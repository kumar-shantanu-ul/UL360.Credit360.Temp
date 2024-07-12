CREATE OR REPLACE PACKAGE BODY CSR.like_for_like_pkg AS

/* 
** SECURABLE OBJECT CALLBACKS
*/
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	null;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_scenario_run_sid			security_pkg.T_SID_ID;
BEGIN

	DELETE FROM like_for_like_email_sub
	 WHERE like_for_like_sid = in_sid_id;

	DELETE FROM like_for_like_excluded_regions
	 WHERE like_for_like_sid = in_sid_id;

	DELETE FROM batch_job_like_for_like
	 WHERE like_for_like_sid = in_sid_id;

	DELETE FROM like_for_like_scenario_alert
	 WHERE like_for_like_sid = in_sid_id;

	SELECT scenario_run_sid
	  INTO v_scenario_run_sid
	  FROM csr.like_for_like_slot
	 WHERE LIKE_FOR_LIKE_SID = in_sid_id;

	DELETE FROM like_for_like_slot
	 WHERE like_for_like_sid = in_sid_id;

	security.securableobject_pkg.deleteso(in_act_id, v_scenario_run_sid);

END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

/* 
** CREATION PROCEDURES
*/

PROCEDURE CreateSlot(
	in_parent_sid				IN	NUMBER,
	in_name						IN	like_for_like_slot.name%TYPE,
	in_ind_sid					IN	like_for_like_slot.ind_sid%TYPE,
	in_region_sid				IN	like_for_like_slot.region_sid%TYPE,
	in_include_inactive_regions	IN	like_for_like_slot.include_inactive_regions%TYPE,
	in_period_start_dtm			IN	like_for_like_slot.period_start_dtm%TYPE,
	in_period_end_dtm			IN	like_for_like_slot.period_end_dtm%TYPE,
	in_period_set_id			IN	like_for_like_slot.period_set_id%TYPE,
	in_period_interval_id		IN	like_for_like_slot.period_interval_id%TYPE,
	in_rule_type				IN	like_for_like_slot.rule_type%TYPE,
	out_like_for_like_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_slots_remaining			NUMBER;
	v_scenario_run_sid			NUMBER;
	v_batch_job_id				NUMBER;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Add contents denied on folder: '||in_parent_sid);
	END IF;

	-- Do they have any slots left?
	SELECT like_for_like_slots - (SELECT COUNT(*) FROM csr.like_for_like_slot)
	  INTO v_slots_remaining
	  FROM csr.customer;
	
	IF v_slots_remaining < 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'No remaining Like for like slots available.');
	END IF;
	  
	  
	securableobject_pkg.CreateSO(security_pkg.getACT,
		in_parent_sid, 
		class_pkg.getClassID('CSRLikeForLike'),
		REPLACE(in_name,'/','\'), --'
		out_like_for_like_sid);
	
	like_for_like_pkg.CreateScenarioRun(in_name, v_scenario_run_sid);
	
	INSERT INTO like_for_like_slot
		(like_for_like_sid, name, ind_sid, region_sid, include_inactive_regions, period_start_dtm,
			period_end_dtm, period_set_id, period_interval_id, rule_type, scenario_run_sid,
			created_by_user_sid, created_dtm)
	VALUES
		(out_like_for_like_sid, in_name, in_ind_sid, in_region_sid, in_include_inactive_regions,
			in_period_start_dtm, in_period_end_dtm, in_period_set_id, in_period_interval_id,
			in_rule_type, v_scenario_run_sid, security_pkg.GetSid, SYSDATE);

	RefreshSlot(out_like_for_like_sid, v_batch_job_id);

END;

PROCEDURE CreateSlot(
	in_name								IN	like_for_like_slot.name%TYPE,
	in_ind_sid								IN	like_for_like_slot.ind_sid%TYPE,
	in_region_sid						IN	like_for_like_slot.region_sid%TYPE,
	in_include_inactive_regions	IN	like_for_like_slot.include_inactive_regions%TYPE,
	in_period_start_dtm				IN	like_for_like_slot.period_start_dtm%TYPE,
	in_period_end_dtm				IN	like_for_like_slot.period_end_dtm%TYPE,
	in_period_set_id					IN	like_for_like_slot.period_set_id%TYPE,
	in_period_interval_id				IN	like_for_like_slot.period_interval_id%TYPE,
	in_rule_type							IN	like_for_like_slot.rule_type%TYPE,
	out_like_for_like_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CreateSlot(
		in_parent_sid => securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, LIKE_FOR_LIKE_FOLDER),
		in_name => in_name,
		in_ind_sid => in_ind_sid,
		in_region_sid => in_region_sid,
		in_include_inactive_regions => in_include_inactive_regions,
		in_period_start_dtm => in_period_start_dtm,
		in_period_end_dtm => in_period_end_dtm,
		in_period_set_id => in_period_set_id,
		in_period_interval_id => in_period_interval_id,
		in_rule_type => in_rule_type,
		out_like_for_like_sid => out_like_for_like_sid
	);

END;

/* 
** SCENARIO / CALC PROCEDURES
*/

PROCEDURE CreateScenario
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
	
	--Find the scenarios container. Scenarios not enabled otherwise!
	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenarios object not found -- run EnableScenarios.sql first');
	END;
	
	-- Don't create a second one; just return the existing sid if already created
	BEGIN
		v_new_scenario_sid := security.securableObject_pkg.GetSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios/Like for like');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid, security.class_pkg.GetClassId('CSRScenario'), 'Like for like', v_new_scenario_sid);
			v_reg_users_sid := security.securableObject_pkg.getSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
			
			SELECT calc_start_dtm, calc_end_dtm
			  INTO v_calc_start_dtm, v_calc_end_dtm
			  FROM customer;

			INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, file_based, data_source, 
				data_source_sp, data_source_sp_args, auto_update_run_sid, include_all_inds)
			VALUES (v_new_scenario_sid, 'Like for like', v_calc_start_dtm, v_calc_end_dtm, 
				1, 4, 1, csr.stored_calc_datasource_pkg.DATA_SOURCE_CUSTOM_FETCH_SP,
				'csr.like_for_like_pkg.GetScenarioData', 'vals', NULL, 0);
			
			-- add registered users read on the scenario
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
	END;
	
