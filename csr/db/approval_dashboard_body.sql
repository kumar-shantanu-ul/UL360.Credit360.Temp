CREATE OR REPLACE PACKAGE BODY CSR.approval_dashboard_pkg AS

PROCEDURE CreateScenario(
	in_scenario_name				IN 	VARCHAR2,
	in_data_source_sp				IN 	VARCHAR2,
	in_data_source_sp_args			IN	VARCHAR2,
	out_new_scenario_run_sid		OUT	SCENARIO_RUN.scenario_run_sid%TYPE
);

PROCEDURE SaveScenarioRule(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
);

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
)
AS
BEGIN
	null;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- TODO: unhook flow items

	--Need to do an update first as we have a bi-directional constraint
	UPDATE flow_item
	   SET last_flow_state_log_id = NULL
	 WHERE dashboard_instance_id IN (
		SELECT dashboard_instance_id
		  FROM approval_dashboard_instance
		 WHERE approval_dashboard_sid = in_sid_id
	);

	DELETE FROM flow_item_generated_alert
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE dashboard_instance_id IN (
			SELECT dashboard_instance_id
			  FROM approval_dashboard_instance
			 WHERE approval_dashboard_sid = in_sid_id
		)
	);
	
	DELETE FROM flow_state_log
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE dashboard_instance_id IN (
			SELECT dashboard_instance_id
			  FROM approval_dashboard_instance
			 WHERE approval_dashboard_sid = in_sid_id
		)
	);

	DELETE FROM flow_item
	 WHERE dashboard_instance_id IN (
		SELECT dashboard_instance_id
		  FROM approval_dashboard_instance
		 WHERE approval_dashboard_sid = in_sid_id
	);

	DELETE FROM approval_dashboard_val_src
	 WHERE approval_dashboard_val_id IN (
		SELECT approval_dashboard_val_id
		  FROM approval_dashboard_val
		 WHERE approval_dashboard_sid = in_sid_id
	 );

	DELETE FROM approval_dashboard_val
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard_ind
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard_alert_type
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard_instance
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard_region
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard_tab
	 WHERE approval_dashboard_sid = in_sid_id;

	DELETE FROM approval_dashboard
	 WHERE approval_dashboard_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateDashboard(
	in_label						IN	approval_dashboard.label%TYPE,
	out_dashboard_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid	NUMBER(10);
BEGIN
	v_parent_sid := securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Dashboards');

	securableobject_pkg.CreateSO(security_pkg.getACT,
		v_parent_sid,
		class_pkg.getClassID('CSRApprovalDashboard'),
		REPLACE(in_label,'/','\'), --'
		out_dashboard_sid);

	INSERT INTO approval_dashboard (approval_dashboard_sid, label)
		VALUES (out_dashboard_sid, in_label);
END;

PROCEDURE CreateDashboard(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_label						IN	approval_dashboard.label%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_ind_pos						IN  security_pkg.T_SID_IDS,
	in_ind_allow_est				IN	security_pkg.T_SID_IDS,
	in_ind_is_hidden				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_period_start					IN	approval_dashboard.start_dtm%TYPE,
	in_period_end					IN	approval_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	approval_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	approval_dashboard.period_interval_id%TYPE,
	in_workflow_sid					IN	approval_dashboard.flow_sid%TYPE,
	in_instance_schedule			IN	XMLType,
	in_publish_doc_folder_sid		IN	approval_dashboard.publish_doc_folder_sid%TYPE,
	in_active_period_scenario_run	IN	approval_dashboard.active_period_scenario_run_sid%TYPE,
	in_signed_off_scenario_run		IN	approval_dashboard.signed_off_scenario_run_sid%TYPE,
	in_source_scenario_run			IN	approval_dashboard.source_scenario_run_sid%TYPE,
	out_dashboard_sid				OUT	approval_dashboard.approval_dashboard_sid%TYPE
)
AS
	v_dashboard_cont_sid				NUMBER(10);
	v_indicators						security.T_SID_TABLE;
	v_regions							security.T_SID_TABLE;
	v_instance_start_dtm				DATE;
	v_next_instance_create_dtm			DATE;
	v_active_period_scen_run_sid		approval_dashboard.active_period_scenario_run_sid%TYPE;
	v_signed_off_scenario_run_sid		approval_dashboard.signed_off_scenario_run_sid%TYPE;
BEGIN
	
	securableobject_pkg.CreateSO(security_pkg.getACT,
		in_parent_sid,
		class_pkg.getClassID('CSRApprovalDashboard'),
		REPLACE(in_label,'/','\'), --'
		out_dashboard_sid);

	IF in_active_period_scenario_run IS NULL THEN
		CreateScenario('Approval dashboard - '||in_label||' (active period)',
			'csr.approval_dashboard_pkg.getActivePeriodVals', 'vals,notes,files',
			v_active_period_scen_run_sid);
	ELSE
		v_active_period_scen_run_sid := in_active_period_scenario_run;
	END IF;

	IF in_signed_off_scenario_run IS NULL THEN
		CreateScenario('Approval dashboard - '||in_label||' (signed off)',
			'csr.approval_dashboard_pkg.getSignedOffVals', 'vals,notes,files',
			v_signed_off_scenario_run_sid);
	ELSE
		v_signed_off_scenario_run_sid := in_signed_off_scenario_run;
	END IF;

	INSERT INTO approval_dashboard
		(approval_dashboard_sid, label, start_dtm, end_dtm, period_set_id, period_interval_id, flow_sid, instance_creation_schedule, active_period_scenario_run_sid, signed_off_scenario_run_sid, source_scenario_run_sid)
	VALUES
		(out_dashboard_sid, in_label, in_period_start, in_period_end, in_period_set_id, in_period_interval_id, in_workflow_sid, in_instance_schedule, v_active_period_scen_run_sid, v_signed_off_scenario_run_sid, in_source_scenario_run);

	 --Indicators
	 IF NOT (in_ind_sids.COUNT = 0 OR (in_ind_sids.COUNT = 1 AND in_ind_sids(1) IS NULL)) THEN
		FOR i IN 1 .. in_ind_sids.COUNT LOOP
			INSERT INTO approval_dashboard_ind
				(approval_dashboard_sid, ind_sid, pos, allow_estimated_data, is_hidden)
			VALUES
				(out_dashboard_sid, in_ind_sids(i), in_ind_pos(i), in_ind_allow_est(i), in_ind_is_hidden(i));
		END LOOP;
	END IF;
	 
	 --Regions
	 v_regions := security_pkg.SidArrayToTable(in_region_sids);
	 FOR r IN (
		SELECT column_value
		  FROM TABLE(v_regions)
	 )
	 LOOP
		INSERT INTO approval_dashboard_region
			(approval_dashboard_sid, region_sid)
		VALUES
			(out_dashboard_sid, r.column_value);
	 END LOOP;

	SaveScenarioRule(v_active_period_scen_run_sid);
	SaveScenarioRule(v_signed_off_scenario_run_sid);
	 
	-- Create instances
	CheckForNewInstances(out_dashboard_sid);
END;

PROCEDURE CreateScenario(
	in_scenario_name				IN 	VARCHAR2,
	in_data_source_sp				IN 	VARCHAR2,
	in_data_source_sp_args			IN	VARCHAR2,
	out_new_scenario_run_sid		OUT	SCENARIO_RUN.scenario_run_sid%TYPE
)
AS
	v_scenarios_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_new_scenario_sid				SCENARIO.scenario_sid%TYPE;
	v_acl_count						NUMBER;
	v_act							security_pkg.T_ACT_ID;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');

	--Create scenarios? Make sure scenarios is enabled first
	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenarios object not found -- run EnableScenarios.sql first');
	END;

	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid, security.class_pkg.GetClassId('CSRScenario'), in_scenario_name, v_new_scenario_sid);
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds, 
							  dont_run_aggregate_indicators)
	VALUES (v_new_scenario_sid, in_scenario_name, v_calc_start_dtm, v_calc_end_dtm, 1, 4, 0, 1);

	-- add registered users read on the scenarios
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_new_scenario_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;

	IF v_acl_count = 0 THEN
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_new_scenario_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	-- Create the scenario run
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid,
		security.class_pkg.GetClassId('CSRScenarioRun'), in_scenario_name||' (run)', out_new_scenario_run_sid);

	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (out_new_scenario_run_sid, v_new_scenario_sid, in_scenario_name||' (run)');

	UPDATE csr.scenario
	   SET file_based = 1,
	       recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_CUSTOM_FETCH_SP,
	       data_source_sp = in_data_source_sp,
	       data_source_sp_args = in_data_source_sp_args,
	       auto_update_run_sid = out_new_scenario_run_sid
	 WHERE scenario_sid = v_new_scenario_sid;

	 -- add registered users read on the scenario run
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(out_new_scenario_run_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;

	IF v_acl_count = 0 THEN
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(out_new_scenario_run_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);

	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_new_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE SaveScenarioRule(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_scenario_sid					scenario.scenario_sid%TYPE;
	v_empty_sids					security_pkg.T_SID_IDS;
	v_rule_id						scenario_rule.rule_id%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
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
	   AND rule_type = scenario_pkg.RT_FIXCALCRESULTS
	   AND app_sid = v_app_sid;

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- Save the rule with no inds and regions; the scenario can be shared across multiple dashboards
	-- so we need to add these later in a query.
	scenario_pkg.SaveRule(
		in_scenario_sid				=> v_scenario_sid,
		in_rule_id					=> v_rule_id,
		in_description				=> 'Approval dashboard calcs',
		in_rule_type				=> scenario_pkg.RT_FIXCALCRESULTS,
		in_amount					=> 0,
		in_measure_conversion_id	=> NULL,
		in_start_dtm				=> v_calc_start_dtm,
		in_end_dtm					=> v_calc_end_dtm,
		in_indicators				=> v_empty_sids,
		in_regions					=> v_empty_sids,
		out_rule_id					=> v_rule_id
	);
	
	INSERT INTO scenario_rule_region (app_sid, scenario_sid, rule_id, region_sid)
		SELECT distinct v_app_sid, v_scenario_sid, v_rule_id, region_sid
		  FROM approval_dashboard_region adr
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adr.approval_dashboard_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adr.app_sid = v_app_sid;
	
	INSERT INTO scenario_rule_ind (app_sid, scenario_sid, rule_id, ind_sid)
		SELECT distinct v_app_sid, v_scenario_sid, v_rule_id, adi.ind_sid
		  FROM approval_dashboard_ind adi
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
		  JOIN ind i ON i.ind_sid = adi.ind_sid
		 WHERE (active_period_scenario_run_sid = in_scenario_run_sid OR signed_off_scenario_run_sid = in_scenario_run_sid)
		   AND adi.app_sid = v_app_sid;
END;

PROCEDURE GetOutputScenarioRuns(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT scenario_run_sid, description
		  FROM scenario_run
		 WHERE scenario_sid IN (
				SELECT scenario_sid
				  FROM scenario
				 WHERE LOWER(data_source_sp) IN ('csr.approval_dashboard_pkg.getactiveperiodvals', 'csr.approval_dashboard_pkg.getsignedoffvals')
			)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteRegion(
	in_dashboard_sid	IN		approval_dashboard_instance.approval_dashboard_sid%TYPE,
	in_region_sid		IN		approval_dashboard_instance.region_sid%TYPE
)
AS
BEGIN
 
	DELETE FROM approval_dashboard_val_src
	 WHERE approval_dashboard_val_id IN (
		SELECT approval_dashboard_val_id 
		  FROM approval_dashboard_val
		 WHERE dashboard_instance_id IN (
			SELECT dashboard_instance_id
			  FROM approval_dashboard_instance
			 WHERE region_sid = in_region_sid
			   AND approval_dashboard_sid = in_dashboard_sid
	));

	DELETE FROM approval_dashboard_val
	 WHERE dashboard_instance_id IN (
		SELECT dashboard_instance_id
		  FROM approval_dashboard_instance
		 WHERE region_sid = in_region_sid
		   AND approval_dashboard_sid = in_dashboard_sid
	);
	
	DELETE FROM flow_item_generated_alert
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE dashboard_instance_id IN (
			SELECT dashboard_instance_id
			  FROM approval_dashboard_instance
			 WHERE region_sid = in_region_sid
			   AND approval_dashboard_sid = in_dashboard_sid
	));
  
	DELETE FROM flow_state_log
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE dashboard_instance_id IN (
			SELECT dashboard_instance_id
			  FROM approval_dashboard_instance
			 WHERE region_sid = in_region_sid
			   AND approval_dashboard_sid = in_dashboard_sid
	));
  
	DELETE FROM flow_item
	 WHERE dashboard_instance_id IN (
		SELECT dashboard_instance_id
		  FROM approval_dashboard_instance
		 WHERE region_sid = in_region_sid
		   AND approval_dashboard_sid = in_dashboard_sid
	);
   
	DELETE FROM approval_dashboard_instance
	 WHERE region_sid = in_region_sid
	   AND approval_dashboard_sid = in_dashboard_sid;

	DELETE FROM approval_dashboard_region 
	 WHERE region_sid = in_region_sid
	   AND approval_dashboard_sid = in_dashboard_sid;

END;

PROCEDURE DeleteIndicator(
	in_dashboard_sid	IN		approval_dashboard_instance.approval_dashboard_sid%TYPE,
	in_ind_sid			IN		approval_dashboard_ind.ind_sid%TYPE
)
AS
BEGIN
 
	DELETE FROM approval_dashboard_val_src
	 WHERE approval_dashboard_val_id IN (
		SELECT approval_dashboard_val_id
		  FROM approval_dashboard_val
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND ind_sid = in_ind_sid
	);

	DELETE FROM approval_dashboard_val
	 WHERE approval_dashboard_sid = in_dashboard_sid
	   AND ind_sid = in_ind_sid;

	DELETE FROM approval_dashboard_ind
	 WHERE approval_dashboard_sid = in_dashboard_sid
	   AND ind_sid = in_ind_sid;

END;

 PROCEDURE UpdateDashboard(
 	in_approval_dashboard_sid		IN 	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
 	in_label						IN	APPROVAL_DASHBOARD.label%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_ind_pos						IN  security_pkg.T_SID_IDS,
	in_ind_allow_est				IN	security_pkg.T_SID_IDS,
	in_ind_is_inactive				IN	security_pkg.T_SID_IDS,
	in_ind_is_hidden				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_end_dtm						IN	APPROVAL_DASHBOARD.start_dtm%TYPE,
	in_instance_schedule			IN	XMLType,
	in_publish_doc_folder_sid		IN	approval_dashboard.publish_doc_folder_sid%TYPE,
	in_active_period_scenario_run	IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	in_signed_off_scenario_run		IN	APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE,
	in_source_scenario_run			IN	approval_dashboard.source_scenario_run_sid%TYPE
)
AS
	v_current_end_dtm					DATE;
	v_max_instance_end_dtm				DATE;
	v_end_date_changed					NUMBER;
	v_indicators						security.T_SID_TABLE;
	v_regions							security.T_SID_TABLE;
	v_region_added						NUMBER;
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_approval_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied writing to dashboard with sid '||in_approval_dashboard_sid);
	END IF;

	-- Check the date; They can change the end date, but only where it isn't less than the current max instance. In other words, we don't
	-- delete instances, and don't want to. So if they have pushed it forward, fine, or if they have brought the end date earlier, but
	-- still after the current instance, then fine. Otherwise, throw.
	v_end_date_changed := 0;
	SELECT end_dtm
	  INTO v_current_end_dtm
	  FROM approval_dashboard
	 WHERE approval_dashboard_sid = in_approval_dashboard_sid;

	IF in_end_dtm ~= v_current_end_dtm THEN
		v_end_date_changed := 1;

		SELECT MAX(start_dtm)
		  INTO v_max_instance_end_dtm
		  FROM approval_dashboard_instance
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid;

		IF in_end_dtm <= v_max_instance_end_dtm THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot modify end date to be before existing instance.');
		END IF;
	END IF;
	
	-- Update cols
	UPDATE APPROVAL_DASHBOARD
	   SET 	label 							= in_label,
			instance_creation_schedule 		= in_instance_schedule,
			active_period_scenario_run_sid 	= in_active_period_scenario_run,
			signed_off_scenario_run_sid 	= in_signed_off_scenario_run,
			source_scenario_run_sid			= in_source_scenario_run,
			end_dtm							= in_end_dtm,
			publish_doc_folder_sid			= in_publish_doc_folder_sid
	 WHERE approval_dashboard_sid = in_approval_dashboard_sid;

	 --Indicators
	 IF NOT (in_ind_sids.COUNT = 0 OR (in_ind_sids.COUNT = 1 AND in_ind_sids(1) IS NULL)) THEN
		FOR i IN 1 .. in_ind_sids.COUNT LOOP
			-- Upsert the list we have been given
			BEGIN
				INSERT INTO APPROVAL_DASHBOARD_IND
					(approval_dashboard_sid, ind_sid, pos, allow_estimated_data, is_hidden)
				VALUES
					(in_approval_dashboard_sid, in_ind_sids(i), in_ind_pos(i), in_ind_allow_est(i), in_ind_is_hidden(i));
			EXCEPTION
				WHEN dup_val_on_index THEN
					UPDATE approval_dashboard_ind
					   SET pos = in_ind_pos(i),
						   allow_estimated_data = in_ind_allow_est(i),
						   is_hidden = in_ind_is_hidden(i)
					 WHERE approval_dashboard_sid = in_approval_dashboard_sid
					   AND ind_sid = in_ind_sids(i);
			END;
			
			-- Process the deactivation time
			UPDATE approval_dashboard_ind
			   SET deactivated_dtm = (
					SELECT CASE(in_ind_is_inactive(i)) WHEN 1 THEN NVL(deactivated_dtm, SYSDATE) ELSE NULL END 
					  FROM approval_dashboard_ind 
					 WHERE ind_sid = in_ind_sids(i)
					   AND approval_dashboard_sid = in_approval_dashboard_sid)
			 WHERE ind_sid = in_ind_sids(i)
			   AND approval_dashboard_sid = in_approval_dashboard_sid;
			
			v_indicators := security_pkg.SidArrayToTable(in_ind_sids);
		
			FOR r IN (
				-- Pick up deletions
				SELECT ind_sid
				  FROM approval_dashboard_ind
				 WHERE approval_dashboard_sid = in_approval_dashboard_sid
				   AND ind_sid NOT IN (
						SELECT column_value
						  FROM TABLE(v_indicators)
				)
			)
			LOOP
				approval_dashboard_pkg.DeleteIndicator(in_approval_dashboard_sid, r.ind_sid);
			END LOOP;
		END LOOP;
	ELSE
		FOR r IN (
			-- Pick up deletions
			SELECT ind_sid
			  FROM approval_dashboard_ind
			 WHERE approval_dashboard_sid = in_approval_dashboard_sid
		)
		LOOP
			approval_dashboard_pkg.DeleteIndicator(in_approval_dashboard_sid, r.ind_sid);
		END LOOP;
		
	END IF;

	 --Regions
	v_region_added := 0;

	v_regions := security_pkg.SidArrayToTable(in_region_sids);
	FOR r IN (
		SELECT column_value
		  FROM TABLE(v_regions)
	)
	LOOP
		BEGIN
			INSERT INTO approval_dashboard_region
				(approval_dashboard_sid, region_sid)
			VALUES
				(in_approval_dashboard_sid, r.column_value);
			v_region_added := 1;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				--Do nothing - it's already there
				NULL;
		END;
	END LOOP;

	--Look for region deletions
	FOR r IN (
		-- Pick up deletions
		SELECT region_sid
		  FROM approval_dashboard_region
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid
		   AND region_sid NOT IN (
				SELECT column_value
				  FROM TABLE(v_regions)
		)
	)
	LOOP
		approval_dashboard_pkg.DeleteRegion(in_approval_dashboard_sid, r.region_sid);
	END LOOP;
	
	SaveScenarioRule(in_active_period_scenario_run);
	SaveScenarioRule(in_signed_off_scenario_run);
	
	IF v_region_added > 0 OR v_end_date_changed > 0 THEN
		CheckForNewInstances(in_approval_dashboard_sid);
	END IF;
END;

PROCEDURE SetFlow(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_flow_sid						IN	security_pkg.T_SID_ID
)
AS
	v_old_flow	flow.label%TYPE;
	v_new_flow	flow.label%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing approval dashboard sid '||in_dashboard_sid);
	END IF;

	-- audit the change
	BEGIN
		SELECT f.label
		  INTO v_old_flow
		  FROM approval_dashboard ad
			JOIN flow f ON ad.flow_sid = f.flow_sid
		 WHERE approval_dashboard_sid = in_dashboard_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_old_flow := null;
	END;

	BEGIN
		SELECT label
		  INTO v_new_flow
		  FROM flow
		 WHERE flow_sid = in_flow_sid
		   AND flow_alert_class = 'approval_dashboard';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Flow with sid:' || in_flow_sid || ' and class "approval_dashboard" was not found');
	END;

	csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getApp,
		in_dashboard_sid, 'Dashboard linked to workflow', v_old_flow, v_new_flow);

	-- clean up in case they already had linked this to workflows
	DELETE FROM approval_dashboard_alert_type
	 WHERE approval_dashboard_sid = in_dashboard_sid;

	-- insert any alerts that might be configured already for approval_dashboards linked to the specified flow
	INSERT INTO approval_dashboard_alert_type (approval_dashboard_sid, customer_alert_type_id, flow_sid)
		SELECT in_dashboard_sid, customer_alert_type_id, in_flow_sid
		  FROM approval_dashboard_alert_type
		 WHERE flow_sid = in_flow_sid
		   AND approval_dashboard_sid != approval_dashboard_sid;
