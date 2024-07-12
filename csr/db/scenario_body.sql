CREATE OR REPLACE PACKAGE BODY CSR.scenario_pkg AS

PROCEDURE GetOptions(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT show_chart, show_bau_option, bau_default
		  FROM scenario_options
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE GetScenarioList(
	in_parent_sid					IN 	security_pkg.T_SID_ID,	 
	in_order_by						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
) 
AS
	v_order_by			VARCHAR2(1000);
	v_parent_sid		security_pkg.T_SID_ID;
	v_children			security.T_SO_TABLE;
BEGIN
	v_parent_sid := COALESCE(in_parent_sid, securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios'));

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'description,start_dtm,end_dtm,period_set_id,period_interval_id');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	v_children := securableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_parent_sid, 1);
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM scenario s, TABLE(v_children) soc
	 WHERE s.scenario_sid = soc.sid_id
	   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), s.scenario_sid) = 0;

	OPEN out_cur FOR
		'SELECT * '||
		  'FROM ('||
				'SELECT rownum rn, x.* '||
				  'FROM ('||
						'SELECT s.scenario_sid, s.description, s.start_dtm, s.end_dtm, s.period_set_id, s.period_interval_id '||
						  'FROM scenario s, TABLE(:1) soc '||
						 'WHERE s.scenario_sid = soc.sid_id '||
						   'AND trash_pkg.IsInTrash(security_pkg.GetAct, s.scenario_sid) = 0 '||
						 v_order_by ||
					   ') x '||
				 'WHERE rownum <= :v_limit'||
			    ')'||
		 'WHERE rn > :v_start_row'
	USING v_children, in_start_row + in_page_size, in_start_row;
END;