END;

PROCEDURE CreateScenarioRun(
	in_name						IN	like_for_like_slot.name%TYPE,
	out_new_scenario_run_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID;
	v_acl_count						NUMBER;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_scenario_container			security.security_pkg.T_SID_ID;
	v_scenario_sid					security.security_pkg.T_SID_ID;
BEGIN

	v_act := SYS_CONTEXT('SECURITY', 'ACT');

	BEGIN
		v_scenario_container := security.securableObject_pkg.GetSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
		v_scenario_sid := security.securableObject_pkg.GetSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios/Like for like');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenario cannot be found. Ensure Like for like has been enabled.');
	END;

	-- Create the scenario run
	security.securableObject_pkg.CreateSO(v_act, v_scenario_container, 
		security.class_pkg.GetClassId('CSRScenarioRun'), in_name || ' (run)', out_new_scenario_run_sid);			
	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description, on_completion_sp)
	VALUES (out_new_scenario_run_sid, v_scenario_sid, in_name, 'csr.like_for_like_pkg.OnCalcJobCompletion');
	 
	 -- add registered users read on the scenario run
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(v_act, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
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
	
	/*
	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);
	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_new_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	*/

END;

PROCEDURE GetScenarioForFullPeriodRule(
	in_like_for_like_object		IN	t_like_for_like,
	in_like_for_like_val		IN	t_like_for_like_val_table,
	out_val_cur					OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_val_cur FOR
		SELECT v.period_start_dtm, v.period_end_dtm, v.ind_sid, v.region_sid, v.source_type_id,
			v.source_id, v.val_number, null error_code, 1 is_merged, null changed_dtm, null val_key
		  FROM TABLE (in_like_for_like_val) v
		  LEFT JOIN like_for_like_excluded_regions ex 
			ON v.region_sid = ex.region_sid
		   AND ex.like_for_like_sid = in_like_for_like_object.like_for_like_sid
		   AND v.period_end_dtm > in_like_for_like_object.period_start_dtm
		   AND v.period_start_dtm < in_like_for_like_object.period_end_dtm
		 WHERE ex.region_sid IS NULL
		 ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm;

END;

PROCEDURE LoadIndSids(
	in_raw_excluded_vals	IN	t_like_for_like_val_table,
	in_divisibility			IN	NUMBER,
	out_ind_sids			OUT	security.T_SID_TABLE
)
AS
BEGIN

	SELECT DISTINCT i.ind_sid BULK COLLECT INTO out_ind_sids
	  FROM TABLE (in_raw_excluded_vals) v
	  JOIN ind i
		ON i.ind_sid = v.ind_sid
	  LEFT JOIN csr.measure m
		ON i.measure_sid = m.measure_sid
	 WHERE NVL(i.divisibility, m.divisibility) = in_divisibility;

END;

PROCEDURE LoadExcludedValsRawTable(
	in_like_for_like_object		IN	t_like_for_like,
	in_like_for_like_val		IN	t_like_for_like_val_table,
	out_raw_excluded_vals		OUT	t_like_for_like_val_table
)
AS
BEGIN

	out_raw_excluded_vals := t_like_for_like_val_table();
	
	-- Excluded is checked again after aggregation this just filters to values that are likely to be included.
	-- Add distinct to avoid duplicate rows when the val has a higher granularity (eg Quarterly) than the exclusion ind (eg Monthly).
	FOR r in (
		SELECT DISTINCT v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, 
			v.val_number, v.source_type_id, v.source_id
		  FROM TABLE (in_like_for_like_val) v
		  JOIN like_for_like_excluded_regions ex 
			ON v.region_sid = ex.region_sid
		   AND ex.like_for_like_sid = in_like_for_like_object.like_for_like_sid
		   AND v.period_end_dtm > ex.period_start_dtm
		   AND v.period_start_dtm < ex.period_end_dtm)
	LOOP
		out_raw_excluded_vals.EXTEND;
		out_raw_excluded_vals(out_raw_excluded_vals.COUNT) := t_like_for_like_val_row(
			r.ind_sid,
			r.region_sid,
			r.period_start_dtm,
			r.period_end_dtm,
			r.val_number,
			r.source_type_id,
			r.source_id
		);
	END LOOP;

END;

PROCEDURE FillNormalizedTableDivisType(
	in_like_for_like_object				IN	t_like_for_like,
	in_raw_excluded_vals				IN	t_like_for_like_val_table,
	in_ind_sids							IN	security.T_SID_TABLE,
	in_divisibility						IN	NUMBER
)
AS
	v_cur								SYS_REFCURSOR;
	v_norm_values						t_normalised_val_table;
BEGIN

	FOR r in (
		SELECT column_value ind_sid
		  FROM TABLE(in_ind_sids))
	LOOP
		OPEN v_cur FOR
			SELECT region_sid, period_start_dtm, period_end_dtm, val_number
			  FROM TABLE (in_raw_excluded_vals) v
			 WHERE v.ind_sid = r.ind_sid
			 ORDER BY region_sid, period_start_dtm;

			v_norm_values := period_pkg.AggregateOverTime(
				in_cur => v_cur,
				in_start_dtm => in_like_for_like_object.period_start_dtm,
				in_end_dtm => in_like_for_like_object.period_end_dtm,
				in_period_set_id => in_like_for_like_object.period_set_id,
				in_peiod_interval_id => in_like_for_like_object.period_interval_id,
				in_divisibility => in_divisibility
			);

			FOR norm_val IN (
				SELECT nv.region_sid, nv.start_dtm, nv.end_dtm, nv.val_number
				  FROM TABLE(v_norm_values) nv
				  LEFT JOIN like_for_like_excluded_regions ex
					ON ex.like_for_like_sid = in_like_for_like_object.like_for_like_sid
				   AND nv.region_sid = ex.region_sid
				   AND nv.start_dtm = ex.period_start_dtm
				   AND nv.end_dtm = ex.period_end_dtm
				 WHERE ex.region_sid IS NULL
				   AND nv.val_number IS NOT NULL
			)
			LOOP
				INSERT INTO t_like_for_like_val_normalised
					(ind_sid, region_sid, period_start_dtm, period_end_dtm,
						val_number, source_type_id, source_id)
				VALUES
					(r.ind_sid, norm_val.region_sid, norm_val.start_dtm, norm_val.end_dtm, 
						norm_val.val_number, CSR_DATA_PKG.SOURCE_TYPE_DIRECT, null);
			END LOOP;
	END LOOP;

END;

PROCEDURE GetFinalValues(
	in_like_for_like_object		IN	t_like_for_like,
	in_like_for_like_val		IN	t_like_for_like_val_table,
	out_val_cur					OUT SYS_REFCURSOR
)
AS
	v_like_for_like_val_normalised_table	T_LIKE_FOR_LIKE_VAL_NORMALISED_TABLE;
BEGIN

	SELECT T_LIKE_FOR_LIKE_VAL_NORMALISED_ROW(ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, source_type_id, source_id)
	BULK COLLECT INTO v_like_for_like_val_normalised_table
	  FROM t_like_for_like_val_normalised n;

	OPEN out_val_cur FOR
		SELECT v.period_start_dtm period_start_dtm, v.period_end_dtm period_end_dtm, v.ind_sid ind_sid, v.region_sid region_sid, v.source_type_id source_type_id,
			v.source_id source_id, v.val_number val_number, null error_code, 1 is_merged, null changed_dtm, null val_key
		  FROM TABLE (in_like_for_like_val) v
		  LEFT JOIN like_for_like_excluded_regions ex 
			ON v.region_sid = ex.region_sid
		   AND ex.like_for_like_sid = in_like_for_like_object.like_for_like_sid
		   AND v.period_end_dtm > ex.period_start_dtm
		   AND v.period_start_dtm < ex.period_end_dtm
		 WHERE ex.region_sid IS NULL
		 UNION
		SELECT n.period_start_dtm, n.period_end_dtm, n.ind_sid, n.region_sid, n.source_type_id,
			n.source_id, n.val_number, null error_code, 1 is_merged, null changed_dtm, null val_key
		  FROM TABLE(v_like_for_like_val_normalised_table) n
		 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

PROCEDURE GetScenarioForPerPeriodRule(
	in_like_for_like_object		IN	t_like_for_like,
	in_like_for_like_val		IN	t_like_for_like_val_table,
	out_val_cur					OUT SYS_REFCURSOR
)
AS
	v_raw_excluded_vals				t_like_for_like_val_table;
	v_di_average_ind_sids			security.T_SID_TABLE;
	v_di_divisible_ind_sids			security.T_SID_TABLE;
	v_di_last_period_ind_sids		security.T_SID_TABLE;
	v_count						NUMBER := 0;
BEGIN

	LoadExcludedValsRawTable(in_like_for_like_object, in_like_for_like_val, v_raw_excluded_vals);

	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE (v_raw_excluded_vals);

	IF v_count = 0 THEN
		GetScenarioForFullPeriodRule(in_like_for_like_object, in_like_for_like_val, out_val_cur);
		RETURN;
	END IF;

	LoadIndSids(v_raw_excluded_vals, csr_data_pkg.DIVISIBILITY_AVERAGE,
		v_di_average_ind_sids);
	LoadIndSids(v_raw_excluded_vals, csr_data_pkg.DIVISIBILITY_DIVISIBLE,
		v_di_divisible_ind_sids);
	LoadIndSids(v_raw_excluded_vals, csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		v_di_last_period_ind_sids);

	DELETE FROM t_like_for_like_val_normalised;

	FillNormalizedTableDivisType(in_like_for_like_object, v_raw_excluded_vals,
		v_di_average_ind_sids, csr_data_pkg.DIVISIBILITY_AVERAGE);
	FillNormalizedTableDivisType(in_like_for_like_object, v_raw_excluded_vals,
		v_di_divisible_ind_sids, csr_data_pkg.DIVISIBILITY_DIVISIBLE);
	FillNormalizedTableDivisType(in_like_for_like_object, v_raw_excluded_vals,
		v_di_last_period_ind_sids, csr_data_pkg.DIVISIBILITY_LAST_PERIOD);

	GetFinalValues(in_like_for_like_object, in_like_for_like_val, out_val_cur);

END;

PROCEDURE LoadBaseValTable(
	in_like_for_like_object		IN	t_like_for_like,
	out_like_for_like_val		OUT	t_like_for_like_val_table
)
AS
BEGIN

	out_like_for_like_val := t_like_for_like_val_table();

	/*
		Loading any value that intersects with the period defined in the slot
		and belongs to a region under the slot's root region.
	*/

	FOR r in (
	SELECT v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
		v.val_number, v.source_id, v.source_type_id
	  FROM val v
	  JOIN ind i 
		ON i.ind_sid = v.ind_sid
	 WHERE i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
	   AND v.ind_sid != in_like_for_like_object.ind_sid
	   AND v.region_sid in (
		SELECT region_sid
		  FROM region
		 START WITH region_sid = in_like_for_like_object.region_sid
	   CONNECT BY PRIOR region_sid = parent_sid)
	   AND v.period_end_dtm > in_like_for_like_object.period_start_dtm
	   AND v.period_start_dtm < in_like_for_like_object.period_end_dtm)
	LOOP
		out_like_for_like_val.EXTEND;
		out_like_for_like_val(out_like_for_like_val.COUNT) := t_like_for_like_val_row(
			r.ind_sid,
			r.region_sid,
			r.period_start_dtm,
			r.period_end_dtm,
			r.val_number,
			r.source_type_id,
			r.source_id
		);
	END LOOP;

END;

PROCEDURE GetScenarioData(
	in_start_dtm					IN  DATE,
	in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
	out_val_cur						OUT SYS_REFCURSOR
)
AS
	v_slot_sid						security.security_pkg.T_SID_ID;
	v_like_for_like_object			t_like_for_like;
	v_like_for_like_val				t_like_for_like_val_table;
BEGIN

	SELECT like_for_like_sid
	  INTO v_slot_sid
	  FROM like_for_like_slot
	 WHERE scenario_run_sid = in_scenario_run_sid;
	v_like_for_like_object := t_like_for_like(v_slot_sid);

	LoadBaseValTable(v_like_for_like_object, v_like_for_like_val);

	IF v_like_for_like_object.rule_type = RULE_TYPE_FULL_PERIOD THEN
		GetScenarioForFullPeriodRule(v_like_for_like_object, v_like_for_like_val, out_val_cur);
	ELSE
		GetScenarioForPerPeriodRule(v_like_for_like_object, v_like_for_like_val, out_val_cur);
	END IF;

END;

PROCEDURE TriggerScenarioRecalc(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
)
AS
	v_scenario_run_sid			NUMBER;
BEGIN
	
	SELECT scenario_run_sid
	  INTO v_scenario_run_sid
	  FROM like_for_like_slot
	 WHERE like_for_like_sid = in_like_for_like_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	stored_calc_datasource_pkg.AddFullScenarioJob(SYS_CONTEXT('SECURITY', 'app'), v_scenario_run_sid, 0, 0);	
	
END;

PROCEDURE OnCalcJobCompletion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
)
AS
	v_like_for_like_sid					NUMBER;
BEGIN
	-- Sort out the email subscriptions
	INSERT INTO like_for_like_scenario_alert
		(app_sid, like_for_like_sid, csr_user_sid, calc_job_id, calc_job_completion_dtm)
	SELECT sub.app_sid, sub.like_for_like_sid, sub.csr_user_sid, in_calc_job_id, run.last_success_dtm
	  FROM like_for_like_email_sub sub
	  JOIN like_for_like_slot slot 	ON sub.like_for_like_sid = slot.like_for_like_sid
	  JOIN scenario_run run 		ON slot.scenario_run_sid = run.scenario_run_sid
	 WHERE slot.scenario_run_sid = in_scenario_run_sid;

	SELECT like_for_like_sid
	  INTO v_like_for_like_sid
	  FROM like_for_like_slot
	 WHERE scenario_run_sid = in_scenario_run_sid;

	UPDATE like_for_like_slot
	   SET last_refresh_dtm = SYSTIMESTAMP
	 WHERE like_for_like_sid = v_like_for_like_sid;

END;

PROCEDURE GetPendingScenarioAlerts(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT slot.app_sid app_sid, slot.like_for_like_sid like_for_like_sid, alert.csr_user_sid to_user_sid, slot.name slot_name, run.description scenario_run_name, alert.calc_job_completion_dtm completion_dtm, 
			   slot.period_start_dtm start_dtm, slot.period_end_dtm end_dtm, alert.calc_job_id calc_job_id
		  FROM like_for_like_scenario_alert alert
		  JOIN like_for_like_slot slot ON alert.like_for_like_sid = slot.like_for_like_sid
		  JOIN scenario_run run ON slot.scenario_run_sid = run.scenario_run_sid
		 ORDER BY app_sid, alert.calc_job_completion_dtm DESC;

END;

PROCEDURE MarkScenarioAlertSent(
	in_app_sid			IN	like_for_like_scenario_alert.app_sid%TYPE,
	in_calc_job_id		IN	like_for_like_scenario_alert.calc_job_id%TYPE,
	in_user_sid			IN	like_for_like_scenario_alert.csr_user_sid%TYPE
)
AS
BEGIN

	DELETE FROM like_for_like_scenario_alert
	 WHERE app_sid		= in_app_sid
	   AND calc_job_id	= in_calc_job_id
	   AND csr_user_sid	= in_user_sid;

END;

/* 
** PERMISSION PROCEDURES
*/

PROCEDURE AssertWritePermission(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_like_for_like_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on like for like slot with sid '||in_like_for_like_sid);
	END IF;

END;

-- READ permission on the slot
FUNCTION CanViewSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_ind_sid		security_pkg.T_SID_ID;
	v_region_sid	security_pkg.T_SID_ID;
BEGIN

	RETURN security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_like_for_like_sid, security_pkg.PERMISSION_READ);

END;

-- WRITE permission on the slot, read on the indicator and region
FUNCTION CanEditSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_ind_sid						security_pkg.T_SID_ID;
	v_region_sid					security_pkg.T_SID_ID;
BEGIN

	like_for_like_pkg.AssertWritePermission(in_like_for_like_sid);

	SELECT ind_sid, region_sid
	  INTO v_ind_sid, v_region_sid
	  FROM like_for_like_slot
	 WHERE like_for_like_sid = in_like_for_like_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_ind_sid, security_pkg.PERMISSION_READ) THEN
		RETURN FALSE;
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RETURN FALSE;
	END IF;
	
	RETURN TRUE;

END;

FUNCTION CanEditSlot_sql(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	in_do_assert				IN	NUMBER DEFAULT 0
) RETURN BINARY_INTEGER
AS
BEGIN

	BEGIN
		IF like_for_like_pkg.CanEditSlot(in_like_for_like_sid) THEN
			RETURN 1;
		END IF;

		RETURN 0;

		EXCEPTION
			WHEN security_pkg.ACCESS_DENIED THEN
				IF in_do_assert > 0 THEN
					RAISE;
				END IF;
				RETURN 0;
	END;

END;

-- WRITE permission on the slot, read on the indicator and region
FUNCTION CanRefreshSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_ind_sid		security_pkg.T_SID_ID;
	v_region_sid	security_pkg.T_SID_ID;
BEGIN

	like_for_like_pkg.AssertWritePermission(in_like_for_like_sid);
	
	SELECT ind_sid, region_sid
	  INTO v_ind_sid, v_region_sid
	  FROM like_for_like_slot
	 WHERE like_for_like_sid = in_like_for_like_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_ind_sid, security_pkg.PERMISSION_READ) THEN
		RETURN FALSE;
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RETURN FALSE;
	END IF;
	
	RETURN TRUE;

