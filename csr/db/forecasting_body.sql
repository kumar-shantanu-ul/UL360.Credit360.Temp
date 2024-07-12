CREATE OR REPLACE PACKAGE BODY csr.forecasting_pkg AS

/* 
** SECURABLE OBJECT CALLBACKS
*/
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
	IF in_new_name IS NOT NULL THEN
		UPDATE scenario
		   SET description = in_new_name
		 WHERE scenario_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	DELETE FROM forecasting_rule
	 WHERE scenario_sid = in_sid_id
	   AND app_sid = v_app_sid;

	scenario_pkg.DeleteObject(in_act_id, in_sid_id);

	DELETE FROM scenario_rule
	 WHERE scenario_sid = in_sid_id
	   AND app_sid = v_app_sid;
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

PROCEDURE AssertWritePermission(
	in_scenario_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on forecast with sid '||in_scenario_sid);
	END IF;

END;

FUNCTION CanEditForecast_sql(
	in_scenario_sid					IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER
AS
BEGIN

	IF security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
		RETURN 1;
	END IF;

	RETURN 0;

END;

FUNCTION CanDeleteForecast_sql(
	in_scenario_sid					IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER
AS
BEGIN

	IF security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_scenario_sid, security_pkg.PERMISSION_DELETE) THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

PROCEDURE AddRegisteredUsersRead(
	in_object_sid					IN	security_pkg.T_SID_ID
)
AS
	v_reg_users_sid					security_pkg.T_SID_ID;
	v_dacl_id						security_pkg.T_ACL_ID;
	v_acl_count						BINARY_INTEGER;
BEGIN
	v_dacl_id := acl_pkg.GetDACLIDForSID(in_object_sid);
	
	v_reg_users_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'APP'),
		SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');

	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl
	 WHERE acl_id = v_dacl_id
	   AND ace_type = security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security_pkg.PERMISSION_STANDARD_READ;

	IF v_acl_count = 0 THEN
		acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'APP'), v_dacl_id,
			security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security_pkg.PERMISSION_STANDARD_READ);
	END IF;
END;
	