PROCEDURE Subscribe(
	in_scenario_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO scenario_email_sub
		(scenario_sid, csr_user_sid)
	VALUES
		(in_scenario_sid, security_pkg.getSid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
END;

PROCEDURE Unsubscribe(
	in_scenario_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM scenario_email_sub
	 WHERE csr_user_sid = security_pkg.getSid
	   AND scenario_sid = in_scenario_sid;
END;

PROCEDURE CheckScenarioReadAccess(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the scenario with sid '||in_scenario_sid);
	END IF;
END;

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_scn_ind_cur					OUT	SYS_REFCURSOR,
	out_scn_region_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_scn_cur FOR
		SELECT so.parent_sid_id parent_sid, s.scenario_sid, s.description, s.start_dtm, s.end_dtm,
			   s.period_set_id, s.period_interval_id, s.equality_epsilon, s.auto_update_run_sid,
			   s.recalc_trigger_type, s.data_source, s.data_source_sp, s.data_source_sp_args,
			   s.data_source_run_sid, srvf.file_path data_source_run_path, srvf.sha1 data_source_run_sha1,
			   s.include_all_inds, s.dont_run_aggregate_indicators
		  FROM scenario s
		  JOIN security.securable_object so ON s.scenario_sid = so.sid_id
		  LEFT JOIN scenario_run sr ON s.app_sid = sr.app_sid AND sr.scenario_run_sid = s.data_source_run_sid
		  LEFT JOIN scenario_run_version_file srvf ON sr.scenario_run_sid = srvf.scenario_run_sid AND sr.version = srvf.version
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND s.scenario_sid = in_scenario_sid;

	OPEN out_scn_ind_cur FOR
		SELECT si.scenario_sid, si.ind_sid, i.description
		  FROM scenario_ind si, v$ind i
		 WHERE si.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND si.scenario_sid = in_scenario_sid
		   AND si.app_sid = i.app_sid AND si.ind_sid = i.ind_sid;

	OPEN out_scn_region_cur FOR
		SELECT sr.scenario_sid, sr.region_sid, r.description
		  FROM scenario_region sr, v$region r
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.app_sid = r.app_sid AND sr.region_sid = r.region_sid;
END;

PROCEDURE GetScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid, s.scenario_sid, s.description, s.file_based
		  FROM scenario_run sr
		  JOIN scenario s ON s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), s.scenario_sid) = 0;
END;

PROCEDURE GetMergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid, s.scenario_sid, s.description, s.file_based
		  FROM scenario_run sr
		  JOIN scenario s ON s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
		  JOIN customer c on c.app_sid = sr.app_sid AND c.merged_scenario_run_sid = sr.scenario_run_sid
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetUnmergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid, s.scenario_sid, s.description, s.file_based
		  FROM scenario_run sr
		  JOIN scenario s ON s.app_sid = sr.app_sid AND s.scenario_sid = sr.scenario_sid
		  JOIN customer c on c.app_sid = sr.app_sid AND c.unmerged_scenario_run_sid = sr.scenario_run_sid
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetScenarioExtrapolationRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_rule_ind_cur				OUT	SYS_REFCURSOR,
	out_rule_region_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_cur FOR
		SELECT sr.rule_id, sr.description, sr.rule_type, sr.amount, 
			   sr.measure_conversion_id, mc.description measure_conversion_description,
			   sr.start_dtm, sr.end_dtm
		  FROM scenario_rule sr, measure_conversion mc
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.app_sid = mc.app_sid(+) AND sr.measure_conversion_id = mc.measure_conversion_id(+)
		   AND sr.rule_type IN (RT_ABSOLUTE_VALUE, RT_ABSOLUTE_CHANGE, RT_PERCENTAGE_CHANGE);

	OPEN out_rule_ind_cur FOR
		SELECT sri.scenario_sid, sri.rule_id, sri.ind_sid, i.description
		  FROM scenario_rule sr, scenario_rule_ind sri, v$ind i
		 WHERE sri.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sri.scenario_sid = in_scenario_sid
		   AND sri.app_sid = i.app_sid AND sri.ind_sid = i.ind_sid
		   AND sr.app_sid = sri.app_sid AND sr.rule_id = sri.rule_id
		   AND sr.rule_type IN (RT_ABSOLUTE_VALUE, RT_ABSOLUTE_CHANGE, RT_PERCENTAGE_CHANGE)
		 ORDER BY sri.rule_id;
		 
	OPEN out_rule_region_cur FOR
		SELECT srr.scenario_sid, srr.rule_id, srr.region_sid, r.description
		  FROM scenario_rule sr, scenario_rule_region srr, v$region r
		 WHERE srr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND srr.scenario_sid = in_scenario_sid
		   AND srr.app_sid = r.app_sid AND srr.region_sid = r.region_sid
		   AND sr.app_sid = srr.app_sid AND sr.rule_id = srr.rule_id
		   AND sr.rule_type IN (RT_ABSOLUTE_VALUE, RT_ABSOLUTE_CHANGE, RT_PERCENTAGE_CHANGE)
		 ORDER BY srr.rule_id;
END;

PROCEDURE GetScenarioLikeForLikeRule(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_cur FOR
		SELECT applies_to_region_type, contiguous_data_check_type
		  FROM scenario_like_for_like_rule
		 WHERE scenario_sid = in_scenario_sid
		   AND rule_id = in_rule_id;
END;

PROCEDURE GetScenarioLikeForLikeRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_exclusion_set_cur			OUT	SYS_REFCURSOR,
	out_contiguous_set_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_cur FOR
		SELECT sr.rule_id, sr.description, sr.rule_type, sr.start_dtm, sr.end_dtm,
			   NVL(slflr.applies_to_region_type, 0) applies_to_region_type,
			   NVL(slflr.contiguous_data_check_type, 0) contiguous_data_check_type
		  FROM scenario_rule sr
		  LEFT JOIN scenario_like_for_like_rule slflr ON sr.app_sid = slflr.app_sid 
		   AND sr.scenario_sid = slflr.scenario_sid AND slflr.rule_id = sr.rule_id
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.rule_type IN (RT_LIKE_FOR_LIKE);

	OPEN out_exclusion_set_cur FOR
		SELECT sri.scenario_sid, sri.rule_id, sri.ind_sid, i.description
		  FROM scenario_rule sr, scenario_rule_ind sri, v$ind i
		 WHERE sri.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sri.scenario_sid = in_scenario_sid
		   AND sri.app_sid = i.app_sid AND sri.ind_sid = i.ind_sid
		   AND sr.app_sid = sri.app_sid AND sr.rule_id = sri.rule_id
		   AND sr.rule_type IN (RT_LIKE_FOR_LIKE)
		 ORDER BY sri.rule_id;

	OPEN out_contiguous_set_cur FOR
		SELECT srli.scenario_sid, srli.rule_id, srli.ind_sid
		  FROM scenario_rule sr, scenario_rule_like_contig_ind srli
		 WHERE srli.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND srli.scenario_sid = in_scenario_sid
		   AND sr.app_sid = srli.app_sid AND sr.rule_id = srli.rule_id
		   AND sr.rule_type IN (RT_LIKE_FOR_LIKE)
		 ORDER BY srli.rule_id;
END;

PROCEDURE GetScenarioIndFilterRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_exclusion_set_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_cur FOR
		SELECT sr.rule_id, sr.description, sr.rule_type
		  FROM scenario_rule sr
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.rule_type IN (RT_INITIATIVES_IND_FILTER);

	-- Select a list of indicators whose values will be removed from the data set
	-- That is in this case any ind template indicator instance that is associated
	-- with an initiative not in one of the desired statuses
	OPEN out_exclusion_set_cur FOR
		SELECT sr.rule_id, i.ind_sid
		  FROM actions.task_ind_template_instance i, scenario_rule sr
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND sr.app_sid = i.app_sid
		   AND sr.scenario_sid = in_scenario_sid
		   AND sr.rule_type IN (RT_INITIATIVES_IND_FILTER)
		MINUS
		SELECT sr.rule_id, i.ind_sid
		  FROM actions.task t, actions.task_ind_template_instance i, actions.scenario_filter_status s,
			   scenario_rule sr
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = i.app_sid AND t.task_sid = i.task_sid
		   AND t.app_sid = s.app_sid AND t.task_status_id = s.task_status_id
		   AND s.scenario_sid = in_scenario_sid
		   AND s.app_sid = sr.app_sid AND s.rule_id = sr.rule_id
		   AND sr.rule_type IN (RT_INITIATIVES_IND_FILTER);
END;

PROCEDURE GetActiveForWholePeriodRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_cur FOR
		SELECT sr.rule_id, sr.description, sr.rule_type, sr.start_dtm, sr.end_dtm
		  FROM scenario_rule sr
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.rule_type IN (RT_ACTIVE_FOR_WHOLE_PERIOD);
END;

PROCEDURE GetForecastingRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_cur FOR
		SELECT sr.rule_id, fr.ind_sid, fr.region_sid, fr.start_dtm, fr.end_dtm,
			   fr.rule_type, fr.rule_val
		  FROM forecasting_rule fr, scenario_rule sr
		 WHERE sr.scenario_sid = in_scenario_sid
		   AND sr.scenario_sid = fr.scenario_sid
		   AND fr.rule_id = sr.rule_id
		   AND sr.rule_type IN (RT_FORECASTING);
END;

PROCEDURE GetFixCalcResultsRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_ind_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckScenarioReadAccess(in_scenario_sid);

	OPEN out_rule_ind_cur FOR
		SELECT sri.rule_id, sri.ind_sid
		  FROM scenario_rule_ind sri, scenario_rule sr
		 WHERE sr.scenario_sid = in_scenario_sid
		   AND sri.app_sid = sr.app_sid
		   AND sri.scenario_sid = sr.scenario_sid
		   AND sri.rule_id = sr.rule_id
		   AND sr.rule_type IN (RT_FIXCALCRESULTS);
END;

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_scn_ind_cur					OUT	SYS_REFCURSOR,
	out_scn_region_cur				OUT	SYS_REFCURSOR,
	out_scn_rule_cur				OUT	SYS_REFCURSOR,
	out_scn_rule_ind_cur			OUT	SYS_REFCURSOR,
	out_scn_rule_region_cur			OUT	SYS_REFCURSOR,
	out_scn_like_rule_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	-- This GetScenario overload checks security
	GetScenario(in_scenario_sid, out_scn_cur, out_scn_ind_cur, out_scn_region_cur);

	OPEN out_scn_rule_cur FOR
		SELECT sr.rule_id, sr.description, sr.rule_type, sr.amount, 
			   sr.measure_conversion_id, mc.description measure_conversion_description,
			   sr.start_dtm, sr.end_dtm
		  FROM scenario_rule sr, measure_conversion mc
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sr.scenario_sid = in_scenario_sid
		   AND sr.app_sid = mc.app_sid(+) AND sr.measure_conversion_id = mc.measure_conversion_id(+);

	OPEN out_scn_rule_ind_cur FOR
		SELECT sri.scenario_sid, sri.rule_id, sri.ind_sid, i.description
		  FROM scenario_rule_ind sri, v$ind i
		 WHERE sri.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sri.scenario_sid = in_scenario_sid
		   AND sri.app_sid = i.app_sid AND sri.ind_sid = i.ind_sid
		 ORDER BY sri.rule_id;
		 
	OPEN out_scn_rule_region_cur FOR
		SELECT srr.scenario_sid, srr.rule_id, srr.region_sid, r.description
		  FROM scenario_rule_region srr, v$region r
		 WHERE srr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND srr.scenario_sid = in_scenario_sid
		   AND srr.app_sid = r.app_sid AND srr.region_sid = r.region_sid
		 ORDER BY srr.rule_id;
		 
	OPEN out_scn_like_rule_cur FOR
		SELECT srli.rule_id, srli.ind_sid
		  FROM scenario_rule sr, scenario_rule_like_contig_ind srli
		 WHERE sr.scenario_sid = in_scenario_sid 
		   AND sr.app_sid = srli.app_sid AND sr.scenario_sid = srli.scenario_sid 
		   AND sr.rule_id = srli.rule_id;	
END;

PROCEDURE SaveScenario(
	in_class_id						IN	security_pkg.T_CLASS_ID DEFAULT NULL,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario.description%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_regions						IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	scenario.start_dtm%TYPE,
	in_end_dtm						IN	scenario.end_dtm%TYPE,
	in_period_set_id				IN	scenario.period_set_id%TYPE DEFAULT 1,
	in_period_interval_id			IN	scenario.period_interval_id%TYPE DEFAULT 1,
	in_include_all_inds				IN	scenario.include_all_inds%TYPE DEFAULT 0,
	in_file_based					IN	scenario.file_based%TYPE DEFAULT 1,
	out_scenario_sid				OUT	scenario.scenario_sid%TYPE
)
AS
	v_regions				security.T_SID_TABLE;
	v_indicators			security.T_SID_TABLE;
BEGIN
	IF in_scenario_sid IS NULL THEN
		securableObject_pkg.CreateSO(security_pkg.GetACT(), in_parent_sid, 
			NVL(in_class_id, class_pkg.GetClassId('CSRScenario')), null, out_scenario_sid);

		INSERT INTO scenario 
			(scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id,
			 include_all_inds, file_based)
		VALUES
			(out_scenario_sid, in_description, in_start_dtm, in_end_dtm, in_period_set_id,
			 in_period_interval_id, in_include_all_inds, in_file_based);
	ELSE
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the scenario model with sid '||in_scenario_sid);
		END IF;

		UPDATE scenario
		   SET description = in_description,
		   	   start_dtm = in_start_dtm,
		   	   end_dtm = in_end_dtm,
		   	   period_set_id = in_period_set_id,
		   	   period_interval_id = in_period_interval_id,
		   	   include_all_inds = in_include_all_inds,
			   file_based = in_file_based
		 WHERE scenario_sid = in_scenario_sid;

		DELETE FROM scenario_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
		 
		DELETE FROM scenario_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
		 
		 out_scenario_sid := in_scenario_sid;
	END IF;
	
	v_regions := security_pkg.SidArrayToTable(in_regions);
	INSERT INTO scenario_region (app_sid, scenario_sid, region_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), out_scenario_sid, column_value
		   FROM TABLE(v_regions);
	
	v_indicators := security_pkg.SidArrayToTable(in_indicators);
	INSERT INTO scenario_ind (app_sid, scenario_sid, ind_sid)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), out_scenario_sid, column_value
		   FROM TABLE(v_indicators);
END;

PROCEDURE SaveRule(
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
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving a rule for the scenario model with sid '||in_scenario_sid);
	END IF;
	
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

PROCEDURE DeleteRule(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE
)
AS
	v_dummy					scenario.scenario_sid%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting a rule for the scenario model with sid '||in_scenario_sid);
	END IF;

	-- Lock the scenario row so we get a consistent rule id
	SELECT scenario_sid
	  INTO v_dummy
	  FROM scenario
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid
	  	   FOR UPDATE;

	DELETE FROM actions.scenario_filter_status
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_sid = in_scenario_sid
	   AND rule_id = in_rule_id;

	DELETE FROM actions.scenario_filter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_sid = in_scenario_sid
	   AND rule_id = in_rule_id;

	DELETE FROM scenario_rule_ind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
	 
	DELETE FROM scenario_rule_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
	 
	DELETE FROM scenario_like_for_like_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
	 
	DELETE FROM scenario_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid AND rule_id = in_rule_id;
END;

PROCEDURE DeleteAllRules(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE
)
AS
	v_dummy					scenario.scenario_sid%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving a rule for the scenario model with sid '||in_scenario_sid);
	END IF;

	-- Lock the scenario row so we get a consistent rule id
	SELECT scenario_sid
	  INTO v_dummy
	  FROM scenario
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid
	  	   FOR UPDATE;

	DELETE FROM forecasting_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;

	DELETE FROM scenario_like_for_like_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;

	DELETE FROM scenario_rule_ind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
	 
	DELETE FROM scenario_rule_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
	 
	DELETE FROM scenario_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scenario_sid = in_scenario_sid;
END;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Should be called via the Create method
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	v_app_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	DELETE FROM actions.scenario_filter_status
	 WHERE app_sid = v_app_sid
	   AND scenario_sid = in_sid_id;

	DELETE FROM actions.scenario_filter
	 WHERE app_sid = v_app_sid
	   AND scenario_sid = in_sid_id;

	UPDATE scenario 
	   SET auto_update_run_sid = NULL
	 WHERE scenario_sid = in_sid_id;

	-- kill all scenario runs
	-- Remove the runs from dataviews
	DELETE FROM dataview_scenario_run 
	 WHERE scenario_run_sid IN (
		SELECT scenario_run_sid
		  FROM scenario_run
		 WHERE scenario_sid = in_sid_id
	);
	
	FOR r IN (SELECT scenario_run_sid
				FROM scenario_run
			   WHERE app_sid = v_app_sid
			     AND scenario_sid = in_sid_id) LOOP			     	
		securableobject_pkg.DeleteSO(in_act_id, r.scenario_run_sid);
	END LOOP;
	
	DELETE FROM scenario_rule_ind
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_rule_region
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_ind
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_region
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_rule_like_contig_ind
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_rule
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_email_sub
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario_alert
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	DELETE FROM scenario
	 WHERE app_sid = v_app_sid AND scenario_sid = in_sid_id;

	-- write to audit log
--	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
	--	'Deleted "{0}"', INTERNAL_GetIndPathString(in_sid_id));
		
	-- we need to set our audit log object_sid to null due to FK constraint
	--???
--	update audit_log set object_sid = null where object_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN	security_pkg.T_SID_ID
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	NULL;
	--csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
	--	'Moved under "{0}"', 
	--	INTERNAL_GetIndPathString(in_new_parent_sid_id));
END;

-- TODO: warn if part of formula / has user mount points pointing to it etc?
PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	NULL;
END;

-- Private -- fills temp_ind_tree with the portion of the indicator tree that's allowed
PROCEDURE GetFilteredTree(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	out_roots						OUT	security.T_SID_TABLE,
	out_ind_tree_table				OUT csr.T_IND_TREE_TABLE
)
AS
	v_indicators					security.T_SID_TABLE;
BEGIN
	-- Check permissions on the root nodes
	FOR i IN in_parent_sids.FIRST .. in_parent_sids.LAST
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sids(i));
		END IF;
	END LOOP;
	out_roots := security_pkg.SidArrayToTable(in_parent_sids);

	-- Put all given inds, any inds they depend on (if they are calcs),
	-- and the path to them from the root into the temp tree table
	-- We can then do the normal filtering on top of this
	-- (This could be combined with the query, but it's probably going to drive Oracle nuts)
	
	v_indicators := security_pkg.SidArrayToTable(in_indicators);

	SELECT T_IND_TREE_ROW(i.app_sid, i.ind_sid, i.parent_sid, id.description, i.ind_type, i.measure_sid, m.description, NVL(i.format_mask, m.format_mask), i.active)
	BULK COLLECT INTO out_ind_tree_table
		  FROM (SELECT DISTINCT app_sid, ind_sid, parent_sid, ind_type, measure_sid, format_mask, active
				  FROM ind i
				  	   START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ind_sid IN (
							SELECT column_value
							  FROM TABLE(v_indicators)
							 UNION
							SELECT ind_sid
							  FROM v$calc_dependency 
								   START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND calc_ind_sid IN (SELECT column_value FROM TABLE(v_indicators))
								   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = calc_ind_sid)
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = ind_sid) i,
			   measure m, ind_description id
		 WHERE i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		   AND i.app_sid = id.app_sid AND i.ind_sid = id.ind_sid 
		   AND id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
END;

PROCEDURE GetRuleIndTreeWithDepth(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	-- Get the filtered down tree.  Due to some bizarre PL/SQL restriction, this must be done in two parts.
	OPEN out_cur FOR
		SELECT ind_sid sid_id, description, ind_type, measure_sid, measure_description, LEVEL lvl, active,
			   CONNECT_BY_ISLEAF is_leaf, 'CSRIndicator' class_name, format_mask
		  FROM TABLE(v_ind_tree_table)
		 WHERE level <= in_fetch_depth
			   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 		      (in_include_root = 1 AND ind_sid in (SELECT column_value FROM TABLE(v_roots)))
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
			   ORDER SIBLINGS BY description;
END;

PROCEDURE GetRuleIndTreeWithSelect(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	OPEN out_cur FOR
		SELECT sid_id, description, 'CSRIndicator' class_name, ind_type, measure_sid, measure_description, lvl, is_leaf, active, format_mask
		  FROM (SELECT ind_sid sid_id, LEVEL lvl, description, measure_sid, measure_description,
		  			   ind_type, CONNECT_BY_ISLEAF is_leaf, parent_sid, active, format_mask
		  	  	  FROM TABLE(v_ind_tree_table) 
			    	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(v_roots))) OR 
			 			          (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(v_roots)))
		 			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid 
		 			   ORDER SIBLINGS BY description)
		 WHERE lvl <= in_fetch_depth 
		 	OR sid_id IN (
				SELECT ind_sid
		 		  FROM TABLE(v_ind_tree_table)
		 			   START WITH ind_sid = in_select_sid
		 			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = ind_sid
		 	)
		 	OR parent_sid IN (
				SELECT ind_sid
		 		  FROM TABLE(v_ind_tree_table) 
		 			   START WITH ind_sid = in_select_sid
		 			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = ind_sid
		 	);
