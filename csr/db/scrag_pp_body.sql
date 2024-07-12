CREATE OR REPLACE PACKAGE BODY CSR.scrag_pp_pkg IS

FUNCTION SecurableObjectExists(
	in_path IN VARCHAR2,
	in_parent_sid_id IN Security_Pkg.T_SID_ID
)
RETURN BOOLEAN
AS
v_securableObject_sid security.security_pkg.T_SID_ID;
BEGIN
	v_securableObject_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid_id, in_path);
	RETURN TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN FALSE;
END;

FUNCTION OnlyUnmergedScenarioExists(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN,
	v_test_scenario_exists IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	RETURN v_unmerged_scenario_exists AND v_unmerged_scenario_run_exists AND
	  NOT v_merged_scenario_exists AND NOT v_merged_scenario_run_exists AND
	  NOT v_test_scenario_exists;
END;

FUNCTION CanUpdateTestcubeToMerged(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN,
	v_test_scenario_exists IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	RETURN NOT v_merged_scenario_exists AND NOT v_merged_scenario_run_exists AND
	  v_unmerged_scenario_exists AND v_unmerged_scenario_run_exists AND
	  v_test_scenario_exists;
END;

FUNCTION AnyScenarioExists(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	RETURN v_merged_scenario_exists OR v_merged_scenario_run_exists OR v_unmerged_scenario_exists OR
	  v_unmerged_scenario_run_exists;
END;

FUNCTION BothScenarioExist(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	RETURN v_merged_scenario_exists AND v_merged_scenario_run_exists AND v_unmerged_scenario_exists AND
	  v_unmerged_scenario_run_exists;
END;

PROCEDURE Trace(
	in_msg VARCHAR2
)
AS
BEGIN
	--dbms_output.put_line(in_msg);
	NULL;
END;

PROCEDURE UpdateACE(
	in_name			VARCHAR2,
	in_sid			security.security_pkg.T_SID_ID,
	in_allow_sid	security.security_pkg.T_SID_ID
)
AS
	v_acl_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = in_allow_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		Trace('Not found, adding registered users read on the '||in_name||'.');
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(in_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, in_allow_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	ELSE
		Trace('Registered users read found on the '||in_name||'.');
	END IF;
END;

PROCEDURE EnableTestCube
AS
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_merged_scenario_exists		BOOLEAN;
	v_merged_scenario_run_exists	BOOLEAN;
	v_unmerged_scenario_exists		BOOLEAN;
	v_unmerged_scenario_run_exists	BOOLEAN;
	v_test_scenario_exists			BOOLEAN;
	v_scenarios_sid					security.security_pkg.T_SID_ID;
	v_scenario_sid					security.security_pkg.T_SID_ID;
	v_scenario_run_sid				security.security_pkg.T_SID_ID;
	v_scragpp_status_rows			NUMBER;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	v_merged_scenario_exists := SecurableObjectExists('Merged scenario', v_app_sid);
	v_merged_scenario_run_exists := SecurableObjectExists('Merged scenario run', v_app_sid);
	v_unmerged_scenario_exists := SecurableObjectExists('Unmerged scenario', v_app_sid);
	v_unmerged_scenario_run_exists := SecurableObjectExists('Unmerged scenario run', v_app_sid);

	SELECT COUNT(*)
	  INTO v_scragpp_status_rows
	  FROM csr.scragpp_status
	WHERE app_sid = v_app_sid;

	IF v_scragpp_status_rows = 0 THEN
		INSERT INTO csr.scragpp_status (app_sid) values (v_app_sid);
	END IF;

	IF NOT SecurableObjectExists('Scenarios', v_app_sid) THEN
		csr.enable_pkg.EnableScenarios;
	END IF;

	v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Scenarios');
	v_test_scenario_exists := SecurableObjectExists('New calc engine scenario run', v_scenarios_sid);

	IF NOT OnlyUnmergedScenarioExists(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists,
	  v_merged_scenario_exists, v_merged_scenario_run_exists, v_test_scenario_exists)
	  AND AnyScenarioExists(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists,
	  v_merged_scenario_exists, v_merged_scenario_run_exists) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Scenarios already exist for this client.');
	END IF;

	IF v_test_scenario_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Test scenario already exists for this client.');
	END IF;

	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid,
		security.class_pkg.GetClassId('CSRScenario'), 'New calc engine scenario', v_scenario_sid);
	
	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
		SELECT v_scenario_sid, 'New calc engine scenario', calc_start_dtm, calc_end_dtm, 1, 4, 0
		  FROM csr.customer;
	
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid,
		security.class_pkg.GetClassId('CSRScenarioRun'), 'New calc engine scenario run', v_scenario_run_sid);
	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (v_scenario_run_sid, v_scenario_sid, 'New calc engine scenario run');
	
	UPDATE csr.scenario
	   SET recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
		   data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_MERGED,
		   auto_update_run_sid = v_scenario_run_sid,
		   file_based = 1
	 WHERE scenario_sid = v_scenario_sid;

	INSERT INTO csr.scenario_auto_run_request (scenario_sid, full_recompute)
		SELECT s.scenario_sid, 1
		  FROM csr.scenario_run s
		 WHERE scenario_run_sid = v_scenario_run_sid
		   AND NOT EXISTS (SELECT NULL FROM csr.scenario_auto_run_request r WHERE r.scenario_sid = s.scenario_sid);
	
	UPDATE csr.scragpp_status SET testcube_enabled = 1 WHERE app_sid = v_app_sid;
	INSERT INTO csr.scragpp_audit_log (app_sid, action, action_dtm, user_sid) VALUES (v_app_sid, 'csr.scrag_pp_pkg.EnableTestCube', SYSDATE, SYS_CONTEXT('SECURITY', 'SID'));
	
END;

PROCEDURE MigrateTestCube
AS
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_scenario_sid					security.security_pkg.T_SID_ID;
	v_scenarios_sid					security.security_pkg.T_SID_ID;
	v_scenario_run_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
BEGIN
	Trace('Reusing test scenario as merged.');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Scenarios');
	v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_scenarios_sid, 'New calc engine scenario run');
	security.securableObject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), v_scenario_run_sid, 'Merged scenario run');
	security.securableObject_pkg.MoveSO(SYS_CONTEXT('SECURITY', 'ACT'), v_scenario_run_sid, v_app_sid);
	UPDATE csr.scenario_run SET description = 'Merged scenario run' WHERE scenario_run_sid = v_scenario_run_sid;
	SELECT scenario_sid
	  INTO v_scenario_sid
	  FROM csr.scenario_run
	 WHERE scenario_run_sid = v_scenario_run_sid;
	security.securableObject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), v_scenario_sid, 'Merged scenario');
	security.securableObject_pkg.MoveSO(SYS_CONTEXT('SECURITY', 'ACT'), v_scenario_sid, v_app_sid);
	UPDATE csr.scenario SET description = 'Merged scenario' WHERE scenario_sid = v_scenario_sid;

	-- add registered users read on the scenario
	Trace('Checking registered users read on the merged scenario.');
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(
	SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Groups/RegisteredUsers');
	UpdateACE('merged scenario', v_scenario_sid, v_reg_users_sid);

	-- add registered users read on the scenario run
	Trace('Checking registered users read on the merged scenario run.');
	UpdateACE('merged scenario run', v_scenario_run_sid, v_reg_users_sid);

	UPDATE csr.customer
	   SET merged_scenario_run_sid = v_scenario_run_sid
	WHERE app_sid = v_app_sid;

	Trace('Adding a recalc job for the merged scenario run.');
	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);
	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE CreateUnmergedScenario