PROCEDURE CreateForecast(
	in_description					IN	scenario.description%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_include_all_inds				IN	scenario.include_all_inds%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	scenario.start_dtm%TYPE,
	in_end_dtm						IN	scenario.end_dtm%TYPE,
	in_period_set_id				IN	scenario.period_set_id%TYPE,
	in_period_interval_id			IN	scenario.period_interval_id%TYPE,
	in_parent_folder_sid			IN	security_pkg.T_SID_ID	DEFAULT NULL,
	out_scenario_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_forecasting_slots				BINARY_INTEGER;
	v_slots_remaining				BINARY_INTEGER;
	v_scenario_run_sid				NUMBER;
	v_scenarios_folder_sid			security_pkg.T_SID_ID;
	v_parent_folder_sid				security_pkg.T_SID_ID;
	v_forecasting_class_id			security_pkg.T_CLASS_ID := class_pkg.GetClassId('CSRForecasting');
	v_empty_sids					security_pkg.T_SID_IDS;
	v_rule_id						scenario_rule.rule_id%TYPE;
BEGIN
	v_scenarios_folder_sid := securableObject_pkg.GetSidFromPath(v_act,
		SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');	

	-- Lock to avoid race conditions with double submit etc
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_FORECASTING);

	-- Do they have any slots left?
	SELECT forecasting_slots
	  INTO v_forecasting_slots
	  FROM csr.customer;	

	SELECT v_forecasting_slots - COUNT(*)
	  INTO v_slots_remaining
	  FROM scenario s, security.securable_object so
	 WHERE so.class_id = v_forecasting_class_id
	   AND s.scenario_sid = so.sid_id;	

	IF v_slots_remaining < 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'No remaining Forecasting slots available.');
	END IF;
	  
	v_parent_folder_sid := NVL(in_parent_folder_sid, v_scenarios_folder_sid);

	scenario_pkg.SaveScenario(
		in_class_id					=> class_pkg.getClassID('CSRForecasting'),
		in_parent_sid				=> v_parent_folder_sid,
		in_scenario_sid				=> NULL,
		in_description				=> REPLACE(in_description, '/', '\'),
		in_indicators				=> in_ind_sids,
		in_regions					=> in_region_sids,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		in_period_set_id			=> in_period_set_id,
		in_period_interval_id		=> in_period_interval_id,
		in_include_all_inds			=> in_include_all_inds,
		in_file_based				=> 1,
		out_scenario_sid			=> out_scenario_sid
	);

	/* add a scenario rule encapsulating the forecasting value application
	   TODO: this might be better as separate scenario rules, but currently those structure
	   "add 20 to {set of indicators} x {set of regions}" rather than this structure
	   which is "to ind X, region Y add 20" x N inds x N regions
	   so we'd need to rework the i/o format
	*/
	scenario_pkg.SaveRule(
		in_scenario_sid				=> out_scenario_sid,
		in_rule_id					=> NULL,
		in_description				=> 'Forecasting rule',
		in_rule_type				=> scenario_pkg.RT_FORECASTING,
		in_amount					=> 0,
		in_measure_conversion_id	=> NULL,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		in_indicators				=> v_empty_sids,
		in_regions					=> v_empty_sids,
		out_rule_id					=> v_rule_id
	);
	
	-- add registered users read on the scenario
	AddRegisteredUsersRead(out_scenario_sid);

	-- Create the scenario run
	securableObject_pkg.CreateSO(v_act, v_parent_folder_sid, class_pkg.GetClassId('CSRScenarioRun'),
		REPLACE(in_description, '/', '\') || ' (run)', v_scenario_run_sid);
	--' Stop the single \ from confusing n++ by adding a single quote.
		
	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (v_scenario_run_sid, out_scenario_sid, in_description);

	-- Set it as the auto-update scenario run for this scenario, with a manual trigger	
	UPDATE csr.scenario
	   SET recalc_trigger_type = stored_calc_datasource_pkg.RECALC_TRIGGER_MANUAL,
		   auto_update_run_sid = v_scenario_run_sid
	 WHERE scenario_sid = out_scenario_sid;
	 
	-- add registered users read on the scenario run
	AddRegisteredUsersRead(v_scenario_run_sid);
END;

PROCEDURE RecalculateForecast(
	in_scenario_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	AssertWritePermission(in_scenario_sid);
	INSERT INTO scenario_auto_run_request (scenario_sid, full_recompute)
	VALUES (in_scenario_sid, 1);
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
		 START WITH sid_id = in_folder_sid 
		   AND class_id = security_pkg.SO_CONTAINER
	   CONNECT BY sid_id = PRIOR parent_sid_id 
		   AND class_id = security_pkg.SO_CONTAINER
		 ORDER BY LEVEL DESC;
END;

PROCEDURE GetForecastList(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_scenarios_folder_sid			security_pkg.T_SID_ID;
BEGIN
	v_scenarios_folder_sid := securableObject_pkg.GetSidFromPath(v_act_id,
		SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');	

	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_scenarios_folder_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.scenario_sid, s.description, s.start_dtm, s.end_dtm, 
			   floor(months_between(s.end_dtm, s.start_dtm) / 12) number_of_years,
			   s.period_set_id, s.period_interval_id, sr.scenario_run_sid,
			   s.created_by_user_sid, s.created_dtm, sr.last_run_by_user_sid,
			   sr.last_success_dtm, s.include_all_inds
		  FROM scenario s
		  JOIN scenario_run sr ON s.app_sid = sr.app_sid AND s.auto_update_run_sid = sr.scenario_run_sid
		  JOIN TABLE(securableObject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_scenarios_folder_sid, security_pkg.PERMISSION_READ)) so
		    ON so.sid_id = s.scenario_sid
		 WHERE so.class_id = class_pkg.GetClassId('CSRForecasting')		   
		 ORDER BY LOWER(s.description);
END;

FUNCTION GetForecastCount
RETURN NUMBER
AS
	v_count							BINARY_INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM scenario s, security.securable_object so
	 WHERE so.class_id = class_pkg.GetClassId('CSRForecasting')
	   AND s.scenario_sid = so.sid_id;	
	RETURN v_count;
END;

PROCEDURE GetChildForecasts(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.scenario_sid item_sid, s.description name, s.start_dtm base_dtm, (s.start_dtm + INTERVAL '1' year) start_dtm, (s.end_dtm + INTERVAL '1' year) end_dtm,
			   floor(months_between(s.end_dtm, s.start_dtm) / 12) number_of_years,
			   p.label period_interval_label, u.full_name last_refresh_user_name,
			   u.email last_refresh_user_mail, sr.last_success_dtm,
			   CASE WHEN m.csr_user_sid IS NULL THEN 0 ELSE 1 END is_user_subscribed,
			   CanEditForecast_sql(s.scenario_sid) can_write,
			   CanDeleteForecast_sql(s.scenario_sid) can_delete
		  FROM scenario s
		  JOIN scenario_run sr ON s.app_sid = sr.app_sid AND s.auto_update_run_sid = sr.scenario_run_sid
		  JOIN security.securable_object so ON so.sid_id = s.scenario_sid
		  JOIN period_interval p ON s.app_sid = p.app_sid
		   AND s.period_interval_id = p.period_interval_id AND p.period_set_id = s.period_set_id
		  LEFT JOIN csr_user u ON sr.app_sid = u.app_sid AND sr.last_run_by_user_sid = u.csr_user_sid
		  LEFT JOIN scenario_email_sub m ON s.app_sid = m.app_sid AND s.scenario_sid = m.scenario_sid
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act_id, in_parent_sid, security_pkg.PERMISSION_READ)) sp
		    ON sp.sid_id = s.scenario_sid
		 WHERE so.class_id = class_pkg.GetClassId('CSRForecasting')
		 ORDER BY LOWER(s.description);
END;

PROCEDURE UpdateRule(
	in_scenario_sid					IN	security_pkg.T_SID_ID,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE
)
AS
BEGIN
	DELETE FROM forecasting_rule
	 WHERE app_sid = security_pkg.getApp 
	   AND scenario_sid = in_scenario_sid
	   AND rule_id = in_rule_id
	   AND (region_sid NOT IN (
				SELECT region_sid
				  FROM scenario_region
				 WHERE app_sid = security_pkg.getApp AND scenario_sid = in_scenario_sid) OR
			ind_sid NOT IN (
				SELECT ind_sid
				  FROM scenario_ind
				 WHERE app_sid = security_pkg.getApp AND scenario_sid = in_scenario_sid) OR
			(start_dtm - INTERVAL '1' YEAR) >= (
				SELECT end_dtm
				  FROM scenario
				 WHERE app_sid = security_pkg.getApp AND scenario_sid = in_scenario_sid)
			);
END;

PROCEDURE SaveRule(
	in_scenario_sid					IN	forecasting_rule.scenario_sid%TYPE,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE,
	in_ind_sid						IN	forecasting_rule.ind_sid%TYPE,
	in_region_sid					IN	forecasting_rule.region_sid%TYPE,
	in_start_dtm					IN	forecasting_rule.start_dtm%TYPE,
	in_end_dtm						IN	forecasting_rule.end_dtm%TYPE,
	in_rule_type					IN	forecasting_rule.rule_type%TYPE,
	in_rule_val						IN	forecasting_rule.rule_val%TYPE
)
AS
BEGIN
	BEGIN
		security_pkg.debugmsg('scn ' ||in_scenario_sid||', rule '||in_rule_id);
		INSERT INTO forecasting_rule
			(scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm,
			 rule_type, rule_val)
		VALUES
			(in_scenario_sid, in_rule_id, in_ind_sid, in_region_sid, in_start_dtm,
			 in_end_dtm, UPPER(in_rule_type), in_rule_val);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE forecasting_rule
			   SET rule_type = in_rule_type, rule_val = in_rule_val
			 WHERE scenario_sid = in_scenario_sid
			   AND rule_id = in_rule_id
			   AND ind_sid = in_ind_sid
			   AND region_sid = in_region_sid
			   AND start_dtm = in_start_dtm
			   AND end_dtm = in_end_dtm;
	END;
END;

PROCEDURE DeleteRule(
	in_slot_sid						IN	forecasting_rule.scenario_sid%TYPE,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE,
	in_ind_sid						IN	forecasting_rule.ind_sid%TYPE,
	in_region_sid					IN	forecasting_rule.region_sid%TYPE
)
AS
BEGIN
	DELETE FROM forecasting_rule
	 WHERE app_sid = security_pkg.getApp
	   AND scenario_sid = in_slot_sid
	   AND rule_id = in_rule_id
	   AND ind_sid = in_ind_sid
	   AND region_sid = in_region_sid;
END;

PROCEDURE GetRules(
	in_scenario_sid					IN	security_pkg.T_SID_ID,
	out_rules_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_rules_cur FOR
		SELECT scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm, rule_type, rule_val
		  FROM forecasting_rule
		 WHERE app_sid = security_pkg.getApp
		   AND scenario_sid = in_scenario_sid
		 ORDER BY rule_id, region_sid, ind_sid, start_dtm;
END;

END;
/