END;

PROCEDURE GetRuleIndTreeTextFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	OPEN out_cur FOR
		SELECT i.sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, i.active,
			   i.format_mask, i.measure_description
		  FROM (SELECT ind_sid sid_id, description, ind_type, measure_sid, active, 
		  			   CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name,
		  			   measure_description, format_mask
			  	 FROM TABLE(v_ind_tree_table)
			   		  START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 			         (in_include_root = 1 AND ind_sid IN (SELECT column_value FROM TABLE(v_roots)))
					  CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
					  ORDER SIBLINGS BY description) i, 
			   (SELECT DISTINCT ind_sid sid_id
			     FROM TABLE(v_ind_tree_table)
			 		  START WITH ind_sid IN ( 
			 			SELECT ind_sid 
			 		      FROM TABLE(v_ind_tree_table)
			 		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 		   	   AND (LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'))
			 		  CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = ind_sid) ti 
		 WHERE i.sid_id = ti.sid_id 
		 ORDER BY i.rn;
END;

PROCEDURE GetRuleIndTreeTagFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
	v_search_tag_table				csr.T_SEARCH_TAG_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	SELECT t_search_tag_row(set_id, tag_id)
	  BULK COLLECT INTO v_search_tag_table
	  FROM search_tag;

	OPEN out_cur FOR
		SELECT i.sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, i.active,
			   i.measure_description, i.format_mask
		  FROM (SELECT ind_sid sid_id, description, ind_type, measure_sid, active, 
		  			   CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name,
		  			   measure_description, format_mask
			  	  FROM TABLE(v_ind_tree_table)
			    	   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
			 	 		          (in_include_root = 1 AND ind_sid IN (SELECT column_value FROM TABLE(v_roots)))
					   CONNECT BY PRIOR ind_sid = parent_sid
					   ORDER SIBLINGS BY description) i, 
			   (SELECT DISTINCT ind_sid sid_id 
			      FROM TABLE(v_ind_tree_table)
			 	  	   START WITH ind_sid IN (SELECT ind_sid
	                    	  					FROM (SELECT ind_sid, set_id
	                      	  							FROM TABLE(v_search_tag_table) st, ind_tag it
	                     	 						   WHERE st.tag_id = it.tag_id
	                      							   GROUP BY ind_sid, set_id)
	                  						   GROUP BY ind_sid
	                  						  HAVING COUNT(*) = in_tag_group_count)
			 				  AND ind_sid IN (SELECT ind_sid 
			 		  							FROM TABLE(v_ind_tree_table)
			 		 						   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   							AND (LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'))
			 		   CONNECT BY PRIOR parent_sid = ind_sid) ti 
		 WHERE i.sid_id = ti.sid_id 
		 ORDER BY i.rn;
END;

PROCEDURE GetRuleIndListTextFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	OPEN out_cur FOR
		SELECT *
		  -- ************* N.B. that's a literal 0x1 character in there, not a space **************
		  FROM (SELECT ind_sid sid_id, 'CSRIndicator' class_name, description, ind_type, measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
		  			   SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),'') path, active, measure_description, format_mask
				  FROM TABLE(v_ind_tree_table)
				 WHERE (in_search_phrase IS NULL OR LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%')
					   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
					 			  (in_include_root = 1 AND ind_sid IN (SELECT column_value FROM TABLE(v_roots)))
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
				 ORDER SIBLINGS BY description)
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetRuleIndListTagFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_SID_TABLE;
	v_ind_tree_table				csr.T_IND_TREE_TABLE;
	v_search_tag_table				csr.T_SEARCH_TAG_TABLE;
BEGIN
	GetFilteredTree(in_indicators, in_parent_sids, v_roots, v_ind_tree_table);

	SELECT t_search_tag_row(set_id, tag_id)
	  BULK COLLECT INTO v_search_tag_table
	  FROM search_tag;

	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT *
			  FROM (SELECT ind_sid sid_id, 'CSRIndicator' class_name, description, ind_type, measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
			  			   SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),'') path, active,
			  			   rownum rn, measure_description, format_mask
					  FROM TABLE(v_ind_tree_table) i
					 WHERE (in_search_phrase IS NULL OR LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%')
						   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value FROM TABLE(v_roots))) OR 
						 			  (in_include_root = 1 AND ind_sid IN (SELECT column_value FROM TABLE(v_roots)))
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
					 ORDER SIBLINGS BY description)
			 WHERE sid_id IN (
	               SELECT ind_sid
	                 FROM (SELECT ind_sid, set_id
	                   	     FROM TABLE(v_search_tag_table) st, ind_tag it
	                 	    WHERE st.tag_id = it.tag_id
	                     GROUP BY ind_sid, set_id)
	                GROUP BY ind_sid
	               HAVING count(*) = in_tag_group_count)
	      ORDER BY rn)
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE ResolveNormalInds(
	in_ind_list						IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_inds							security.T_SID_TABLE;
BEGIN
	t_inds := security_Pkg.SidArrayToTable(in_ind_list);
	
	FOR r IN (
		SELECT column_value
		  FROM TABLE(t_inds)
	) LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||r.column_value);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT c.ind_sid
		  FROM v$calc_dependency c, ind i
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.ind_sid = c.ind_sid
		   AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
			   START WITH c.calc_ind_sid IN (
			   		SELECT column_value
			   		  FROM TABLE(t_inds)
			   )
			   CONNECT BY PRIOR c.ind_sid = c.calc_ind_sid
		UNION 
		SELECT ind_sid
		  FROM ind
		 WHERE ind_type = csr_data_pkg.IND_TYPE_NORMAL
		   AND ind_sid IN (
		 	SELECT column_value
			  FROM TABLE(t_inds)
		   );
