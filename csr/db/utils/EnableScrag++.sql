DECLARE
	-- Enables the merged/unmerged cubes, reusing a test scenario if it was enabled
	--
	-- Run @enablescenarios first
	--
    v_app_sid 						security.security_pkg.T_SID_ID;
    v_scenario_sid					security.security_pkg.T_SID_ID;
    v_scenarios_sid					security.security_pkg.T_SID_ID;
    v_scenario_run_sid 				security.security_pkg.T_SID_ID;
    v_parent_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_acl_count						NUMBER;
BEGIN
    security.user_pkg.logonadmin('&&1', 86400);
    v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(
		SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');

	-- Get the scenarios folder
	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenarios object not found -- run EnableScenarios.sql first');
	END;

	-- Find the test scenario -- rename + move if present
	BEGIN
		dbms_output.put_line('Looking for test scenario.');
		v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_scenarios_sid, 'New calc engine scenario run');
		dbms_output.put_line('Test scenario found, reusing as merged.');
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
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			dbms_output.put_line('Test scenario not found.');
			-- Find or create the merged scenario (XXX: move to csr_data_pkg?)
			BEGIN
				dbms_output.put_line('Looking for merged scenario.');
				v_scenario_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Merged scenario');
				dbms_output.put_line('Found, keeping merged scenario.');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					dbms_output.put_line('Not found, creating merged scenario.');
					security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
						security.class_pkg.GetClassId('CSRScenario'), 'Merged scenario', v_scenario_sid);
				
				INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
					SELECT v_scenario_sid, 'Merged scenario', calc_start_dtm, calc_end_dtm, 1, 1, 0
					  FROM csr.customer;
			END;
	END;

	-- add registered users read on the scenario
	dbms_output.put_line('Checking registered users read on the merged scenario.');
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		dbms_output.put_line('Not found, adding registered users read on the merged scenario.');
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	ELSE
		dbms_output.put_line('Registered users read found on the merged scenario.');
	END IF;

	-- Find or create the merged scenario run (XXX: move to csr_data_pkg?)
	BEGIN
		dbms_output.put_line('Looking for merged scenario run.');
		v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Merged scenario run');
		dbms_output.put_line('Found, keeping merged scenario run.');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			dbms_output.put_line('Not found, creating merged scenario run.');
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
				security.class_pkg.GetClassId('CSRScenarioRun'), 'Merged scenario run', v_scenario_run_sid);			
			INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
			VALUES (v_scenario_run_sid, v_scenario_sid, 'Merged scenario run');
	END;
	
	UPDATE csr.scenario
	   SET file_based = 1,
	   	   recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_MERGED,
	   	   auto_update_run_sid = v_scenario_run_sid
	 WHERE scenario_sid = v_scenario_sid;
	
	-- add registered users read on the scenario run
	dbms_output.put_line('Checking registered users read on the merged scenario run.');
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		dbms_output.put_line('Not found, adding registered users read on the merged scenario run.');
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	ELSE
		dbms_output.put_line('Registered users read found on the merged scenario run.');
	END IF;

	UPDATE csr.customer
	   SET merged_scenario_run_sid = v_scenario_run_sid
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
 	 
 	dbms_output.put_line('Adding a recalc job for the merged scenario run.');
	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);
	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Find or create the unmerged scenario (XXX: move to csr_data_pkg?)
	BEGIN
		dbms_output.put_line('Looking for unmerged scenario.');
		v_scenario_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Unmerged scenario');
		dbms_output.put_line('Found, keeping unmerged scenario.');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			dbms_output.put_line('Not found, creating unmerged scenario.');
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
				security.class_pkg.GetClassId('CSRScenario'), 'Unmerged scenario', v_scenario_sid);
				
			INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
				SELECT v_scenario_sid, 'Unmerged scenario', calc_start_dtm, calc_end_dtm, 1, 1, 0
				  FROM csr.customer;
	END;

	-- add registered users read on the scenario
	dbms_output.put_line('Checking registered users read on the unmerged scenario.');
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		dbms_output.put_line('Not found, adding registered users read on the unmerged scenario.');
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	ELSE
		dbms_output.put_line('Registered users read found on the unmerged scenario.');
	END IF;

	-- Find or create the unmerged scenario run (XXX: move to csr_data_pkg?)
	BEGIN
		dbms_output.put_line('Looking for unmerged scenario run.');
		v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Unmerged scenario run');
		dbms_output.put_line('Found, keeping unmerged scenario run.');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			dbms_output.put_line('Not found, creating unmerged scenario run.');
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
				security.class_pkg.GetClassId('CSRScenarioRun'), 'Unmerged scenario run', v_scenario_run_sid);			
			INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
			VALUES (v_scenario_run_sid, v_scenario_sid, 'Unmerged scenario run');
	END;
	
	UPDATE csr.scenario
	   SET file_based = 1,
	   	   auto_update_run_sid = v_scenario_run_sid,
	       recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_UNMERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_UNMERGED
	 WHERE scenario_sid = v_scenario_sid;
	
	-- add registered users read on the scenario run
	dbms_output.put_line('Checking registered users read on the unmerged scenario run.');
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		dbms_output.put_line('Not found, adding registered users read on the unmerged scenario run.');
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	ELSE
		dbms_output.put_line('Registered users read found on the unmerged scenario run.');
	END IF;

 	dbms_output.put_line('Adding a recalc job for the unmerged scenario run.');
	UPDATE csr.customer
	   SET unmerged_scenario_run_sid = v_scenario_run_sid
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
 	 
	csr.csr_data_pkg.LockApp(csr.csr_data_pkg.LOCK_TYPE_CALC);
	BEGIN
		INSERT INTO csr.scenario_auto_run_request (scenario_sid)
		VALUES (v_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/