END;

--PROCEDURE SetRegions
-- TODO: what happens if there are regions in approval_dashboard_instance and we try and remove them?

PROCEDURE CheckForNewInstances(
	in_dashboard_sid				IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE
)
AS
	v_instance_start_dtm			DATE;
	v_dashboard_end_dtm				DATE;
	v_schedule_xml					XMLTYPE;
	v_next_instance_create_dtm		DATE;
	v_period_set_id					NUMBER;
	v_period_interval_id			NUMBER;
BEGIN
	SELECT start_dtm, end_dtm, instance_creation_schedule, period_set_id, period_interval_id
	  INTO v_instance_start_dtm, v_dashboard_end_dtm, v_schedule_xml, v_period_set_id, v_period_interval_id
	  FROM approval_dashboard
	 WHERE approval_dashboard_sid = in_dashboard_sid;

	-- We'll create an instance as long as the start_dtm has passed
	v_next_instance_create_dtm := v_instance_start_dtm;

	WHILE v_next_instance_create_dtm < SYSDATE AND NOT (v_instance_start_dtm >= v_dashboard_end_dtm) LOOP
		CreateInstance(in_dashboard_sid, v_instance_start_dtm, period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_instance_start_dtm, 1));
		v_next_instance_create_dtm := CSR.RECURRENCE_PATTERN_PKG.GETNEXTOCCURRENCE(v_schedule_xml, v_instance_start_dtm);
		v_instance_start_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_instance_start_dtm, 1);
	END LOOP;
END;

PROCEDURE CreateInstance(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm						IN	approval_dashboard_instance.end_dtm%TYPE
)
AS
	v_dashboard_instance_id   	approval_dashboard_instance.dashboard_instance_id%TYPE;
BEGIN
	CreateInstance(in_dashboard_sid, in_start_dtm, in_end_dtm, v_dashboard_instance_id);
END;

PROCEDURE CreateNextInstance(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	out_instance_id					OUT	approval_dashboard_instance.dashboard_instance_id%TYPE
)
AS
	v_inst_start_dtm		approval_dashboard_instance.start_dtm%TYPE;
	v_inst_end_dtm			approval_dashboard_instance.end_dtm%TYPE;
	v_dashboard_end_dtm		approval_dashboard.end_dtm%TYPE;
BEGIN
	SELECT MAX(adi.end_dtm), period_pkg.AddIntervals(ad.period_set_id, ad.period_interval_id, MAX(adi.end_dtm), 1), ad.end_dtm
	  INTO v_inst_start_dtm, v_inst_end_dtm, v_dashboard_end_dtm
	  FROM approval_dashboard_instance adi
	  JOIN approval_dashboard ad ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
	 WHERE adi.approval_dashboard_sid = in_dashboard_sid
	 GROUP BY adi.approval_dashboard_sid, ad.end_dtm;

	IF v_inst_start_dtm < v_dashboard_end_dtm THEN
		CreateInstance(in_dashboard_sid, v_inst_start_dtm, v_inst_end_dtm, out_instance_id);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'No more instances available.');
	END IF;
END;

PROCEDURE CreateInstance(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm						IN	approval_dashboard_instance.end_dtm%TYPE,
	out_instance_id					OUT	approval_dashboard_instance.dashboard_instance_id%TYPE
)
AS
	v_flow_item_id				flow_item.flow_item_id%TYPE;
BEGIN
	FOR r IN (
		SELECT approval_dashboard_sid, region_sid
		  FROM approval_dashboard_region
		 WHERE approval_dashboard_sid = in_dashboard_sid
	)
	LOOP
		BEGIN
			INSERT INTO approval_dashboard_instance
				(dashboard_instance_id, approval_dashboard_sid, region_sid, start_dtm, end_dtm)
				VALUES (dashboard_instance_id_seq.nextval, in_dashboard_sid, r.region_sid, in_start_dtm, in_end_dtm)
				RETURNING dashboard_instance_id INTO out_instance_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				out_instance_id := null;
		END;

		IF out_instance_id IS NOT NULL THEN
			-- log it with the flow_pkg
			flow_pkg.AddApprovalDashboardInstance(out_instance_id, v_flow_item_id );
		END IF;
	END LOOP;
END;