END;

/* 
** EDIT PROCEDURES
*/

PROCEDURE RenameSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	in_new_name					IN	like_for_like_slot.name%TYPE
)
AS
BEGIN

	IF NOT like_for_like_pkg.CanEditSlot(in_like_for_like_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied renaming like for like slot '||in_like_for_like_sid);
	END IF;
	
	UPDATE like_for_like_slot
	   SET name = in_new_name
	 WHERE like_for_like_sid = in_like_for_like_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE RefreshSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN

	IF NOT like_for_like_pkg.CanRefreshSlot(in_like_for_like_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied refreshing like for like slot '||in_like_for_like_sid);
	END IF;

	UPDATE like_for_like_slot
	   SET last_refresh_user_sid = security_pkg.getSid
	 WHERE like_for_like_sid = in_like_for_like_sid;

	-- Create the batch job for the regions
	like_for_like_pkg.CreateExcludedRegionsJob(
		in_like_for_like_sid	=> in_like_for_like_sid,
		out_batch_job_id		=> out_batch_job_id
	);

END;

/* 
** BATCH JOB PROCEDURES
*/

PROCEDURE CreateExcludedRegionsJob(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	out_batch_job_id					OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN

	like_for_like_pkg.AssertWritePermission(in_like_for_like_sid);

	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.jt_like_for_like,
		in_description => 'Like for like, regions excluded recalc.',
		in_total_work => 1,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_like_for_like
		(batch_job_id, like_for_like_sid)
	VALUES
		(out_batch_job_id, in_like_for_like_sid);

END;

PROCEDURE OnExcludedRegionsCompletion(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_batch_job_id						IN	batch_job.batch_job_id%TYPE
)
AS
	v_scenario_run_sid		NUMBER;
BEGIN

	like_for_like_pkg.TriggerScenarioRecalc(in_like_for_like_sid);

END;

PROCEDURE UNSEC_AddExcludedRegion(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_region_sid						IN	region.region_sid%TYPE,
	in_start_dtm						IN	DATE,
	in_end_dtm							IN	DATE
)
AS
BEGIN

	INSERT INTO like_for_like_excluded_regions
		(like_for_like_sid, region_sid, period_start_dtm, period_end_dtm)
	VALUES
		(in_like_for_like_sid, in_region_sid, in_start_dtm, in_end_dtm);

END;

PROCEDURE ClearCurrentExclusions(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_region_sid						IN	region.region_sid%TYPE DEFAULT NULL
)
AS
BEGIN

	like_for_like_pkg.AssertWritePermission(in_like_for_like_sid);

	DELETE FROM like_for_like_excluded_regions
	 WHERE app_sid = security.security_pkg.GetAPP
	   AND like_for_like_sid = in_like_for_like_sid
	   AND (in_region_sid IS NULL OR region_sid = in_region_sid);

END;

PROCEDURE GetSlotToProcess(
	in_batch_job_id						IN	NUMBER,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT slot.like_for_like_sid, slot.name, slot.ind_sid, slot.region_sid,
			slot.include_inactive_regions, slot.period_start_dtm, slot.period_end_dtm,
			slot.period_set_id, slot.period_interval_id, slot.rule_type,
			slot.scenario_run_sid, slot.created_by_user_sid, slot.created_dtm,
			slot.last_refresh_user_sid, slot.last_refresh_dtm
		  FROM batch_job_like_for_like bj
		  JOIN like_for_like_slot slot ON bj.like_for_like_sid = slot.like_for_like_sid
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetRegionSids(
	in_region_root_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive_regions		IN NUMBER DEFAULT 1,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	--
	OPEN out_cur FOR
		SELECT region_sid
		  FROM region
		 WHERE (in_include_inactive_regions > 0 OR active = 1)
		 START WITH region_sid = in_region_root_sid
	   CONNECT BY PRIOR region_sid = parent_sid;
END;

/* 
** AUX PROCEDURES
*/

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
		   AND class_id = security.security_pkg.SO_CONTAINER
	   CONNECT BY sid_id = PRIOR parent_sid_id 
		   AND class_id = security.security_pkg.SO_CONTAINER
		 ORDER BY LEVEL DESC;
END;

PROCEDURE GetChildSlots(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.like_for_like_sid, s.name, s.ind_sid, i.description indicator_description,
			i.ind_type, s.region_sid, r.description region_description, t.class_name region_class,
			s.include_inactive_regions, s.period_start_dtm, s.period_end_dtm, s.period_set_id,
			s.period_interval_id, p.label period_interval_label, s.rule_type, s.created_by_user_sid,
			s.created_dtm, s.last_refresh_user_sid, u.friendly_name last_refresh_user_name,
			u.email last_refresh_user_mail, s.last_refresh_dtm,
			CASE WHEN m.csr_user_sid IS NULL THEN 0 ELSE 1 END is_user_subscribed,
			CanEditSlot_sql(s.like_for_like_sid) user_can_edit_slot
		  FROM like_for_like_slot s
		  JOIN security.securable_object so ON so.sid_id = s.like_for_like_sid
		  LEFT JOIN csr_user u ON s.last_refresh_user_sid = u.csr_user_sid
		  JOIN period_interval p ON s.period_interval_id = p.period_interval_id
		   AND p.period_set_id = s.period_set_id
		  LEFT JOIN like_for_like_email_sub m ON  s.like_for_like_sid = m.like_for_like_sid
		   AND m.csr_user_sid = security_pkg.getSid
		  JOIN v$ind i ON s.ind_sid = i.ind_sid
		  JOIN v$region r ON s.region_sid = r.region_sid
		  JOIN region_type t ON r.region_type = t.region_type
		 WHERE so.parent_sid_id = in_parent_sid
		   AND s.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), s.like_for_like_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY s.name;
END;

PROCEDURE GetSlotList(
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_like_forLike_slots_sid		security_pkg.T_SID_ID;
BEGIN
	v_like_forLike_slots_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), LIKE_FOR_LIKE_FOLDER);

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_like_forLike_slots_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.like_for_like_sid, s.name, s.ind_sid, s.include_inactive_regions, s.period_start_dtm, s.period_end_dtm, s.period_set_id, s.period_interval_id,
			s.rule_type, s.created_by_user_sid, s.last_refresh_user_sid, s.last_refresh_dtm
		  FROM like_for_like_slot s
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), s.like_for_like_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY s.name;
END;

FUNCTION GetSlotCount
RETURN NUMBER
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_count							NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM like_for_like_slot s
	 WHERE app_sid = v_app_sid;

	RETURN v_count;
END;

PROCEDURE Subscribe(
	in_slot_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN

	INSERT INTO like_for_like_email_sub
		(like_for_like_sid, csr_user_sid)
	VALUES
		(in_slot_sid, security_pkg.getSid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;

END;

PROCEDURE Unsubscribe(
	in_slot_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN

	DELETE FROM like_for_like_email_sub
	 WHERE csr_user_sid = security_pkg.getSid
	   AND like_for_like_sid = in_slot_sid;

END;

END;
/