END;

PROCEDURE GetAllRegions (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM region r
		 WHERE r.region_type <> csr_data_pkg.REGION_TYPE_ROOT;
END;

PROCEDURE GetAllUntrashedRegions (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM region r
		 WHERE r.region_type <> csr_data_pkg.REGION_TYPE_ROOT
		   AND csr.trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY','ACT'), r.region_sid) = 0;
END;

PROCEDURE GetAllUntrashedInds (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid
		  FROM ind i
		 WHERE i.parent_sid <> SYS_CONTEXT('SECURITY', 'APP')
		   AND csr.trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY','ACT'), i.ind_sid) = 0;
END;

PROCEDURE GetFolderTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_fetch_depth   				IN	NUMBER,
	out_cur   						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf
		  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_parent_sid, 
		  				security_pkg.PERMISSION_READ, in_fetch_depth, null, 1) )
		 WHERE class_id NOT IN (class_pkg.GetClassId('CSRScenario'), security.class_pkg.GetClassId('CSRForecasting'), class_pkg.GetClassId('CSRScenarioRun'));
END;

PROCEDURE GetFolderTreeWithSelect(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf
		  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_parent_sid, 
		  				security_pkg.PERMISSION_READ, null, null, 1 )
		 )
		 WHERE class_id NOT IN (class_pkg.GetClassId('CSRScenario'), security.class_pkg.GetClassId('CSRForecasting'), class_pkg.GetClassId('CSRScenarioRun'))
		   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), sid_id) = 0
		   AND (
		   	so_level <= in_fetch_depth 
		 	OR sid_id IN (
				SELECT sid_id
		 		  FROM security.securable_object
		 			   START WITH sid_id = in_select_sid
		 			   CONNECT BY PRIOR parent_sid_id = sid_id
		 	)
		 	OR parent_sid_id IN (
				SELECT sid_id
		 		  FROM security.securable_object
		 			   START WITH sid_id = in_select_sid
		 			   CONNECT BY PRIOR parent_sid_id = sid_id
		 	));