PROCEDURE AddTab(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_tab_name						IN	tab.name%TYPE,
	in_is_shared 					IN	tab.is_shared%TYPE,
	in_is_hideable 					IN	tab.is_hideable%TYPE,
	in_layout						IN	tab.layout%TYPE,
	in_portal_group					IN	tab.portal_group%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_out_tab_id	tab.tab_id%TYPE;
BEGIN
	portlet_pkg.AddTabReturnTabId(security_pkg.getApp, in_tab_name, in_is_shared, in_is_hideable, in_layout, in_portal_group,
		v_out_tab_id);

	-- this does the security check we need
	AddTab(in_dashboard_sid, v_out_tab_id, null);

	-- return cursor
	OPEN out_cur FOR
		SELECT TAB_ID, LAYOUT, NAME, IS_SHARED, IS_HIDEABLE, POS, IS_OWNER, OVERRIDE_POS
			FROM v$TAB_USER
		 WHERE tab_id = v_out_tab_id;
END;

PROCEDURE AddTab(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_tab_id						IN	security_pkg.T_SID_ID,
	in_pos							IN	NUMBER DEFAULT NULL
)
AS
	v_pos	NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing approval dashboard sid '||in_dashboard_sid);
	END IF;

	IF NVL(in_pos,-1) = -1 THEN
		SELECT NVL(MAX(pos),0) + 1
		  INTO v_pos
		  FROM approval_dashboard_tab
		 WHERE approval_dashboard_sid = in_dashboard_sid;
	ELSE
		v_pos := in_pos;
	END IF;

	BEGIN
		INSERT INTO approval_dashboard_tab
			(approval_dashboard_sid, tab_id, pos)
			VALUES (in_dashboard_sid, in_tab_id, v_pos);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE approval_dashboard_tab
			   SET pos = in_pos
			 WHERE approval_dashboard_sid = in_dashboard_sid
			   AND tab_id = in_tab_id;
	END;
END;

/**
 * Update the position of tabs in db
 *
 * @param		in_tab_ids				Array of tab ids (ordered from top to down)
 */
PROCEDURE UpdateTabPosition(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_tab_ids						IN	security_pkg.T_SID_IDS
)
AS
	t_tab_ids			security.T_ORDERED_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing approval dashboard sid '||in_dashboard_sid);
	END IF;

	t_tab_ids	:= security_pkg.SidArrayToOrderedTable(in_tab_ids);

	UPDATE approval_dashboard_tab
	   SET pos = (
			SELECT pos FROM TABLE(t_tab_ids)
			 WHERE sid_id = approval_dashboard_tab.tab_id
		)
	 WHERE approval_dashboard_sid = in_dashboard_sid;
END;

PROCEDURE GetDashboards(
	out_cur_dashboard	OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- return dashboards that the user can see
	OPEN out_cur_dashboard FOR
		SELECT ad.approval_dashboard_sid, ad.label, min(adi.start_dtm) min_start_dtm, max(adi.end_dtm) max_end_dtm
		  FROM approval_dashboard ad
		  JOIN approval_dashboard_instance adi
		    ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
		   AND ad.app_sid = adi.app_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSID(security_pkg.getACT, ad.approval_dashboard_sid, security_pkg.PERMISSION_READ) = 1
		 GROUP BY ad.approval_dashboard_sid, ad.label;
END;

PROCEDURE GetDashboardList(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_dashboards_sid		security_pkg.T_SID_ID;
BEGIN
	v_dashboards_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Dashboards');

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_dashboards_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT approval_dashboard_sid dashboard_sid, label, start_dtm, end_dtm, period_set_id, period_interval_id
		  FROM APPROVAL_DASHBOARD
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), approval_dashboard_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY label;
END;

PROCEDURE GetFolderPath(
	in_folder_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, Name
		  FROM security.securable_object
			START WITH sid_id = in_folder_sid AND class_id = 4	--Container
			CONNECT BY sid_id = PRIOR parent_sid_id AND class_id = 4
		 ORDER BY LEVEL DESC;
END;

PROCEDURE GetChildDashboards(
	in_parent_sid					IN security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT approval_dashboard_sid dashboard_sid, label, start_dtm, end_dtm, period_set_id, period_interval_id
		  FROM APPROVAL_DASHBOARD ad
		  JOIN security.SECURABLE_OBJECT so ON so.sid_id = ad.approval_dashboard_sid
		 WHERE so.parent_sid_id = in_parent_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), ad.approval_dashboard_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY label;
END;

PROCEDURE NewFlowAlertType(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_Id%TYPE
)
AS
BEGIN
	-- in theory we don't need to secure this as this is run as a helper pkg, but we can just guarantee that someone will ignore that
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_flow_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||in_flow_sid);
	END IF;

	-- link this new alert type to all dashboards using this flow_sid
	INSERT INTO approval_dashboard_alert_type (approval_dashboard_sid, customer_alert_type_id, flow_sid)
		SELECT approval_dashboard_sid, in_customer_alert_type_id, in_flow_sid
		  FROM approval_dashboard
		 WHERE flow_sid = in_flow_sid;

	-- stick in a bunch of defaults
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user sending the email', 5);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'FROM_NAME', 'From name', 'The name of the user sending the email', 6);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);

	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'DASHBOARD_LABEL', 'Dashboard name', 'The name of the dashboard', 8);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'DASHBOARD_URL', 'Dashboard URL', 'The URL of the dashboard', 9);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'DASHBOARD_LINK', 'Dashboard link', 'A link to the dashboard', 10);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'REGION_DESCRIPTION', 'Region description', 'The name of the region', 11);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'FROM_STATE', 'From state', 'The state moved from', 12);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'TO_STATE', 'From state', 'The state moved to', 13);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'SET_BY_FULL_NAME', 'Name of user who performed the action', 'The name of the user who performed the action', 14);
	INSERT INTO customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (in_customer_alert_type_id, 1, 'SET_BY_EMAIL', 'Email of user who performed the action', 'The email of the user who performed the action', 15);

	INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_Frame_id, send_type)
		SELECT app_sid, in_customer_alert_type_id, min(alert_frame_id), 'manual'
		  FROM alert_frame WHERE app_Sid = security_pkg.getapp GROUP BY app_sid;

	INSERT INTO alert_template_body(app_sid, customer_alert_type_Id, lang, subject, body_html, item_html)
		SELECT security_pkg.getapp, in_customer_alert_type_id, 'en', '<template>The status of dashboard data has changed</template>',
			'<template>'||
				'Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/>'||
				'<br/>'||
				'The status of data relating to you in CRedit 360 regarding Sustainability '||CHR(38)||'amp; Corporate Responsibility has changed.'||
				'<br/><br/>'||
				'<mergefield name="ITEMS"/>'||
				'<br/>'||
				'Please login to the system here: <mergefield name="HOST"/>'||
			'</template>',
			'<template>'||
				'<b><mergefield name="REGION_DESCRIPTION"/></b> (<mergefield name="DASHBOARD_LABEL"/>) - <mergefield name="SET_BY_FULL_NAME"/> changed the status from "<mergefield name="FROM_STATE"/>" to "<mergefield name="TO_STATE"/>"'||
				'<div style="padding-left:10px; color:#ccc"><mergefield name="DASHBOARD_LINK"/></div><br/>'||
			'</template>'
		  FROM dual;
END;

PROCEDURE GetDashboardDetail(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	out_cur_dashboard				OUT	SYS_REFCURSOR,
	out_cur_periods					OUT	SYS_REFCURSOR,
	out_cur_regions 				OUT	SYS_REFCURSOR,
	out_cur_users 					OUT	SYS_REFCURSOR,
	out_cur_inds					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading approval dashboard sid '||in_dashboard_sid);
	END IF;

	OPEN out_cur_dashboard FOR
		SELECT label, security_pkg.SQL_IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) can_save
		  FROM approval_dashboard
		 WHERE approval_dashboard_sid = in_dashboard_sid;

	OPEN out_cur_periods FOR
		SELECT DISTINCT start_dtm, end_dtm
		  FROM approval_dashboard_instance
		 WHERE approval_dashboard_sid = in_dashboard_sid
		 ORDER BY start_dtm;

	OPEN out_cur_regions FOR
		SELECT r.region_sid, r.description, adi.dashboard_instance_id,
			   adi.start_dtm, adi.end_dtm,
			   fi.current_state_id, fi.current_state_label
		  FROM v$flow_item fi
		  JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id
		  JOIN v$region r ON adi.region_sid = r.region_sid
		 WHERE adi.approval_dashboard_sid = in_dashboard_sid
		 ORDER BY r.description;

	OPEN out_cur_users FOR
		SELECT adi.dashboard_instance_id, ro.role_sid, ro.name role_name,
			rrm.user_sid, cu.full_name, cu.email, cu.user_name
		  FROM V$FLOW_ITEM fi
		  JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id
		  JOIN region r ON adi.region_sid = r.region_sid
		  JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id
		  JOIN role ro ON fsr.role_sid = ro.role_sid
		  JOIN region_role_member rrm ON r.region_sid = rrm.region_sid AND ro.role_sid = rrm.role_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid
		 WHERE adi.approval_dashboard_sid = in_dashboard_sid
		 ORDER BY ro.name, cu.full_name;

	OPEN out_cur_inds FOR
		SELECT ind_sid
		  FROM approval_dashboard_ind
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND deactivated_dtm IS NULL
		 ORDER BY pos ASC;
END;

