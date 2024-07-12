-- Please update version.sql too -- this keeps clean builds in sync
define version=3030
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
insert into csr.source_type (source_type_id, description)
values (16, 'Fixed calc result');

-- Fix up existing dashboards
CREATE PROCEDURE CSR.LatestSaveRule(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE,
	in_description					IN	scenario_rule.description%TYPE,
	in_rule_type					IN	scenario_rule.rule_type%TYPE,
	in_amount						IN	scenario_rule.amount%TYPE,
	in_measure_conversion_id		IN	scenario_rule.measure_conversion_id%TYPE,
	in_start_dtm					IN	scenario_rule.start_dtm%TYPE,
	in_end_dtm						IN	scenario_rule.end_dtm%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_regions						IN	security_pkg.T_SID_IDS,
	out_rule_id						OUT	scenario_rule.rule_id%TYPE
)
AS
	v_dummy					scenario.scenario_sid%TYPE;
	v_regions				security.T_SID_TABLE;
	v_indicators			security.T_SID_TABLE;
BEGIN
	-- Lock the scenario row so we get a consistent rule id
	SELECT scenario_sid
	  INTO v_dummy
	  FROM scenario
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid
	  	   FOR UPDATE;

	IF in_rule_id IS NULL THEN
		SELECT NVL(MAX(rule_id), 0) + 1
		  INTO out_rule_id
		  FROM scenario_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;

		INSERT INTO scenario_rule
			(scenario_sid, rule_id, description, rule_type, amount, measure_conversion_id, start_dtm, end_dtm)
		VALUES
			(in_scenario_sid, out_rule_id, in_description, in_rule_type, in_amount, in_measure_conversion_id, in_start_dtm, in_end_dtm);
	ELSE
		UPDATE scenario_rule
		   SET description = in_description,
		   	   rule_type = in_rule_type,
		   	   amount = in_amount,
		   	   measure_conversion_id = in_measure_conversion_id,
		   	   start_dtm = in_start_dtm,
		   	   end_dtm = in_end_dtm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		 
		DELETE FROM scenario_rule_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;

		DELETE FROM scenario_like_for_like_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
		 
		DELETE FROM scenario_rule_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;

		out_rule_id := in_rule_id;		
	END IF;
	
	v_regions := security_pkg.SidArrayToTable(in_regions);
	INSERT INTO scenario_rule_region (app_sid, scenario_sid, rule_id, region_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_scenario_sid, out_rule_id, column_value
		   FROM TABLE(v_regions);
	
	v_indicators := security_pkg.SidArrayToTable(in_indicators);
	INSERT INTO scenario_rule_ind (app_sid, scenario_sid, rule_id, ind_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_scenario_sid, out_rule_id, column_value
		   FROM TABLE(v_indicators);
END;
/

CREATE PROCEDURE CSR.LatestSaveScenarioRule(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_scenario_sid					scenario.scenario_sid%TYPE;
	v_empty_sids					security_pkg.T_SID_IDS;
	v_rule_id						scenario_rule.rule_id%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT scenario_sid
	  INTO v_scenario_sid
	  FROM scenario_run
	 WHERE scenario_run_sid = in_scenario_run_sid
	   AND app_sid = v_app_sid;
	 
	SELECT max(rule_id)
	  INTO v_rule_id
	  FROM scenario_rule
	 WHERE scenario_sid = v_scenario_sid
	   AND rule_type = 7 --scenario_pkg.RT_FIXCALCRESULTS
	   AND app_sid = v_app_sid;

	-- Save the rule with no inds and regions; the scenario can be shared across multiple dashboards
	-- so we need to add these later in a query.
	CSR.LatestSaveRule(
		in_scenario_sid				=> v_scenario_sid,
		in_rule_id					=> v_rule_id,
		in_description				=> 'Approval dashboard calcs',
		in_rule_type				=> 7, --scenario_pkg.RT_FIXCALCRESULTS,
		in_amount					=> 0,
		in_measure_conversion_id	=> NULL,
		in_start_dtm				=> DATE '1990-01-01',
		in_end_dtm					=> DATE '2021-01-01',
		in_indicators				=> v_empty_sids,
		in_regions					=> v_empty_sids,
		out_rule_id					=> v_rule_id
	);
	
	INSERT INTO scenario_rule_region (app_sid, scenario_sid, rule_id, region_sid)
		SELECT DISTINCT v_app_sid, v_scenario_sid, v_rule_id, region_sid
		  FROM approval_dashboard_region adr
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adr.approval_dashboard_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adr.app_sid = v_app_sid;
	
	INSERT INTO scenario_rule_ind (app_sid, scenario_sid, rule_id, ind_sid)
		SELECT DISTINCT v_app_sid, v_scenario_sid, v_rule_id, ind_sid
		  FROM approval_dashboard_ind adi
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adi.app_sid = v_app_sid;
END;
/

BEGIN
	security.user_pkg.logonadmin;
	FOR h IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT DISTINCT app_sid 
			  FROM csr.approval_dashboard
		)
	) 
	LOOP
		security.user_pkg.logonadmin(h.host);
		FOR r IN (
			SELECT active_period_scenario_run_sid scenario_run_sid
			  FROM csr.approval_dashboard
			 WHERE active_period_scenario_run_sid IS NOT NULL
			 UNION
			SELECT signed_off_scenario_run_sid scenario_run_sid
			  FROM csr.approval_dashboard
			 WHERE signed_off_scenario_run_sid IS NOT NULL
		) LOOP
			CSR.LatestSaveScenarioRule(r.scenario_run_sid);
		END LOOP;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/

DROP PROCEDURE CSR.LatestSaveRule;
DROP PROCEDURE CSR.LatestSaveScenarioRule;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../scenario_pkg
@../scenario_body
@../approval_dashboard_body

@update_tail