END;
	
PROCEDURE GetFolderTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- XXX: this reads the whole tree, should we add an explicit tree text filter too?
	OPEN out_cur FOR
		SELECT t.sid_id, t.parent_sid_id, t.name, t.so_level, t.is_leaf
		  FROM 
		(
		  	SELECT rownum rn, x.*
		  	  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_parent_sid, 
				  		   security_pkg.PERMISSION_READ, null, null, 1) ) x
			 WHERE class_id NOT IN (class_pkg.GetClassId('CSRScenario'), security.class_pkg.GetClassId('CSRForecasting'), class_pkg.GetClassId('CSRScenarioRun'))
			   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), sid_id) = 0
		) t, (
			SELECT DISTINCT sid_id
			  FROM security.securable_object
			 START WITH sid_id IN (
				   SELECT sid_id
		      		 FROM security.securable_object
		      	    WHERE LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%'
			        START WITH sid_id = in_parent_sid
			  CONNECT BY PRIOR sid_id = parent_sid_id)
		    CONNECT BY PRIOR parent_sid_id = sid_id
		) ti, (
			 SELECT sid_id, 1 is_match
      		  FROM security.securable_object
      	     WHERE LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%'
	         START WITH sid_id = in_parent_sid
		   CONNECT BY PRIOR sid_id = parent_sid_id
		) mt 
		WHERE t.sid_id = ti.sid_id 
		  AND t.sid_id = mt.sid_id(+) 
     ORDER BY t.rn;