PROCEDURE GetDashboardFromValId(
	in_val_id						IN	NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_capability_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_instance_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dashboard_sid					security_pkg.T_SID_ID;
	v_start_dtm						approval_dashboard_instance.start_dtm%TYPE;
	v_end_dtm						approval_dashboard_instance.end_dtm%TYPE;
	v_instance_id					approval_dashboard_instance.dashboard_instance_id%TYPE;
BEGIN

	SELECT val.approval_dashboard_sid, inst.start_dtm, inst.end_dtm, inst.dashboard_instance_id
	  INTO v_dashboard_sid, v_start_dtm, v_end_dtm, v_instance_id
	  FROM approval_dashboard_val val
	  JOIN approval_dashboard_instance inst ON val.dashboard_instance_id = inst.dashboard_instance_id
	 WHERE APPROVAL_DASHBOARD_VAL_ID = in_val_id;
	 
	approval_dashboard_pkg.GetDashboard(
		in_dashboard_sid				=> v_dashboard_sid,
		in_start_dtm					=> v_start_dtm,
		in_end_dtm						=> v_end_dtm,
		out_cur							=> out_cur,
		out_regions_cur					=> out_regions_cur,
		out_inds_cur					=> out_inds_cur,
		out_capability_cur				=> out_capability_cur
	);
	
	OPEN out_instance_cur FOR
		SELECT v_start_dtm instance_start_dtm, v_end_dtm instance_end_dtm, v_instance_id instance_id
		  FROM DUAL;

END;

PROCEDURE GetDashboard(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm						IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_capability_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading approval dashboard sid '||in_dashboard_sid);
	END IF;

	OPEN out_cur FOR
		SELECT approval_dashboard_sid, ad.label, f.flow_sid, f.label flow_label, ad.start_dtm, ad.end_dtm, ad.period_set_id, ad.period_interval_id, ad.tpl_report_sid, ad.active_period_scenario_run_sid, ad.signed_off_scenario_run_sid, tr.filename template_filename
		  FROM approval_dashboard ad
			LEFT JOIN flow f ON ad.flow_sid = f.flow_sid
			LEFT JOIN tpl_report tr ON tr.tpl_report_sid = ad.tpl_report_sid
		 WHERE approval_dashboard_sid = in_dashboard_sid;

	OPEN out_regions_cur FOR
		SELECT r.region_sid, r.description, fi.current_state_id, fs.label current_state_label, fi.flow_item_id, fi.dashboard_instance_id,
			   adi.start_dtm, adi.end_dtm, TO_CHAR(fsl.comment_text) comment_text, MAX(fsr.is_editable) is_editable, fsl.set_dtm comment_date, cu.full_name comment_by
		  FROM flow_item fi
		  JOIN approval_dashboard_instance adi   ON adi.dashboard_instance_id	= fi.dashboard_instance_id
												AND adi.approval_dashboard_sid	= in_dashboard_sid
												AND adi.start_dtm				= in_start_dtm
												AND adi.end_dtm					= in_end_dtm
		  JOIN flow_state_role fsr				 ON fsr.flow_state_id			= fi.current_state_id
		  JOIN csr.region_role_member rrm		 ON rrm.region_sid				= adi.region_sid
												AND rrm.role_sid				= fsr.role_sid
												AND rrm.user_sid				= SYS_CONTEXT('SECURITY', 'SID')
		  JOIN csr.v$region r					 ON r.region_sid				= adi.region_sid
		  JOIN flow_state fs					 ON fs.flow_state_id			= fsr.flow_state_id
		  JOIN flow_state_log fsl				 ON fsl.flow_state_log_id		= fi.last_flow_state_log_id
	 LEFT JOIN csr_user cu						 ON fsl.set_by_user_sid			= cu.csr_user_sid
		 GROUP BY fi.dashboard_instance_id, adi.start_dtm, adi.end_dtm, r.region_sid, r.description, fi.current_state_id, fs.label, fi.flow_item_id, TO_CHAR(fsl.comment_text), fsl.set_dtm, cu.full_name
		 ORDER BY r.description;

	GetDashboardInds(in_dashboard_sid, out_inds_cur);
	GetDashboardStateCapabilities(in_dashboard_sid, in_start_dtm, in_end_dtm, out_capability_cur);
END;

PROCEDURE GetDashboardStateCapabilities(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm						IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT firm.region_sid, firm.current_state_id, firm.flow_item_Id, firm.dashboard_instance_Id, firm.flow_capability_id, firm.permission_set, firm.description
		  FROM (
			-- user might be in multiple roles
			SELECT dashboard_instance_id, current_state_id, flow_item_id, region_sid, last_flow_state_log_id, max(fsrc.permission_set) permission_set, fsrc.flow_capability_id, fc.description
			  FROM v$flow_item_role_member vfirm
			  JOIN FLOW_STATE_ROLE_CAPABILITY fsrc ON fsrc.flow_state_id = vfirm.current_state_id AND fsrc.role_sid = vfirm.role_sid
			  JOIN v$flow_capability fc ON fc.flow_capability_id = fsrc.flow_capability_id
			 GROUP BY current_state_id, current_state_label, flow_item_id, region_sid, last_flow_state_log_id, dashboard_instance_id, fsrc.flow_capability_id, fc.description
		 )firm
			  JOIN approval_dashboard_instance adi ON firm.dashboard_instance_id = adi.dashboard_instance_id
			  JOIN v$region r ON adi.region_sid = r.region_sid AND firm.region_sid = r.region_sid
			  JOIN flow_state_log fsl ON firm.last_flow_state_log_id = fsl.flow_state_log_id
			 WHERE adi.approval_dashboard_sid = in_dashboard_sid
			   AND adi.start_dtm = in_start_dtm
			   AND adi.end_dtm = in_end_dtm
		 ORDER BY r.description;
END;

PROCEDURE GetDashboardInds(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_inds_cur FOR
		SELECT ind_sid, is_hidden, deactivated_dtm
		  FROM approval_dashboard_ind
		 WHERE approval_dashboard_sid = in_dashboard_sid
		 ORDER BY pos ASC;
END;

PROCEDURE GetDashboardSettings(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_regions_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT label, start_dtm period_start_dtm, end_dtm period_end_dtm, period_set_id, period_interval_id, flow_sid workflow_sid, instance_creation_schedule instance_schedule_xml, active_period_scenario_run_sid,
			signed_off_scenario_run_sid, source_scenario_run_sid, publish_doc_folder_sid, so.name doc_folder_name
		  FROM approval_dashboard ad
		  LEFT JOIN security.securable_object so ON so.sid_id = ad.publish_doc_folder_sid
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND ad.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_regions_cur FOR
		SELECT region_sid
		  FROM approval_dashboard_region
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_inds_cur FOR
		SELECT adi.ind_sid, adi.pos, adi.allow_estimated_data, i.description, adi.deactivated_dtm, adi.is_hidden
		  FROM approval_dashboard_ind adi
		  JOIN v$ind i on adi.ind_sid = i.ind_sid
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND adi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY pos ASC;
END;

PROCEDURE GetTransitions(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	approval_dashboard_instance.start_dtm%TYPE,
	in_end_dtm						IN	approval_dashboard_instance.end_dtm%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		-- we use a DISTINCT because the user might be in more than one role for this transition, so we don't want to emit multiple
		-- verbs
		SELECT DISTINCT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id, trm.to_state_label, trm.ask_for_comment,
			   r.region_sid, r.description region_description,
			   adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm, transition_pos
		  FROM v$flow_item_trans_role_member trm
		  JOIN approval_dashboard_instance adi ON trm.dashboard_instance_id = adi.dashboard_instance_id
		  JOIN v$region r ON adi.region_sid = r.region_sid AND trm.region_sid = r.region_sid
		 WHERE adi.approval_dashboard_sid = in_dashboard_sid
		   AND start_dtm = in_start_dtm
		   AND end_dtm = in_end_dtm
		 ORDER BY transition_pos;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT adi.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM approval_dashboard_instance adi
	  JOIN flow_item fi ON adi.dashboard_instance_id = fi.dashboard_instance_id
	 WHERE fi.app_sid = security_pkg.getApp
	   AND fi.flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM approval_dashboard_instance adi
	  JOIN flow_item fi ON adi.dashboard_instance_id = fi.dashboard_instance_id
	 WHERE fi.app_sid = security_pkg.getApp
	   AND fi.flow_item_id = in_flow_item_id;

	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT y.*, r.description region_description
		  FROM (
			SELECT x.app_sid, x.flow_item_generated_alert_id, x.flow_item_id, x.flow_state_transition_id,
				   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label,
				   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name, x.comment_text,
				   x.to_user_sid, to_email, to_full_name, to_friendly_name, to_user_name,
				   ad.label dashboard_label, adi.start_dtm, adi.end_dtm, adi.approval_dashboard_sid,
				   adi.region_sid, x.flow_alert_helper, x.to_initiator
			  FROM v$open_flow_item_gen_alert x
			  JOIN approval_dashboard_instance adi
			    ON adi.dashboard_instance_Id = x.dashboard_instance_id
			   AND x.app_sid = adi.app_sid
			  JOIN approval_dashboard ad
				ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
			   AND adi.app_sid = ad.app_sid) y
		  JOIN v$region r ON y.region_sid = r.region_sid AND y.app_sid = r.app_sid
		  JOIN customer c on y.app_sid = c.app_sid
		 WHERE c.scheduled_tasks_disabled = 0
		 ORDER BY y.app_sid, y.customer_alert_type_id, y.to_user_sid, y.flow_item_id; -- order matters!
END;

PROCEDURE GetMyDashboards(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT ad.approval_dashboard_sid, ad.label, adi.region_sid, r.description region_desc, adi.start_dtm, adi.end_dtm
		  FROM csr.flow_state_role fsr
		  JOIN csr.flow_state fs 					 ON fsr.flow_state_id 			= fs.flow_state_id
		  JOIN csr.approval_dashboard ad 			 ON ad.flow_sid 				= fs.flow_sid
		  JOIN csr.approval_dashboard_instance adi 	 ON adi.approval_dashboard_sid 	= ad.approval_dashboard_sid
		  JOIN csr.region_role_member rrm 			 ON rrm.region_sid 				= adi.region_sid
													AND rrm.role_sid 				= fsr.role_sid
													AND rrm.user_sid 				= SYS_CONTEXT('SECURITY', 'SID')
		  JOIN csr.v$region r 						 ON r.region_sid 				= adi.region_sid
		  JOIN csr.flow_item fi 					 ON fi.flow_sid 				= fs.flow_sid
													AND fi.dashboard_instance_id 	= adi.dashboard_instance_id
													AND fi.current_state_id 		= fs.flow_state_id
		 ORDER BY ad.approval_dashboard_sid, adi.region_sid;
END;

PROCEDURE GetMyDashboardsBasicFiltered(
	in_num_months					IN 	NUMBER,
	in_include_final_state			IN 	NUMBER,
	in_include_no_transitions		IN 	NUMBER,
	in_group_by						IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_start_dtm		DATE;
BEGIN

	v_start_dtm := ADD_MONTHS(SYSDATE, NVL(in_num_months, 12) * -1);

	approval_dashboard_pkg.GetMyFilteredDashboards(
		in_text_search 			=> '',
		in_start_dtm			=> v_start_dtm,
		in_end_dtm				=> NULL,
		in_include_final_state	=> in_include_final_state,
		in_action_state			=> in_include_no_transitions,
		in_group_by				=> in_group_by,
		in_workflow_state		=> NULL,
		out_cur					=> out_cur
	);

END;

PROCEDURE GetMyFilteredDashboards(
	in_text_search					IN	VARCHAR2,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_include_final_state			IN	NUMBER DEFAULT 0,
	in_action_state					IN 	NUMBER,
	in_group_by						IN	VARCHAR2,
	in_workflow_state				IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_text_search))|| '%';
BEGIN
	OPEN out_cur FOR
	
		SELECT dashboard_instance_id, approval_dashboard_sid, dashboard_name, region_sid, region_desc, start_dtm, end_dtm, state_label, is_final, period_set_id, period_interval_id, instance_locked, number_trans 
		  FROM (	
			SELECT DISTINCT adi.dashboard_instance_id, ad.approval_dashboard_sid, ad.label dashboard_name, adi.region_sid, r.description region_desc, adi.start_dtm, adi.end_dtm, fs.label state_label, fs.is_final, 
				   ad.period_set_id, ad.period_interval_id, adi.is_locked instance_locked, (
					SELECT COUNT(*) 
					  FROM v$flow_item_trans_role_member v 
					 WHERE v.flow_item_id = fi.flow_item_id 
					   AND v.region_sid = adi.region_sid
				 ) number_trans
			  FROM csr.flow_state_role fsr
			  JOIN csr.flow_state fs 					 ON fsr.flow_state_id 			= fs.flow_state_id
			  JOIN csr.approval_dashboard ad 			 ON ad.flow_sid 				= fs.flow_sid
			  JOIN csr.approval_dashboard_instance adi 	 ON adi.approval_dashboard_sid 	= ad.approval_dashboard_sid
			  JOIN csr.region_role_member rrm 			 ON rrm.region_sid 				= adi.region_sid
														AND rrm.role_sid 				= fsr.role_sid
														AND rrm.user_sid 				= SYS_CONTEXT('SECURITY', 'SID')
			  JOIN csr.v$region r 						 ON r.region_sid 				= adi.region_sid
			  JOIN csr.flow_item fi 					 ON fi.flow_sid 				= fs.flow_sid
														AND fi.dashboard_instance_id 	= adi.dashboard_instance_id
														AND fi.current_state_id 		= fs.flow_state_id
			 WHERE (LOWER(ad.label) LIKE v_search OR LOWER(r.description) LIKE v_search)
			   AND (in_start_dtm IS NULL OR adi.start_dtm >= in_start_dtm)
			   AND (in_end_dtm IS NULL OR adi.start_dtm < in_end_dtm)
			   AND (in_include_final_state = 1 OR fs.is_final = 0)
		)
		WHERE (in_workflow_state IS NULL OR LOWER(state_label) = LOWER(in_workflow_state))
		  AND (in_action_state = 1 OR (in_action_state = 0 AND number_trans > 0) OR (in_action_state = 2 AND number_trans = 0))
		ORDER BY
			CASE in_group_by WHEN 'REGION' THEN region_desc WHEN 'PERIOD' THEN TO_CHAR(start_dtm, 'yyyy/mm/dd') WHEN 'DASHBOARD' THEN dashboard_name END, 
			CASE in_group_by WHEN 'REGION' THEN dashboard_name WHEN 'PERIOD' THEN dashboard_name WHEN 'DASHBOARD' THEN region_desc END, 
			CASE in_group_by WHEN 'REGION' THEN TO_CHAR(start_dtm, 'yyyy/mm/dd') WHEN 'PERIOD' THEN region_desc WHEN 'DASHBOARD' THEN TO_CHAR(start_dtm, 'yyyy/mm/dd') END;
END;

PROCEDURE GetUserWorkflowStates(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT fs.label label
		  FROM csr.flow_state_role fsr
		  JOIN csr.flow_state fs 					 ON fsr.flow_state_id 			= fs.flow_state_id
		  JOIN csr.approval_dashboard ad 			 ON ad.flow_sid 				= fs.flow_sid
		  JOIN csr.approval_dashboard_instance adi 	 ON adi.approval_dashboard_sid 	= ad.approval_dashboard_sid
		  JOIN csr.region_role_member rrm 			 ON rrm.region_sid 				= adi.region_sid
													AND rrm.role_sid 				= fsr.role_sid
													AND rrm.user_sid 				= SYS_CONTEXT('SECURITY', 'SID')
		  JOIN csr.flow_item fi 					 ON fi.flow_sid 				= fs.flow_sid
													AND fi.dashboard_instance_id 	= adi.dashboard_instance_id
													AND fi.current_state_id 		= fs.flow_state_id
		 ORDER BY label;
END;

PROCEDURE GetTabs(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_is_owner  NUMBER(1) := 0;
BEGIN
	IF security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_WRITE) THEN
		v_is_owner := 1;
	ELSIF security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dashboard_sid, security_pkg.PERMISSION_READ) THEN
		v_is_owner := 0;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading approval dashboard sid '||in_dashboard_sid);
	END IF;

	-- return cursor
	OPEN out_cur FOR
		-- gets all the tabs I'm entitled to see where there's
		-- a row for me in tab_user
			SELECT DISTINCT tab_id, layout, name, is_shared, is_hideable, NVL(override_pos,NVL(pos,99)) pos, override_pos,
				CASE WHEN v_is_owner = 1 THEN 1 ELSE is_owner END is_owner -- pretend we're the owner if we've got 'manage any portal' capability
			  FROM v$tab_user
			 WHERE user_sid = security_pkg.GetSID
			   AND app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND is_hidden = 0
			   AND (
					is_owner = 1 OR
					tab_id IN (
							-- ensure the user is still in the group
							SELECT tab_id
							  FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))x, TAB_GROUP tg
							 WHERE tg.group_sid = x.column_value
					)
				)
			  AND portal_group = approval_dashboard_pkg.PORTAL_GROUP_NAME
			  AND tab_id IN (SELECT tab_id FROM approval_dashboard_tab WHERE approval_dashboard_sid = in_dashboard_sid)
			UNION
			-- gets all the tabs I'm entitled to see where there's
			-- no row for me in tab_user
			-- the pos is taken from tag_group table, however there is no UI currently to set this
			SELECT DISTINCT x.tab_id, layout, name, 1 is_shared, is_hideable, NVL(t.override_pos,NVL(tu.pos,99)) pos, t.override_pos, v_is_owner is_owner
				FROM (
					SELECT tab_id
					  FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))y, TAB_GROUP tg
					 WHERE tg.group_sid = y.column_value
					   AND tg.app_sid = SYS_CONTEXT('SECURITY','APP')
					 MINUS
					SELECT tab_id
					  FROM tab_user
					 WHERE user_sid = security_pkg.GetSID
			)x, TAB t, tab_user tu, tab_group tg
			 WHERE x.tab_id = t.tab_id
			   AND t.tab_id = tu.tab_id(+)
			   AND t.tab_id = tg.tab_id(+)
			   AND tu.user_sid(+) = security_pkg.GetSID
			   AND t.portal_group = approval_dashboard_pkg.PORTAL_GROUP_NAME
			   AND t.tab_id IN (SELECT tab_id FROM approval_dashboard_tab WHERE approval_dashboard_sid = in_dashboard_sid)
			 ORDER BY POS, NAME;
END;

PROCEDURE GetInstanceId(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_instance_id					OUT	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
BEGIN
	SELECT dashboard_instance_id
	  INTO out_instance_id
	  FROM approval_dashboard_instance
	 WHERE approval_dashboard_sid 	= in_approval_dashboard_sid
	   AND start_dtm 				= in_start_dtm
	   AND region_sid 				= in_region_sid
	   AND (in_end_dtm IS NULL OR end_dtm = in_end_dtm)
	   AND app_sid 					= SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetInstances(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dashboard_instance_id, approval_dashboard_sid, start_dtm, end_dtm, is_locked, (
			SELECT COUNT(adv.approval_dashboard_val_id)
			  FROM approval_dashboard_val adv
			 WHERE adv.dashboard_instance_id = adi.dashboard_instance_id
		) value_count
		  FROM approval_dashboard_instance adi
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid
		   AND region_sid = in_region_sid
		 ORDER BY adi.start_dtm ASC;
END;

PROCEDURE GetMostRecentInstance(
	in_approval_dashboard_sid			IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid						IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_is_locked						IN  APPROVAL_DASHBOARD_INSTANCE.is_locked%TYPE,
	out_dashboard_instance_id			OUT APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
BEGIN
	--Get the instance id
	SELECT MAX(DASHBOARD_INSTANCE_ID)
	  INTO out_dashboard_instance_id
	  FROM approval_dashboard_instance
	 WHERE approval_dashboard_sid = in_approval_dashboard_sid
	   AND region_sid = in_region_sid
	   AND (in_is_locked = -1 OR is_locked = in_is_locked)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UpdateDashboardIndicators(
	in_dashboard_sid				IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS
)
AS
	v_indicators				security.T_SID_TABLE;
BEGIN
	-- Doesn't handle deletion yet, just additions. The inds are FK constrained so we'd currently have to
	-- delete all the data too which isn't ideal. Most likely wants an active 0/1 column

	v_indicators := security_pkg.SidArrayToTable(in_indicators);

	FOR r IN (
		SELECT column_value
		  FROM TABLE(v_indicators)
	)
	LOOP
		BEGIN
			INSERT INTO approval_dashboard_ind
				(approval_dashboard_sid, ind_sid)
			VALUES
				(in_dashboard_sid, r.column_value);
		EXCEPTION
			WHEN dup_val_on_index THEN
			-- Already exists. Make sure it's active
			UPDATE approval_dashboard_ind
			   SET deactivated_dtm = null
			 WHERE approval_dashboard_sid = in_dashboard_sid
			   AND ind_sid = r.column_value;
		END;
	END LOOP;

	-- Now disable the removed ones
	FOR r IN (
		SELECT ind_sid
		  FROM approval_dashboard_ind
		 WHERE ind_sid NOT IN (
			SELECT column_value
			  FROM TABLE(v_indicators)
		 )
	)
	LOOP
		UPDATE approval_dashboard_ind
		   SET deactivated_dtm = SYSDATE
		 WHERE approval_dashboard_sid = in_dashboard_sid
		   AND ind_sid = r.ind_sid;
	END LOOP;
END;

PROCEDURE CompareRecentInstances(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_live_dashboard_instance_id	OUT	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_locked_dashboard_inst_id	OUT	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetMostRecentInstance(in_approval_dashboard_sid, in_region_sid, 0, out_live_dashboard_instance_id);
	GetMostRecentInstance(in_approval_dashboard_sid, in_region_sid, 1, out_locked_dashboard_inst_id);

	CompareInstances(out_locked_dashboard_inst_id, out_live_dashboard_instance_id, out_cur);
END;

FUNCTION GetIds(
	in_val_id						IN	NUMBER
) RETURN CLOB
AS
	v_ids			CLOB;
BEGIN
	SELECT REPLACE(stragg3(id), ',', '|')
	  INTO v_ids
	  FROM (
		SELECT rownum rn, id
		  FROM (
				SELECT id
				  FROM approval_dashboard_val_src
				 WHERE approval_dashboard_val_id = in_val_id
				 GROUP BY id)
				)
		 START WITH rn = 1
		CONNECT BY rn = PRIOR rn + 1;

	RETURN v_ids;
END;

PROCEDURE CompareInstances(
	in_instance_id_a				IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_instance_id_b				IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ia.dashboard_instance_id id, ib.dashboard_instance_id id2, ia.APPROVAL_DASHBOARD_SID, ia.ind_sid, ia.start_dtm, ia.end_dtm, ia.val_number val_a, ia.ytd_val_number val_ytd_a, ia.approval_dashboard_val_id val_id_a,
			NVL(ib.val_number, 0) val_b, NVL(ib.ytd_val_number, 0) val_ytd_b, NVL(ib.approval_dashboard_val_id, 0) val_id_b, NVL(ia.val_number, 0) - NVL(ib.val_number, 0) val_diff, ia.note,  cu.full_name note_added_by_full_name,
			cu.email note_added_by_email, ia.note_added_dtm, ia.is_estimated_data, GetIds(ia.approval_dashboard_val_id) ids_a, GetIds(ib.approval_dashboard_val_id) ids_b
		  FROM approval_dashboard_val ia
	 LEFT JOIN approval_dashboard_val ib 		 ON ia.ind_sid   		 	 = ib.ind_sid
												AND ia.start_dtm 		 	 = ib.start_dtm
												AND ia.end_dtm   		 	 = ib.end_dtm
												AND ib.dashboard_instance_id = in_instance_id_a
	 LEFT JOIN csr_user cu 				 		 ON ia.note_added_by_sid 	 = cu.csr_user_sid
		  JOIN approval_dashboard_instance adi	 ON adi.dashboard_instance_id = ia.dashboard_instance_id
		 WHERE ia.dashboard_instance_id = in_instance_id_b
		   AND ia.start_dtm != adi.start_dtm
		   AND ia.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ia.start_dtm;
END;

PROCEDURE GetValsForComparePortlet(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_compare_cur					OUT	SYS_REFCURSOR,
	out_livedata_cur				OUT SYS_REFCURSOR,
	out_instance_cur				OUT SYS_REFCURSOR
)
AS
	v_active_dashboard_instance_id		APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_prev_dashboard_instance_id		APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
BEGIN
	OPEN out_ind_cur FOR
		SELECT i.ind_sid, i.description ind_description, i.ind_type, nvl(i.format_mask, m.format_mask) format_mask, adi.deactivated_dtm, adi.is_hidden
		  FROM approval_dashboard_ind adi
		  JOIN v$ind i 		ON adi.ind_sid 		= i.ind_sid
		  JOIN measure m 	ON i.measure_sid 	= m.measure_sid
		 WHERE adi.approval_dashboard_sid 		= in_approval_dashboard_sid
		 ORDER BY adi.pos ASC;

	--Look for instances by the period.
	SELECT dashboard_instance_id
	  INTO v_active_dashboard_instance_id
	  FROM approval_dashboard_instance
	 WHERE start_dtm = in_start_dtm
	   AND (in_end_dtm IS NULL or end_dtm = in_end_dtm)
	   AND region_sid = in_region_sid
	   AND approval_dashboard_sid = in_approval_dashboard_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		SELECT dashboard_instance_id
		  INTO v_prev_dashboard_instance_id
		  FROM approval_dashboard_instance
		 WHERE end_dtm = in_start_dtm
		   AND region_sid = in_region_sid
		   AND approval_dashboard_sid = in_approval_dashboard_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		CompareInstances(v_prev_dashboard_instance_id, v_active_dashboard_instance_id, out_compare_cur);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--Must be the first instance, so no compare data is available
			NULL;
	END;

	--Now get the live data - using the id we have gotten from the compare

	OPEN out_livedata_cur FOR
		SELECT adv.ind_sid, adv.start_dtm, adv.end_dtm, adv.val_number, adv.ytd_val_number, adv.approval_dashboard_val_id, adv.is_estimated_data
		  FROM approval_dashboard_val adv
		  JOIN approval_dashboard_instance adi 	ON adi.dashboard_instance_id = adv.dashboard_instance_id
		 WHERE adi.dashboard_instance_id = v_active_dashboard_instance_id
		   AND adv.start_dtm >= adi.start_dtm
		   AND adv.end_dtm <= adi.end_dtm
		   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_instance_cur FOR
		SELECT adi.last_refreshed_dtm, adi.is_locked, CASE adi.is_locked WHEN 1 THEN fsl.set_dtm ELSE NULL END locked_dtm, adi.dashboard_instance_id, ad.period_set_id, ad.period_interval_id, ad.start_dtm
		  FROM approval_dashboard_instance adi
		  JOIN approval_dashboard ad ON adi.approval_dashboard_sid  = ad.approval_dashboard_sid
		  JOIN flow_item fi 		 ON fi.dashboard_instance_id 	= adi.dashboard_instance_id
		  JOIN flow_state_log fsl 	 ON fi.last_flow_state_log_id 	= fsl.flow_state_log_id
		 WHERE adi.dashboard_instance_id = v_active_dashboard_instance_id
		   AND adi.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetValsBetween(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD_INSTANCE.approval_dashboard_sid%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_start_dtm					IN	APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE,
	in_end_dtm						IN	APPROVAL_DASHBOARD_INSTANCE.end_dtm%TYPE,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_val_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	--TODO
	--These needs to join onto the instance table and only pull values for that instance

	OPEN out_ind_cur FOR
		SELECT UNIQUE(ads.ind_sid) ind_sid, i.description
		  FROM approval_dashboard_val ads
		  JOIN v$ind i ON ads.ind_sid = i.ind_sid
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid
		   AND start_dtm 			 >= in_start_dtm
		   AND end_dtm 				 <= in_end_dtm
		   AND ads.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ind_sid;

	OPEN out_val_cur FOR
		SELECT approval_dashboard_val_id, dashboard_instance_id, ind_sid, start_dtm, end_dtm, val_number
		  FROM approval_dashboard_val
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid
		   AND start_dtm 			 >= in_start_dtm
		   AND end_dtm 				 <= in_end_dtm
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ind_sid, start_dtm, dashboard_instance_id;
END;

PROCEDURE TransitionLockInstance(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_approval_dashboard_sid			security_pkg.T_SID_ID;
	v_region_sid						security_pkg.T_SID_ID;
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_new_start_dtm						APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_new_end_dtm						APPROVAL_DASHBOARD_INSTANCE.end_dtm%TYPE;
	v_active_period_scen_run_sid		APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE;
	v_signed_off_scen_run_sid			APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE;
BEGIN
	SELECT adi.approval_dashboard_sid, adi.region_sid, adi.dashboard_instance_id
	  INTO v_approval_dashboard_sid, v_region_sid, v_dashboard_instance_id
	  FROM flow_item fi
	  JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id AND fi.app_sid = adi.app_sid
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--Lock it
	LockInstance(v_dashboard_instance_id);
END;

PROCEDURE LockInstance(
	in_dashboard_instance_id		IN APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
BEGIN
	UPDATE approval_dashboard_instance
	   SET is_locked = 1
	 WHERE dashboard_instance_id = in_dashboard_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE TransitionUnlockInstance(
	in_flow_sid						IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_approval_dashboard_sid			security_pkg.T_SID_ID;
	v_region_sid						security_pkg.T_SID_ID;
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_new_start_dtm						APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_new_end_dtm						APPROVAL_DASHBOARD_INSTANCE.end_dtm%TYPE;
	v_active_period_scen_run_sid		APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE;
	v_signed_off_scen_run_sid			APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE;
BEGIN
	SELECT adi.approval_dashboard_sid, adi.region_sid, adi.dashboard_instance_id
	  INTO v_approval_dashboard_sid, v_region_sid, v_dashboard_instance_id
	  FROM flow_item fi
	  JOIN approval_dashboard_instance adi ON fi.dashboard_instance_id = adi.dashboard_instance_id AND fi.app_sid = adi.app_sid
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--Unlock it
	UnlockInstance(v_dashboard_instance_id);
END;

PROCEDURE UnlockInstance(
	in_dashboard_instance_id		IN APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
BEGIN
	UPDATE approval_dashboard_instance
	   SET is_locked = 0
	 WHERE dashboard_instance_id = in_dashboard_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE TransitionSignOffInstance(
	in_in_flow_sid					IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_signed_off_scenario_run_sid		APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE;
BEGIN
	SELECT adi.dashboard_instance_id, ad.signed_off_scenario_run_sid
	  INTO v_dashboard_instance_id, v_signed_off_scenario_run_sid
	  FROM flow_item fi
	  JOIN approval_dashboard_instance adi 	ON fi.dashboard_instance_id = adi.dashboard_instance_id AND fi.app_sid = adi.app_sid
	  JOIN approval_dashboard ad 			ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- Update the instance and queue the recalc on the scenario
	UPDATE approval_dashboard_instance
	   SET is_signed_off = 1
	 WHERE dashboard_instance_id = v_dashboard_instance_id;

	stored_calc_datasource_pkg.AddFullScenarioJob(SYS_CONTEXT('SECURITY', 'app'), v_signed_off_scenario_run_sid, 0, 0);
END;

PROCEDURE TransitionReopenSignedOffInst(
	in_in_flow_sid					IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_signed_off_scenario_run_sid		APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE;
BEGIN
	SELECT adi.dashboard_instance_id, ad.signed_off_scenario_run_sid
	  INTO v_dashboard_instance_id, v_signed_off_scenario_run_sid
	  FROM flow_item fi
	  JOIN approval_dashboard_instance adi 	ON fi.dashboard_instance_id = adi.dashboard_instance_id AND fi.app_sid = adi.app_sid
	  JOIN approval_dashboard ad 			ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- Update the instance and queue the recalc on the scenario
	UPDATE approval_dashboard_instance
	   SET is_signed_off = 0
	 WHERE dashboard_instance_id = v_dashboard_instance_id;

	stored_calc_datasource_pkg.AddFullScenarioJob(SYS_CONTEXT('SECURITY', 'app'), v_signed_off_scenario_run_sid, 0, 0);
END;

PROCEDURE TransitionPublish(
	in_in_flow_sid					IN	security_pkg.T_SID_ID,
	in_flow_item_id					IN	csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN	csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN	csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_approval_dashboard_sid			security_pkg.T_SID_ID;
	v_region_sid						security_pkg.T_SID_ID;
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_tpl_report_sid					APPROVAL_DASHBOARD.tpl_report_sid%TYPE;
	v_doc_folder_sid					APPROVAL_DASHBOARD.publish_doc_folder_sid%TYPE;
	v_start_dtm							APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_batch_job_request					CLOB;
	v_batch_job_id						BATCH_JOB.batch_job_id%TYPE;
BEGIN
	SELECT adi.approval_dashboard_sid, adi.region_sid, adi.dashboard_instance_id, ad.tpl_report_sid, ad.publish_doc_folder_sid, adi.start_dtm
	  INTO v_approval_dashboard_sid, v_region_sid, v_dashboard_instance_id, v_tpl_report_sid, v_doc_folder_sid, v_start_dtm
	  FROM flow_item fi
	  JOIN approval_dashboard_instance adi 	ON fi.dashboard_instance_id = adi.dashboard_instance_id AND fi.app_sid = adi.app_sid
	  JOIN approval_dashboard ad 			ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND fi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_doc_folder_sid IS NOT NULL THEN
		-- Create a batch job
		v_batch_job_request := '<?xml version = ''1.0'' encoding = ''UTF-8''?><TemplatedReportRequest xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'||
		   '<UseUnmerged>false</UseUnmerged>'||
		   '<TplReportSid>'||v_tpl_report_sid||'</TplReportSid>'||
		   '<RegionSids>'||
			  '<long>'||v_region_sid||'</long>'||
		   '</RegionSids>'||
		   '<IsPdf>false</IsPdf>'||
		   '<IncludeInactiveRegions>false</IncludeInactiveRegions>'||
		   '<RegionSelectionTypeId>6</RegionSelectionTypeId>'||
		   '<RegionSelectionTagId xsi:nil="true"/>'||
		   '<OneReportPerRegion>false</OneReportPerRegion>'||
		   '<DocFolderSid>'||v_doc_folder_sid||'</DocFolderSid>'||
		   '<OverwriteExisting>false</OverwriteExisting>'||
		   '<GeneratedForRole>false</GeneratedForRole>'||
		   '<ProxyStartDtm>'||v_start_dtm||'</ProxyStartDtm>'||
		   '<ProxyEndDtm>01/01/0001 00:00:00</ProxyEndDtm>'||
		'</TemplatedReportRequest>';

		templated_report_pkg.SetBatchJob(v_batch_job_request, in_user_sid, null, v_batch_job_id);
	END IF;
END;

PROCEDURE GetScenariosForPortlet(
	in_tab_portlet_id				IN	TAB_PORTLET.tab_portlet_id%TYPE,
	out_active_period_scen_run_sid	OUT	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	out_signed_off_scen_run_sid		OUT	APPROVAL_DASHBOARD.signed_off_scenario_run_sid%TYPE
)
AS
BEGIN
	SELECT active_period_scenario_run_sid, signed_off_scenario_run_sid
	  INTO out_active_period_scen_run_sid, out_signed_off_scen_run_sid
	  FROM TAB_PORTLET tp
	  JOIN approval_dashboard_tab adt 	ON adt.tab_id = tp.tab_id
	  JOIN approval_dashboard ad 		ON ad.approval_dashboard_sid = adt.approval_dashboard_sid
	 WHERE tp.tab_portlet_id = in_tab_portlet_id
	   AND ad.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAggregateValueHistory(
	in_current_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_previous_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT id, description, source_detail, aig.source_url, 0 removed, 1 added, 0 unchanged
		  FROM approval_dashboard_val_src src
		  JOIN approval_dashboard_val val 		ON val.approval_dashboard_val_id = src.approval_dashboard_val_id
	 LEFT JOIN aggregate_ind_group_member aigm 	ON aigm.ind_sid = val.ind_sid
	 LEFT JOIN aggregate_ind_group aig 			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		 WHERE src.approval_dashboard_val_id = in_current_val_id
		   AND id NOT IN (
			SELECT id
			  FROM approval_dashboard_val_src
			 WHERE approval_dashboard_val_id = in_previous_val_id
		   )
		   AND src.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 UNION
		SELECT id, description, source_detail, aig.source_url, 0 removed, 0 added, 1 unchanged
		  FROM approval_dashboard_val_src src
		  JOIN approval_dashboard_val val 		ON val.approval_dashboard_val_id = src.approval_dashboard_val_id
	 LEFT JOIN aggregate_ind_group_member aigm 	ON aigm.ind_sid = val.ind_sid
	 LEFT JOIN aggregate_ind_group aig 			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		 WHERE src.approval_dashboard_val_id = in_current_val_id
		   AND id IN (
			SELECT id
			  FROM approval_dashboard_val_src
			 WHERE approval_dashboard_val_id = in_previous_val_id
		   )
		   AND src.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 UNION
		SELECT id, description, source_detail, aig.source_url, 1 removed, 0 added, 0 unchanged
		  FROM approval_dashboard_val_src src
		  JOIN approval_dashboard_val val 		ON val.approval_dashboard_val_id = src.approval_dashboard_val_id
	 LEFT JOIN aggregate_ind_group_member aigm 	ON aigm.ind_sid = val.ind_sid
	 LEFT JOIN aggregate_ind_group aig 			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		 WHERE src.approval_dashboard_val_id = in_previous_val_id
		   AND src.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND id NOT IN (
			SELECT id
			  FROM approval_dashboard_val_src
			 WHERE approval_dashboard_val_id = in_current_val_id
			);

END;

PROCEDURE GetNonAggNonTrackedValHistory(
	in_current_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_source						IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT adv.val_number, 0 source_type_id, 0, null changed_by_sid, adi.last_refreshed_dtm changed_dtm, 'Refreshed dashboard' reason, '' full_name, '' changed_by_email, in_source description,
			   r.description region_description, r.region_type, adv.start_dtm period_start_dtm, adv.end_dtm period_end_dtm
		  FROM approval_dashboard_val adv
		  JOIN approval_dashboard_instance adi 	ON adv.dashboard_instance_id = adi.dashboard_instance_id
		  JOIN v$region r						ON adi.region_sid = r.region_sid
		 WHERE approval_dashboard_val_id = in_current_val_id
		   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetValueHistory(
	in_current_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_previous_val_id				IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_region						IN	REGION.region_sid%TYPE,
	out_ind_type					OUT	SYS_REFCURSOR,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_sid							IND.ind_sid%TYPE;
	v_ind_type							IND.ind_type%TYPE;
	v_start_dtm							APPROVAL_DASHBOARD_VAL.start_dtm%TYPE;
	v_end_dtm							APPROVAL_DASHBOARD_VAL.end_dtm%TYPE;
	v_prev_inst_refresh_dtm				APPROVAL_DASHBOARD_INSTANCE.last_refreshed_dtm%TYPE;
	v_curr_inst_refresh_dtm				APPROVAL_DASHBOARD_INSTANCE.last_refreshed_dtm%TYPE;
	v_using_nonmerged_datasource		NUMBER(1);
BEGIN
	SELECT i.ind_type, adv.ind_sid, adv.start_dtm, adv.end_dtm
	  INTO v_ind_type, v_ind_sid, v_start_dtm, v_end_dtm
	  FROM approval_dashboard_val adv
	  JOIN IND i ON i.ind_sid = adv.ind_sid
	 WHERE approval_dashboard_val_id = in_current_val_id
	   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT CASE NVL(ad.source_scenario_run_sid, -1) WHEN c.merged_scenario_run_sid THEN 0 WHEN -1 THEN 0 ELSE 1 END
	  INTO v_using_nonmerged_datasource
	  FROM approval_dashboard ad
	  JOIN approval_dashboard_val val on val.approval_dashboard_sid = ad.approval_dashboard_sid
	  JOIN customer c on c.app_sid = ad.app_sid
	 WHERE val.approval_dashboard_val_id = in_current_val_id
	   AND ad.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_type FOR
		SELECT ind_type, NVL(i.format_mask, m.format_mask) format_mask
		  FROM v$ind i
		  JOIN measure m ON m.measure_sid = i.measure_sid
		 WHERE ind_sid = v_ind_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--Aggregate ind
	IF v_ind_type = 3 THEN
		GetAggregateValueHistory(in_current_val_id, in_previous_val_id, out_cur);
		RETURN;
	ELSIF v_ind_type IN (1, 2) THEN
		-- It's a standard or stored calc, so we pulled the value from the datasource; there is no backing data.
		GetNonAggNonTrackedValHistory(in_current_val_id, 'Calculation', out_cur);
	ELSE
		-- If not using Merged, don't try and drill back.
		IF v_using_nonmerged_datasource = 1 THEN
			GetNonAggNonTrackedValHistory(in_current_val_id, 'Scenario data', out_cur);
		ELSE
		
			IF in_previous_val_id = 0 THEN
				-- No previous instance; ie it must be newest data.
				v_prev_inst_refresh_dtm := NULL;
			ELSE
				SELECT adi.last_refreshed_dtm
				  INTO v_prev_inst_refresh_dtm
				  FROM approval_dashboard_val adv
				  JOIN approval_dashboard_instance adi ON adv.dashboard_instance_id = adi.dashboard_instance_id
				 WHERE approval_dashboard_val_id = in_previous_val_id
				   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');
			END IF;

			SELECT adi.last_refreshed_dtm
			  INTO v_curr_inst_refresh_dtm
			  FROM approval_dashboard_val adv
			  JOIN approval_dashboard_instance adi ON adv.dashboard_instance_id = adi.dashboard_instance_id
			 WHERE approval_dashboard_val_id = in_current_val_id
			   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');

			--Find it in the core system
			OPEN out_cur FOR
				SELECT v.val_number, v.source_type_id, v.source_id, v.changed_by_sid, v.changed_dtm, v.period_start_dtm, v.period_end_dtm, '' reason, cu.full_name, cu.email changed_by_email,
					CASE WHEN st.source_type_id = 1 THEN d.name ELSE st.description END description, r.description region_description, r.region_type
				  FROM val v
				  JOIN csr_user cu 			ON v.changed_by_sid		= cu.csr_user_sid
				  JOIN source_type st 		ON v.source_type_id 	= st.source_type_id
				  LEFT JOIN sheet_value sv 	ON sv.sheet_value_id 	= v.source_id
				  LEFT JOIN sheet s 		ON s.sheet_id 			= sv.sheet_id
				  LEFT JOIN delegation d 	ON d.delegation_sid 	= s.delegation_sid
				  JOIN v$region r ON v.region_sid = r.region_sid
				 WHERE v.ind_sid = v_ind_sid
				   AND v.region_sid IN (
						SELECT region_sid
						  FROM region
					   CONNECT BY PRIOR region_sid = parent_sid
						 START WITH region_sid = in_region
					)
				   --AND changed_dtm < v_last_refreshed_dtm
				   AND period_start_dtm >= v_start_dtm
				   AND period_end_dtm <= v_end_dtm
				   AND v.val_number IS NOT NULL
				 ORDER BY period_start_dtm DESC;
		END IF;

	END IF;
END;

PROCEDURE GetPeriodValueHistory(
	in_dashboard_instance_id		IN	APPROVAL_DASHBOARD_VAL.dashboard_instance_id%TYPE,
	in_ind_sid						IN	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_ytd_value					IN	NUMBER,
	out_ind_type					OUT	SYS_REFCURSOR,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_ind_type							IND.ind_type%TYPE;
	v_region							APPROVAL_DASHBOARD_REGION.region_sid%TYPE;
	v_last_refreshed_dtm				APPROVAL_DASHBOARD_INSTANCE.last_refreshed_dtm%TYPE;
	v_period_start_dtm					APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_period_end_dtm					APPROVAL_DASHBOARD_INSTANCE.end_dtm%TYPE;
BEGIN
	SELECT ind_type
	  INTO v_ind_type
	  FROM IND
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_type FOR
		SELECT ind_type, NVL(i.format_mask, m.format_mask) format_mask
		  FROM v$ind i
		  JOIN measure m ON m.measure_sid = i.measure_sid
		 WHERE ind_sid = in_ind_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_ind_type = 3 THEN
		IF in_ytd_value = 1 THEN
			OPEN out_cur FOR
				SELECT id, description, source_detail, aig.source_url
				  FROM approval_dashboard_val_src
				  JOIN approval_dashboard_val adv 		ON approval_dashboard_val_src.approval_dashboard_val_id = adv.approval_dashboard_val_id
				  JOIN approval_dashboard_instance adi 	ON adv.dashboard_instance_id = adi.dashboard_instance_id
			 LEFT JOIN aggregate_ind_group_member aigm 	ON adv.ind_sid = aigm.ind_sid
			 LEFT JOIN aggregate_ind_group aig 			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
				 WHERE adv.dashboard_instance_id = in_dashboard_instance_id
				   AND adv.ind_sid = in_ind_sid
				   AND TRUNC(adi.start_dtm, 'YEAR') = TRUNC(adv.START_DTM, 'YEAR')
				   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			  ORDER BY id;
		ELSE
			OPEN out_cur FOR
				SELECT src.id, src.description, src.source_detail, aig.source_url
				  FROM approval_dashboard_val_src src
				  JOIN approval_dashboard_val val 		ON src.approval_dashboard_val_id = val.approval_dashboard_val_id
				  JOIN approval_dashboard_instance adi 	ON adi.dashboard_instance_id = val.dashboard_instance_id
			 LEFT JOIN aggregate_ind_group_member aigm 	ON val.ind_sid = aigm.ind_sid
			 LEFT JOIN aggregate_ind_group aig 			ON aig.aggregate_ind_group_id = aigm.aggregate_ind_group_id
				 WHERE val.ind_sid 				 = in_ind_sid
				   AND val.dashboard_instance_id = in_dashboard_instance_id
				   AND val.start_dtm 			 = adi.start_dtm
				   AND src.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	ELSIF v_ind_type = 1 THEN
		-- It's a standard calc, so we pulled the value from the datasource; there is no backing data.
		OPEN out_cur FOR
			SELECT CASE in_ytd_value WHEN 0 THEN adv.val_number ELSE adv.ytd_val_number END val_number, 0 source_type_id, 0, null changed_by_sid, adi.last_refreshed_dtm changed_dtm, 'Refreshed dashboard' reason,
				'' full_name, '' changed_by_email, 'Calculation' description, r.description region_description, r.region_type
			  FROM approval_dashboard_instance adi
			  JOIN approval_dashboard_val adv 	 ON adv.dashboard_instance_id = adi.dashboard_instance_id
												AND adv.start_dtm = adi.start_dtm
												AND adv.end_dtm = adi.end_dtm
			  JOIN v$region r					 ON r.region_sid = adi.region_sid
			 WHERE adi.dashboard_instance_id = in_dashboard_instance_id
			   AND adv.ind_sid = in_ind_sid
			   AND adv.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE
		SELECT last_refreshed_dtm, region_sid
		  INTO v_last_refreshed_dtm, v_region
		  FROM approval_dashboard_instance
		 WHERE dashboard_instance_id = in_dashboard_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		--get the period for the values
		IF in_ytd_value = 1 THEN
			SELECT TRUNC(adi.start_dtm, 'YEAR') start_dtm, adi.end_dtm
			  INTO v_period_start_dtm, v_period_end_dtm
			  FROM approval_dashboard_instance adi
			  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
			 WHERE dashboard_instance_id = in_dashboard_instance_id
			   AND adi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

			OPEN out_cur FOR
				SELECT v.val_number, v.source_type_id, v.source_id, v.changed_by_sid, v.changed_dtm, v.period_start_dtm, v.period_end_dtm, '' reason, cu.full_name, cu.email changed_by_email,
					CASE WHEN st.source_type_id = 1 THEN d.name ELSE st.description END description
				  FROM val v
				  JOIN csr_user cu 		ON v.changed_by_sid		= cu.csr_user_sid
				  JOIN source_type st 	ON v.source_type_id 	= st.source_type_id
			 LEFT JOIN sheet_value sv 	ON sv.sheet_value_id 	= v.source_id
			 LEFT JOIN sheet s 			ON s.sheet_id 			= sv.sheet_id
			 LEFT JOIN delegation d 	ON d.delegation_sid 	= s.delegation_sid
				 WHERE v.ind_sid = in_ind_sid
				   AND v.region_sid = v_region
				   AND period_start_dtm >= v_period_start_dtm
				   AND period_end_dtm <= v_period_end_dtm
				   AND v.val_number IS NOT NULL
				   AND v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 ORDER BY period_start_dtm DESC;
		ELSE
			SELECT start_dtm, end_dtm
			  INTO v_period_start_dtm, v_period_end_dtm
			  FROM approval_dashboard_instance
			 WHERE dashboard_instance_id = in_dashboard_instance_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

			OPEN out_cur FOR
				SELECT v.val_number, v.source_type_id, v.source_id, v.changed_by_sid, v.changed_dtm, v.period_start_dtm, v.period_end_dtm, '' reason, cu.full_name, cu.email changed_by_email, r.description region_description,
					r.region_type, CASE WHEN st.source_type_id = 1 THEN d.name ELSE st.description END description
				  FROM val v
				  JOIN csr_user cu 		ON v.changed_by_sid		= cu.csr_user_sid
				  JOIN source_type st 	ON v.source_type_id 	= st.source_type_id
				  JOIN v$region r		ON v.region_sid			= r.region_sid
			 LEFT JOIN sheet_value sv 	ON sv.sheet_value_id 	= v.source_id
			 LEFT JOIN sheet s 			ON s.sheet_id 			= sv.sheet_id
			 LEFT JOIN delegation d 	ON d.delegation_sid 	= s.delegation_sid
				 WHERE v.ind_sid = in_ind_sid
				   AND v.region_sid IN (
						SELECT region_sid
						  FROM region
					   CONNECT BY PRIOR region_sid = parent_sid
						 START WITH region_sid = v_region
				   )
				   AND period_start_dtm >= v_period_start_dtm
				   AND period_end_dtm <= v_period_end_dtm
				   AND v.val_number IS NOT NULL
				   AND v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 ORDER BY period_start_dtm DESC;
		END IF;
	END IF;
END;

PROCEDURE SetValueNote(
	in_approval_dashboard_val_id	IN	APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE,
	in_note							IN	APPROVAL_DASHBOARD_VAL.note%TYPE,
	in_note_added_by_sid			IN	APPROVAL_DASHBOARD_VAL.note_added_by_sid%TYPE,
	out_result						OUT	NUMBER
)
AS
	v_current_note					APPROVAL_DASHBOARD_VAL.note%TYPE;
BEGIN
	SELECT UPPER(note)
	  INTO v_current_note
	  FROM approval_dashboard_val
	 WHERE approval_dashboard_val_id = in_approval_dashboard_val_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	 IF v_current_note = UPPER(in_note) THEN
		out_result := 0;
	 ELSE
		UPDATE approval_dashboard_val
		   SET note 				= in_note,
			   note_added_by_sid 	= in_note_added_by_sid,
			   note_added_dtm 		= SYSDATE
		 WHERE approval_dashboard_val_id = in_approval_dashboard_val_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		 out_result := 1;
	 END IF;
END;

PROCEDURE GetDataForRefreshBatchJob(
	in_batch_job_id					IN 	BATCH_JOB_APPROVAL_DASH_VALS.batch_job_id%TYPE,
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_ind_cur						OUT SYS_REFCURSOR,
	out_descendant_region_cur		OUT	SYS_REFCURSOR
)
AS
	v_dashboard_instance_id				APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
BEGIN
	SELECT dashboard_instance_id
	  INTO v_dashboard_instance_id
	  FROM batch_job_approval_dash_vals
	 WHERE batch_job_id = in_batch_job_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetDataForRefresh(v_dashboard_instance_id, out_dashboard_cur, out_ind_cur);

	OPEN out_descendant_region_cur FOR
		SELECT r.region_sid
		  FROM region r
		 START WITH r.region_sid = (SELECT region_sid FROM  approval_dashboard_instance where dashboard_instance_id = v_dashboard_instance_id)
	   CONNECT BY PRIOR r.region_sid = r.parent_sid;
END;

PROCEDURE GetDataForRefresh(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_ind_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_dashboard_cur FOR
		SELECT ad.approval_dashboard_sid, adi.dashboard_instance_id, adi.region_sid, ad.active_period_scenario_run_sid, ad.signed_off_scenario_run_sid, ad.start_dtm dashboard_start_dtm,
			   adi.end_dtm dashboard_end_dtm, ad.period_set_id, ad.period_interval_id, adi.is_locked, adi.start_dtm instance_start_dtm, ad.source_scenario_run_sid
		  FROM approval_dashboard_instance adi
		  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = adi.approval_dashboard_sid
		 WHERE adi.dashboard_instance_id = in_dashboard_instance_id
		   AND adi.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_cur FOR
		SELECT ind.ind_sid
		  FROM approval_dashboard_instance adi
		  JOIN approval_dashboard_ind ind ON ind.approval_dashboard_sid = adi.approval_dashboard_sid
		 WHERE adi.dashboard_instance_id = in_dashboard_instance_id
		   AND ind.deactivated_dtm IS NULL
		   AND adi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY pos ASC;
END;

PROCEDURE CreateDataRefreshBatchJob(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_instance_is_locked				APPROVAL_DASHBOARD_INSTANCE.is_locked%TYPE;
BEGIN
	SELECT is_locked
	  INTO v_instance_is_locked
	  FROM approval_dashboard_instance
	 WHERE dashboard_instance_id = in_dashboard_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	/*IF v_instance_is_locked = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot create refresh job because the instance is locked.');
	END IF;*/

	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_APPROVAL_DASHBOARD,
		in_description => 'Approval dashboard data refresh',
		in_total_work => 2,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_approval_dash_vals
		(dashboard_instance_id, batch_job_id)
	VALUES
		(in_dashboard_instance_id, out_batch_job_id);
END;

PROCEDURE UpsertInstanceValue(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_ind_sid						IN 	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_start_dtm					IN 	APPROVAL_DASHBOARD_VAL.start_dtm%TYPE,
	in_end_dtm						IN 	APPROVAL_DASHBOARD_VAL.end_dtm%TYPE,
	in_val_number					IN 	APPROVAL_DASHBOARD_VAL.val_number%TYPE,
	in_ytd_number					IN 	APPROVAL_DASHBOARD_VAL.ytd_val_number%TYPE
)
AS
	v_val_id							APPROVAL_DASHBOARD_VAL.approval_dashboard_val_id%TYPE;
	v_val_number						APPROVAL_DASHBOARD_VAL.val_number%TYPE;
	v_existing_val_number				APPROVAL_DASHBOARD_VAL.val_number%TYPE;
	v_ind_type							IND.ind_type%TYPE;
	v_region_sid						APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE;
	v_allow_estimated					APPROVAL_DASHBOARD_IND.allow_estimated_data%TYPE;
	v_is_estimated						APPROVAL_DASHBOARD_VAL.is_estimated_data%TYPE;
BEGIN
	-- Indicators where 'allow_estimated_data' is 1 will take a value from the previous instance if they come through with a 0 or null
	SELECT allow_estimated_data
	  INTO v_allow_estimated
	  FROM approval_dashboard_ind
	 WHERE ind_sid = in_ind_sid
	   AND approval_dashboard_sid = in_approval_dashboard_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_allow_estimated = 1 AND (in_val_number IS NULL OR in_val_number = 0) THEN
		SELECT NVL(MIN(val_number), 0)
		  INTO v_val_number
		  FROM approval_dashboard_val
		 WHERE dashboard_instance_id = in_dashboard_instance_id
		   AND ind_sid = in_ind_sid
		   AND end_dtm = in_start_dtm -- To get the value from the previous period
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		v_is_estimated := 1;
	ELSE
		v_val_number := in_val_number;
		v_is_estimated := 0;
	END IF;

	-- Upsert the new value; but with the added caveat that if the value has changed we should blank out the note.
	BEGIN
		SELECT adv.approval_dashboard_val_id, adv.val_number, i.ind_type, adi.region_sid
		  INTO v_val_id, v_existing_val_number, v_ind_type, v_region_sid
		  FROM approval_dashboard_val adv
		  JOIN ind i 							ON i.ind_sid = adv.ind_sid
		  JOIN approval_dashboard_instance adi 	ON adi.dashboard_instance_id = adv.dashboard_instance_id
		 WHERE adv.approval_dashboard_sid	= in_approval_dashboard_sid
		   AND adv.dashboard_instance_id	= in_dashboard_instance_id
		   AND adv.ind_sid				= in_ind_sid
		   AND adv.start_dtm			= in_start_dtm
		   AND adv.end_dtm				= in_end_dtm
		   AND adv.app_sid				= SYS_CONTEXT('SECURITY', 'APP');

		IF v_val_number != v_existing_val_number THEN
			-- Null out the note
			UPDATE approval_dashboard_val
			   SET val_number 			= v_val_number,
			       ytd_val_number		= in_ytd_number,
			       note					= NULL,
			       note_added_by_sid	= NULL,
			       note_added_dtm		= NULL,
			       is_estimated_data	= v_is_estimated
			 WHERE approval_dashboard_val_id = v_val_id
			   AND app_sid 					 = SYS_CONTEXT('SECURITY', 'APP');
		ELSE
			-- Don't null out the note as the value hasn't changed. The YTD might have though, so we still do an update
			UPDATE approval_dashboard_val
			   SET val_number 			= v_val_number,
			       ytd_val_number		= in_ytd_number,
			       is_estimated_data	= v_is_estimated
			 WHERE approval_dashboard_val_id = v_val_id
			   AND app_sid 					 = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- doesn't exist yet, so just insert
			INSERT INTO approval_dashboard_val
				(approval_dashboard_val_id, approval_dashboard_sid, dashboard_instance_id, ind_sid, start_dtm, end_dtm, val_number, ytd_val_number, is_estimated_data)
			VALUES
				(APPROVAL_DASHBOARD_VAL_ID_SEQ.nextval, in_approval_dashboard_sid, in_dashboard_instance_id, in_ind_sid, in_start_dtm, in_end_dtm, v_val_number, in_ytd_number, v_is_estimated)
			RETURNING approval_dashboard_val_id INTO v_val_id;
	END;
END;

PROCEDURE InsertSourceValue(
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_src_id						IN	APPROVAL_DASHBOARD_VAL_SRC.id%TYPE,
	in_src_desc						IN	APPROVAL_DASHBOARD_VAL_SRC.description%TYPE,
	in_src_detail					IN	APPROVAL_DASHBOARD_VAL_SRC.source_detail%TYPE,
	in_ind_sid						IN	APPROVAL_DASHBOARD_VAL.ind_sid%TYPE,
	in_start_dtm					IN	APPROVAL_DASHBOARD_VAL.start_dtm%TYPE,
	in_end_dtm						IN	APPROVAL_DASHBOARD_VAL.end_dtm%TYPE
)
AS
	v_val_id				NUMBER;
BEGIN
	SELECT approval_dashboard_val_id
	  INTO v_val_id
	  FROM approval_dashboard_val
	 WHERE dashboard_instance_id = in_instance_id
	   AND ind_sid = in_ind_sid
	   AND start_dtm = in_start_dtm
	   AND end_dtm = in_end_dtm;

	BEGIN
		INSERT INTO approval_dashboard_val_src
			(approval_dashboard_val_id, id, description, source_detail)
		VALUES
			(v_val_id, in_src_id, SUBSTR(in_src_desc, 1, 1023), in_src_detail);
	EXCEPTION
		WHEN others THEN
			INSERT INTO approval_dashboard_val_src
			(approval_dashboard_val_id, id, description, source_detail)
		VALUES
			(v_val_id, in_src_id, SUBSTR(in_src_desc, 1, 256), in_src_detail);
	END;
END;

PROCEDURE PrepForValueInserts(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
	v_instance_is_locked				APPROVAL_DASHBOARD_INSTANCE.is_locked%TYPE;
BEGIN
	SELECT is_locked
	  INTO v_instance_is_locked
	  FROM approval_dashboard_instance
	 WHERE dashboard_instance_id = in_dashboard_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_instance_is_locked = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot prepare instance for data refresh because the instance is locked.');
	END IF;

	UPDATE approval_dashboard_instance
	   SET last_refreshed_dtm = SYSDATE
	 WHERE dashboard_instance_id = in_dashboard_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM approval_dashboard_val_src
	 WHERE approval_dashboard_val_id IN (
		SELECT approval_dashboard_val_id
		  FROM approval_dashboard_val
		 WHERE dashboard_instance_id = in_dashboard_instance_id
	 );
	
	DELETE FROM approval_dashboard_val
	 WHERE dashboard_instance_id = in_dashboard_instance_id;
END;

PROCEDURE QueueActiveDataScenarioRefresh(
	in_dashboard_instance_id		IN 	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE
)
AS
	v_dashboard_sid						APPROVAL_DASHBOARD_INSTANCE.approval_dashboard_sid%TYPE;
	v_region_sid						APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE;
	v_instance_start_dtm				APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_max_refreshed_inst_start			APPROVAL_DASHBOARD_INSTANCE.start_dtm%TYPE;
	v_active_period_scen_run_sid		APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE;
BEGIN
	-- The instance passed in has had it's data refreshed. We may want to refresh the active period scenario, so long as
	-- a more recent instance (for that dashboard/region) hasn't been refreshed yet. This check ensure that if someone
	-- eg, refreshed February AFTER March has already been refreshed, we do not overwrite the March data.

	SELECT ad.approval_dashboard_sid, inst.region_sid, inst.start_dtm, ad.active_period_scenario_run_sid
	  INTO v_dashboard_sid, v_region_sid, v_instance_start_dtm, v_active_period_scen_run_sid
	  FROM approval_dashboard_instance inst
	  JOIN approval_dashboard ad ON ad.approval_dashboard_sid = inst.approval_dashboard_sid
	 WHERE inst.dashboard_instance_id = in_dashboard_instance_id
	   AND inst.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT MAX(start_dtm)
	  INTO v_max_refreshed_inst_start
	  FROM approval_dashboard_instance
	 WHERE region_sid = v_region_sid
	   AND approval_dashboard_sid = v_dashboard_sid
	   AND last_refreshed_dtm IS NOT NULL;

	-- Only bother to recalculate when a later instance HAS NOT been refreshed yet
	-- Ie, if I have refreshed April and this instance is March, we don't want to recalc.
	IF v_instance_start_dtm >= v_max_refreshed_inst_start THEN
		stored_calc_datasource_pkg.AddFullScenarioJob(SYS_CONTEXT('SECURITY', 'app'), v_active_period_scen_run_sid, 0, 0);
	END IF;
END;

PROCEDURE GetActivePeriodVals(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
	out_val_cur						OUT SYS_REFCURSOR,
	out_note_cur					OUT SYS_REFCURSOR,
	out_file_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_val_cur FOR
		SELECT val_id, period_start_dtm, period_end_dtm, ind_sid, region_sid, csr.csr_data_pkg.SOURCE_TYPE_APPROVAL_DASHBOARD source_type_id, source_id, val_number, null error_code,
			   1 is_merged, changed_dtm, null val_key
		  FROM (
			SELECT adv.approval_dashboard_val_id val_id, adv.start_dtm period_start_dtm, adv.end_dtm period_end_dtm, ind_sid, adi.region_sid region_sid,
				   adv.approval_dashboard_val_id source_id, adv.val_number val_number, adi.last_refreshed_dtm changed_dtm, 
				   ROW_NUMBER() OVER (PARTITION BY adv.start_dtm, ind_sid, region_sid ORDER BY adi.last_refreshed_dtm DESC) AS rn
			  FROM approval_dashboard_val adv
			  JOIN approval_dashboard_instance adi ON adi.dashboard_instance_id = adv.dashboard_instance_id
			 WHERE adv.dashboard_instance_id IN (
				SELECT dashboard_instance_id
			  FROM approval_dashboard_instance adi, (
				SELECT MAX(start_dtm) start_dtm, region_sid
				  FROM approval_dashboard_instance
				 WHERE approval_dashboard_sid IN (
					SELECT approval_dashboard_sid
					  FROM approval_dashboard
					 WHERE active_period_scenario_run_sid = in_scenario_run_sid
				)
				   AND last_refreshed_dtm IS NOT NULL
				 GROUP BY approval_dashboard_sid, region_sid) results
			 WHERE adi.region_sid = results.region_sid
			   AND adi.start_dtm = results.start_dtm
			)
			 ORDER BY period_start_dtm, ind_sid, region_sid
		)
		 WHERE rn = 1
		 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

PROCEDURE GetSignedOffVals(
	in_start_dtm					IN  DATE,
	in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
	out_val_cur						OUT SYS_REFCURSOR,
	out_note_cur					OUT SYS_REFCURSOR,
	out_file_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_val_cur FOR
		SELECT val_id, period_start_dtm, period_end_dtm, ind_sid, region_sid, csr.csr_data_pkg.SOURCE_TYPE_APPROVAL_DASHBOARD source_type_id, source_id, val_number, null error_code,
			   1 is_merged, changed_dtm, null val_key
		  FROM (
			SELECT adv.approval_dashboard_val_id val_id, adv.start_dtm period_start_dtm, adv.end_dtm period_end_dtm, ind_sid, adi.region_sid region_sid,
				   adv.approval_dashboard_val_id source_id, adv.val_number val_number, adi.last_refreshed_dtm changed_dtm, 
				   ROW_NUMBER() OVER (PARTITION BY adv.start_dtm, ind_sid, region_sid ORDER BY adi.last_refreshed_dtm DESC) AS rn
			  FROM approval_dashboard_val adv
			  JOIN approval_dashboard_instance adi ON adi.dashboard_instance_id = adv.dashboard_instance_id
			 WHERE adv.dashboard_instance_id IN (
				SELECT MAX(dashboard_instance_id)
				  FROM csr.approval_dashboard_instance
				 WHERE is_signed_off = 1 
				   AND approval_dashboard_sid in (SELECT approval_dashboard_sid FROM csr.approval_dashboard WHERE signed_off_scenario_run_sid = in_scenario_run_sid)
				 GROUP BY approval_dashboard_sid, region_sid
				)
			 ORDER BY period_start_dtm, ind_sid, region_sid
		)
		 WHERE rn = 1
		 ORDER BY ind_sid, region_sid, period_start_dtm;

END;

FUNCTION IsApprovalDashboardScenario(
	in_scenario_run_sid			IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE
) RETURN NUMBER
AS
	v_app_dash_scenario_cnt		NUMBER;
BEGIN	

	SELECT COUNT(*)
	  INTO v_app_dash_scenario_cnt
	  FROM csr.approval_dashboard
	 WHERE active_period_scenario_run_sid = in_scenario_run_sid
	    OR signed_off_scenario_run_sid = in_scenario_run_sid;

	IF v_app_dash_scenario_cnt > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
	
END;


PROCEDURE GetAggregateApprovalVals(
	in_scenario_run_sid				IN	APPROVAL_DASHBOARD.active_period_scenario_run_sid%TYPE,
	in_aggregate_ind_group_id		IN	NUMBER,
	out_value_cur					OUT SYS_REFCURSOR,
	out_source_detail_cur			OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_value_cur FOR
		SELECT val.ind_sid ind_sid, inst.region_sid region_sid, val.start_dtm period_start_dtm, val.end_dtm period_end_dtm, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, 
			   val.val_number val_number, null error_code, val.approval_dashboard_val_id val_key
		  FROM csr.approval_dashboard_val val
		  JOIN csr.approval_dashboard_instance inst ON inst.dashboard_instance_id = val.dashboard_instance_id
		 WHERE val.dashboard_instance_id IN (
			SELECT MAX(dashboard_instance_id)
			  FROM csr.approval_dashboard_instance
			 WHERE (
				(is_signed_off = 1 AND approval_dashboard_sid in (SELECT approval_dashboard_sid FROM csr.approval_dashboard WHERE signed_off_scenario_run_sid = in_scenario_run_sid)) OR
				(last_refreshed_dtm IS NOT NULL AND approval_dashboard_sid IN (SELECT approval_dashboard_sid FROM csr.approval_dashboard WHERE active_period_scenario_run_sid = in_scenario_run_sid))
			 )
			 GROUP BY approval_dashboard_sid, region_sid
		 )
		   AND val.ind_sid IN (
				SELECT ind_sid
				  FROM csr.aggregate_ind_group_member
				 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
		   )
		 ORDER BY val.ind_sid, inst.region_sid, val.start_dtm;

	OPEN out_source_detail_cur FOR
		SELECT id, dbms_lob.substr(description, 1000) detail1, source_detail detail2, val.approval_dashboard_val_id val_key
		  FROM csr.approval_dashboard_val_src src
		  JOIN csr.approval_dashboard_val val ON src.approval_dashboard_val_id = val.approval_dashboard_val_id
		 WHERE src.approval_dashboard_val_id IN (
			SELECT val.approval_dashboard_val_id
			  FROM csr.approval_dashboard_val val
			  JOIN csr.approval_dashboard_instance inst ON inst.dashboard_instance_id = val.dashboard_instance_id
			 WHERE val.dashboard_instance_id IN ( 
				SELECT MAX(dashboard_instance_id)
				  FROM csr.approval_dashboard_instance
				 WHERE (
					(is_signed_off = 1 AND approval_dashboard_sid in (SELECT approval_dashboard_sid FROM csr.approval_dashboard WHERE signed_off_scenario_run_sid = in_scenario_run_sid)) OR
					(last_refreshed_dtm IS NOT NULL AND approval_dashboard_sid IN (SELECT approval_dashboard_sid FROM csr.approval_dashboard WHERE active_period_scenario_run_sid = in_scenario_run_sid))
				 )
				 GROUP BY approval_dashboard_sid, region_sid
			 )
		 )
		  AND val.ind_sid IN (
				SELECT ind_sid
				  FROM csr.aggregate_ind_group_member
				 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
		   )
		 ORDER BY val.approval_dashboard_val_id;

END;

/*
	PROCEDURES USED IN REPORTING SECTION
*/

PROCEDURE GetReportablePortlets(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.name tab_name, p.name portlet_name, adsrp.maps_to_tag_type, tp.tab_portlet_id, tp.tab_id, tp.state
		  FROM TAB_PORTLET tp
		  JOIN TAB t 							 ON t.tab_id = tp.tab_id
		  JOIN CUSTOMER_PORTLET cp 				 ON tp.customer_portlet_sid = cp.customer_portlet_sid
		  JOIN PORTLET p 						 ON cp.portlet_id = p.portlet_id
		  JOIN APPROVAL_DASHBOARD_TAB adt 		 ON t.tab_id = adt.tab_id
		  JOIN APP_DASH_SUP_REPORT_PORTLET adsrp ON adsrp.portlet_type = p.type
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid;
END;

PROCEDURE UpdateDashboardReportSid(
	in_approval_dashboard_sid		IN  APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_tpl_report_sid				IN	APPROVAL_DASHBOARD.tpl_report_sid%TYPE
)
AS
BEGIN
	UPDATE approval_dashboard
	   SET tpl_report_sid = in_tpl_report_sid
	 WHERE approval_dashboard_sid = in_approval_dashboard_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetDashboardReportDetails(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT label, period_set_id, period_interval_id, tpl_report_sid
		  FROM APPROVAL_DASHBOARD
		 WHERE approval_dashboard_sid = in_approval_dashboard_sid;
END;

/*
	PROCEDURES USED BY APPROVAL NOTE PORTLET
*/

PROCEDURE GetApprovalNotePortletNote(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_instance_id						APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_version							APPROVAL_NOTE_PORTLET_NOTE.version%TYPE;
BEGIN
	--Get the applicable instance
	GetInstanceId(in_approval_dashboard_sid, in_start_dtm, in_end_dtm, in_region_sid, v_instance_id);

	--Get the latest version
	GetApprovalNotePortletNoteVers(in_approval_dashboard_sid, v_instance_id, in_region_sid, in_tab_portlet_id, v_version);

	OPEN out_cur FOR
		SELECT note, added_dtm, added_by_sid, version, cu.full_name, cu.email
		  FROM approval_note_portlet_note anpn
		  JOIN csr_user cu ON cu.csr_user_sid = anpn.added_by_sid
		 WHERE approval_dashboard_sid 	= in_approval_dashboard_sid
		   AND dashboard_instance_id	= v_instance_id
		   AND tab_portlet_id			= in_tab_portlet_id
		   AND region_sid 				= in_region_sid
		   AND version					= v_version
		   AND anpn.app_sid 			= SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveApprovalNotePortletNote(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_note							IN	APPROVAL_NOTE_PORTLET_NOTE.note%TYPE,
	in_added_by_sid					IN	APPROVAL_NOTE_PORTLET_NOTE.added_by_sid%TYPE
)
AS
	v_instance_id						APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
	v_version							APPROVAL_NOTE_PORTLET_NOTE.version%TYPE;
BEGIN
	--Get the applicable instance
	GetInstanceId(in_approval_dashboard_sid, in_start_dtm, in_end_dtm, in_region_sid, v_instance_id);

	GetApprovalNotePortletNoteVers(in_approval_dashboard_sid, v_instance_id, in_region_sid, in_tab_portlet_id, v_version);

	INSERT INTO approval_note_portlet_note
		(version, tab_portlet_id, approval_dashboard_sid, dashboard_instance_id, region_sid, note, added_dtm, added_by_sid)
	VALUES
		(v_version + 1, in_tab_portlet_id, in_approval_dashboard_sid, v_instance_id, in_region_sid, in_note, SYSDATE, in_added_by_sid);
END;

PROCEDURE GetApprovalNotePortletNoteVers(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_version						OUT APPROVAL_NOTE_PORTLET_NOTE.version%TYPE
)
AS
BEGIN
	SELECT NVL(MAX(version), 0)
	  INTO out_version
	  FROM approval_note_portlet_note
	 WHERE approval_dashboard_sid 	= in_approval_dashboard_sid
	   AND dashboard_instance_id	= in_instance_id
	   AND tab_portlet_id			= in_tab_portlet_id
	   AND region_sid 				= in_region_sid
	   AND app_sid 					= SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetApprovalNotePortletNoteHist(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_instance_id						APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
BEGIN
	--Get the applicable instance
	GetInstanceId(in_approval_dashboard_sid, in_start_dtm, in_end_dtm, in_region_sid, v_instance_id);

	OPEN out_cur FOR
		SELECT note, added_dtm, added_by_sid, version, cu.full_name, cu.email
		  FROM approval_note_portlet_note anpn
		  JOIN csr_user cu ON cu.csr_user_sid = anpn.added_by_sid
		 WHERE approval_dashboard_sid 	= in_approval_dashboard_sid
		   AND dashboard_instance_id	= v_instance_id
		   AND tab_portlet_id			= in_tab_portlet_id
		   AND region_sid 				= in_region_sid
		   AND anpn.app_sid 			= SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY version DESC;
END;

PROCEDURE GetApprovalNotePortletNoteDiff(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_version_a					IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE,
	in_version_b					IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_instance_id						APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE;
BEGIN
	GetInstanceId(in_approval_dashboard_sid, in_start_dtm, in_end_dtm, in_region_sid, v_instance_id);

	OPEN out_cur FOR
		SELECT GetApprovalNoteAtVer(in_approval_dashboard_sid, in_region_sid, in_tab_portlet_id, v_instance_id, in_version_a) note_a,
			   GetApprovalNoteAtVer(in_approval_dashboard_sid, in_region_sid, in_tab_portlet_id, v_instance_id, in_version_b) note_b
			  FROM DUAL;
END;

FUNCTION GetApprovalNoteAtVer(
	in_approval_dashboard_sid		IN	APPROVAL_DASHBOARD.approval_dashboard_sid%TYPE,
	in_region_sid					IN	APPROVAL_DASHBOARD_INSTANCE.region_sid%TYPE,
	in_tab_portlet_id				IN	APPROVAL_NOTE_PORTLET_NOTE.tab_portlet_id%TYPE,
	in_instance_id					IN	APPROVAL_DASHBOARD_INSTANCE.dashboard_instance_id%TYPE,
	in_version						IN	APPROVAL_NOTE_PORTLET_NOTE.version%TYPE
) RETURN VARCHAR2
AS
	v_note								APPROVAL_NOTE_PORTLET_NOTE.note%TYPE;
BEGIN
	SELECT NVL(note, '')
	  INTO v_note
	  FROM approval_note_portlet_note
		 WHERE approval_dashboard_sid	= in_approval_dashboard_sid
		   AND dashboard_instance_id	= in_instance_id
		   AND tab_portlet_id			= in_tab_portlet_id
		   AND region_sid				= in_region_sid
		   AND version					= in_version
		   AND app_sid					= SYS_CONTEXT('SECURITY', 'APP');

	return v_note;
END;

PROCEDURE ScheduledInstanceCreator
AS
BEGIN
	FOR r IN (
		SELECT c.host, ad.approval_dashboard_sid
		  FROM approval_dashboard ad
		  JOIN customer c ON ad.app_sid = c.app_sid
		 WHERE instance_creation_schedule IS NOT NULL
	)
	LOOP
		BEGIN
			user_pkg.logonAdmin(r.host);
			approval_dashboard_pkg.checkfornewinstances(r.approval_dashboard_sid);
			security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
		EXCEPTION
			WHEN OTHERS THEN
				-- Catch here so that one failing recurrence pattern doesn't break them all.
				NULL;
		END;
	END LOOP;
END;

END;
/