AS
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_unmerged_scenario_sid			security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_scenario_run_sid				security.security_pkg.T_SID_ID;
BEGIN
	Trace('Creating unmerged scenario.');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_app_sid, 
	security.class_pkg.GetClassId('CSRScenario'), 'Unmerged scenario', v_unmerged_scenario_sid);
		
	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
		SELECT v_unmerged_scenario_sid, 'Unmerged scenario', calc_start_dtm, calc_end_dtm, 1, 1, 0
		  FROM csr.customer;

	-- add registered users read on the scenario
	Trace('Checking registered users read on the unmerged scenario.');
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(
	SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Groups/RegisteredUsers');
	UpdateACE('unmerged scenario', v_unmerged_scenario_sid, v_reg_users_sid);

	-- Create the unmerged scenario run
	Trace('Creating unmerged scenario run.');
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_app_sid, 
		security.class_pkg.GetClassId('CSRScenarioRun'), 'Unmerged scenario run', v_scenario_run_sid);
	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (v_scenario_run_sid, v_unmerged_scenario_sid, 'Unmerged scenario run');
	
	UPDATE csr.scenario
	   SET file_based = 1,
	   	   auto_update_run_sid = v_scenario_run_sid,
	       recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_UNMERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_UNMERGED
	 WHERE scenario_sid = v_unmerged_scenario_sid;
	
	-- add registered users read on the scenario run
	Trace('Checking registered users read on the unmerged scenario run.');
	UpdateACE('unmerged scenario run', v_scenario_run_sid, v_reg_users_sid);

	Trace('Adding a recalc job for the unmerged scenario run.');
	UPDATE csr.customer
	   SET unmerged_scenario_run_sid = v_scenario_run_sid
	 WHERE app_sid = v_app_sid;

	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);
	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_unmerged_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

END;