END;

PROCEDURE GetFolderList(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_root_sid						IN	security_pkg.T_SID_ID,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf, SUBSTR(path, 2) path, 1 is_match
		  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_root_sid, 
						security_pkg.PERMISSION_READ, NULL, in_limit + 1, 1) )
	     WHERE class_id NOT IN (class_pkg.GetClassId('CSRScenario'), security.class_pkg.GetClassId('CSRForecasting'), class_pkg.GetClassId('CSRScenarioRun'))
		   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), sid_id) = 0
	       AND sid_id <> in_root_sid AND rownum <= in_limit;
END;

PROCEDURE GetFolderListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_root_sid						IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- XXX: this reads the whole tree, should we add an explicit list filter?
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_leaf, SUBSTR(path, 2) path, 1 is_match
		  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_root_sid, 
						security_pkg.PERMISSION_READ, null, null, 1) )
	     WHERE class_id NOT IN (class_pkg.GetClassId('CSRScenario'), security.class_pkg.GetClassId('CSRForecasting'), class_pkg.GetClassId('CSRScenarioRun'))
		   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), sid_id) = 0
		   AND sid_id <> in_root_sid AND LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%' AND rownum <= in_limit;
END;

PROCEDURE CreateFolder(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	out_sid_id						OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	Securableobject_Pkg.CreateSO(security_pkg.GetACT(), in_parent_sid, 
		security_pkg.SO_CONTAINER, in_name, out_sid_id);
END;

PROCEDURE GetFolderScenarios(
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
) 
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'List contents access denied on the folder with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT s.parent_sid, s.scenario_sid, s.description, s.start_dtm, 
				   s.end_dtm, s.period_set_id, s.period_interval_id, 
				   MAX(sr.last_success_dtm) last_success_dtm
		  FROM (
			SELECT soc.parent_sid_id parent_sid, s.scenario_sid, s.description, s.start_dtm, 
				   s.end_dtm, s.period_set_id, s.period_interval_id
			  FROM scenario s, TABLE(securableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_READ)) soc
			 WHERE s.scenario_sid = soc.sid_id
			   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), sid_id) = 0
			 ) s
		  LEFT JOIN scenario_run sr ON sr.scenario_sid = s.scenario_sid
		 GROUP BY s.parent_sid, s.scenario_sid, s.description, s.start_dtm, 
				  s.end_dtm, s.period_set_id, s.period_interval_id
		 ORDER BY s.description;