PROCEDURE CheckForExceptions(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN,
	v_test_scenario_exists IN BOOLEAN
)
AS
BEGIN
	IF NOT v_test_scenario_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Test scenario does not exist.');
	END IF;

	IF v_merged_scenario_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged scenario object found.');
	END IF;

	IF v_merged_scenario_run_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged scenario run object found.');
	END IF;

	IF v_unmerged_scenario_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unmerged scenario object found.');
	END IF;

	IF v_unmerged_scenario_run_exists THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unmerged scenario run object found.');
	END IF;
END;

FUNCTION ShouldMigrateTestCube(
	v_unmerged_scenario_exists IN BOOLEAN, v_unmerged_scenario_run_exists IN BOOLEAN,
	v_merged_scenario_exists IN BOOLEAN, v_merged_scenario_run_exists IN BOOLEAN,
	v_test_scenario_exists IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	IF CanUpdateTestcubeToMerged(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists, v_merged_scenario_exists,
		v_merged_scenario_run_exists, v_test_scenario_exists) THEN
			RETURN TRUE;
	END IF;

	CheckForExceptions(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists, v_merged_scenario_exists,
		v_merged_scenario_run_exists, v_test_scenario_exists);

	RETURN TRUE;
END;

FUNCTION ShouldCreateUnmerged(
	in_unmerged_scenario_exists 	IN BOOLEAN, 
	in_unmerged_scenario_run_exists	IN BOOLEAN
)
RETURN BOOLEAN
AS
BEGIN
	IF in_unmerged_scenario_exists OR in_unmerged_scenario_run_exists THEN
		RETURN FALSE;
	END IF;

	RETURN TRUE;
END;

PROCEDURE EnableScragPP(
	in_approved_ref					IN VARCHAR2 DEFAULT NULL
)
AS
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_test_scenario_exists			BOOLEAN;
	v_merged_scenario_exists		BOOLEAN;
	v_merged_scenario_run_exists	BOOLEAN;
	v_unmerged_scenario_exists		BOOLEAN;
	v_unmerged_scenario_run_exists	BOOLEAN;
	v_scenarios_sid					security.security_pkg.T_SID_ID;
	v_scragpp_status_rows			NUMBER;
	v_shouldMigrateTestCube			BOOLEAN;
	v_shouldCreateUnmerged			BOOLEAN;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_merged_scenario_exists := SecurableObjectExists('Merged scenario', v_app_sid);
	v_merged_scenario_run_exists := SecurableObjectExists('Merged scenario run', v_app_sid);
	v_unmerged_scenario_exists := SecurableObjectExists('Unmerged scenario', v_app_sid);
	v_unmerged_scenario_run_exists := SecurableObjectExists('Unmerged scenario run', v_app_sid);
	
	SELECT COUNT(*)
	  INTO v_scragpp_status_rows
	  FROM csr.scragpp_status
	  WHERE app_sid = v_app_sid;

	IF v_scragpp_status_rows = 0 THEN
		INSERT INTO csr.scragpp_status (app_sid) values (v_app_sid);
	END IF;

	IF NOT SecurableObjectExists('Scenarios', v_app_sid) THEN
		csr.enable_pkg.EnableScenarios;
	END IF;

	v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Scenarios');
	IF BothScenarioExist(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists,
	  v_merged_scenario_exists, v_merged_scenario_run_exists) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged and unmerged scenarios exist.');
	END IF;
	
	v_test_scenario_exists := SecurableObjectExists('New calc engine scenario run', v_scenarios_sid);
	
	v_shouldMigrateTestCube := ShouldMigrateTestCube(v_unmerged_scenario_exists, v_unmerged_scenario_run_exists,
	  v_merged_scenario_exists, v_merged_scenario_run_exists, v_test_scenario_exists);
	
	v_shouldCreateUnmerged := ShouldCreateUnmerged(
		in_unmerged_scenario_exists 	=> v_unmerged_scenario_exists, 
		in_unmerged_scenario_run_exists	=> v_unmerged_scenario_run_exists);

	IF v_shouldMigrateTestCube THEN
		MigrateTestCube;
	END IF;
	
	IF v_shouldCreateUnmerged THEN
		CreateUnmergedScenario;
	END IF;

	UPDATE csr.scragpp_status SET testcube_enabled = 0, old_scrag = 0, scragpp_enabled = 1, validation_approved_ref = in_approved_ref WHERE app_sid = v_app_sid;
	INSERT INTO csr.scragpp_audit_log (app_sid, action, action_dtm, user_sid) VALUES (v_app_sid, 'csr.scrag_pp_pkg.EnableScragPP', SYSDATE, SYS_CONTEXT('SECURITY', 'SID'));
END;

END scrag_pp_pkg;
/