END;

PROCEDURE GetFolderScenarioRuns(
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
) 
AS
	v_scenarios_sid					security_pkg.T_SID_ID;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- temporary interface hack to include merged/unmerged data
	BEGIN
		v_scenarios_sid := securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	-- TODO: 13p fix needed
	OPEN out_cur FOR
		SELECT soc.parent_sid_id parent_sid, sr.scenario_run_sid scenario_sid, sr.description run_description, s.description, run_dtm,
			   to_date('2009-01-01','yyyy-mm-dd') start_dtm, to_date('2010-01-01','yyyy-mm-dd') end_dtm,
			   1 period_set_id, 1 period_interval_id, last_success_dtm, 
			   s.scenario_sid raw_scenario_sid, sr.scenario_run_sid raw_scenario_run_sid
		  FROM TABLE(securableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_READ)) soc, scenario_run sr
		  LEFT JOIN csr.scenario s ON sr.scenario_sid = s.scenario_sid
		 WHERE sr.scenario_run_sid = soc.sid_id
		   AND trash_pkg.IsInTrash(SYS_CONTEXT('SECURITY', 'ACT'), s.scenario_sid) = 0
		 UNION ALL
		SELECT v_scenarios_sid parent_sid, NVL(merged_scenario_run_sid, 0) scenario_sid, NVL(sr.description, 'Merged scenario run') run_description, NVL(s.description,'Merged data'), SYSDATE run_dtm,
			   to_date('2009-01-01','yyyy-mm-dd') start_dtm, to_date('2010-01-01','yyyy-mm-dd') end_dtm,
			   1 period_set_id, 1 period_interval_id, sr.last_success_dtm last_success_dtm,
			   NVL(s.scenario_sid, 0) raw_scenario_sid, 
			   NVL(merged_scenario_run_sid, 0) raw_scenario_run_sid
		  FROM customer c
		  LEFT JOIN scenario_run sr on c.merged_scenario_run_sid = sr.scenario_run_sid
		  LEFT JOIN csr.scenario s ON sr.scenario_sid = s.scenario_sid
		 WHERE in_parent_sid = v_scenarios_sid
		 UNION ALL
		SELECT v_scenarios_sid parent_sid, NVL(unmerged_scenario_run_sid, 1) scenario_sid, NVL(sr.description, 'Unmerged scenario run') run_description, NVL(s.description,'Unmerged data'), SYSDATE run_dtm,
			   to_date('2009-01-01','yyyy-mm-dd') start_dtm, to_date('2010-01-01','yyyy-mm-dd') end_dtm,
			   1 period_set_id, 1 period_interval_id, sr.last_success_dtm last_success_dtm,
			   NVL(s.scenario_sid, 1) raw_scenario_sid, 
			   NVL(unmerged_scenario_run_sid, 0) raw_scenario_run_sid
		  FROM customer c
		  LEFT JOIN scenario_run sr on c.unmerged_scenario_run_sid = sr.scenario_run_sid
		  LEFT JOIN csr.scenario s ON sr.scenario_sid = s.scenario_sid
		 WHERE in_parent_sid = v_scenarios_sid;
END;

PROCEDURE GetPendingScenarioAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.app_sid, s.scenario_sid, a.csr_user_sid to_user_sid, s.description,
			   sr.description scenario_run_name, a.calc_job_completion_dtm completion_dtm, 
			   s.start_dtm, s.end_dtm, a.calc_job_id 
		  FROM scenario_alert a
		  JOIN scenario s ON a.scenario_sid = s.scenario_sid
		  JOIN scenario_run sr ON s.auto_update_run_sid = sr.scenario_run_sid
		 ORDER BY a.app_sid, a.csr_user_sid, a.calc_job_completion_dtm DESC;
END;

PROCEDURE MarkScenarioAlertSent(
	in_app_sid						IN	scenario_alert.app_sid%TYPE,
	in_calc_job_id					IN	scenario_alert.calc_job_id%TYPE,
	in_user_sid						IN	scenario_alert.csr_user_sid%TYPE
)
AS
BEGIN
	DELETE FROM scenario_alert
	 WHERE app_sid = in_app_sid
	   AND calc_job_id = in_calc_job_id
	   AND csr_user_sid	= in_user_sid;
END;

END scenario_pkg;
/
