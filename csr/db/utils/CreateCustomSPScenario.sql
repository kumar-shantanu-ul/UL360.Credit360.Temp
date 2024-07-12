-- Creates a custom fetch SP scenario
--
-- Run @enablescenarios first
--
-- Full scenarios are a paid extra. To enable just the merged cube, run
-- @enablescenarios but then remove permissions on
-- Menu/analysis/csr_scenario_scenario and wwwroot/csr/site/scenario
-- (Scenarios object needs permissions though)
PROMPT Enter host, scenario name and custom fetch sp
DEFINE host='&&1'
DEFINE scenario='&&2'
DEFINE data_source_sp='&&3'
DEFINE data_source_sp_args='&&4'

DECLARE
    v_app_sid 						security.security_pkg.T_SID_ID;
    v_scenario_sid					security.security_pkg.T_SID_ID;
    v_scenario_run_sid 				security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_acl_count						NUMBER;
BEGIN
    security.user_pkg.logonadmin('&&host', 86400);
    v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_reg_users_sid := security.securableObject_pkg.getSidFromPath(
		SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');

	-- Find or create the scenario (XXX: move to csr_data_pkg?)
	BEGIN
		v_scenario_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '&&scenario');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
				security.class_pkg.GetClassId('CSRScenario'), '&&scenario', v_scenario_sid);
				
			INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, interval)
				SELECT v_scenario_sid, '&&scenario', calc_start_dtm, calc_end_dtm, 'y'
				  FROM csr.customer;
	END;

	-- add registered users read on the scenario
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	-- Find or create the scenario run (XXX: move to csr_data_pkg?)
	BEGIN
		v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '&&scenario run');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
				security.class_pkg.GetClassId('CSRScenarioRun'), '&&scenario run', v_scenario_run_sid);			
			INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
			VALUES (v_scenario_run_sid, v_scenario_sid, '&&scenario run');
	END;
	
	UPDATE csr.scenario
	   SET file_based = 1,
	   	   recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_CUSTOM_FETCH_SP,
	   	   data_source_sp = '&&data_source_sp',
		   data_source_sp_args = '&&data_source_sp_args',
	   	   auto_update_run_sid = v_scenario_run_sid
	 WHERE scenario_sid = v_scenario_sid;
	
	-- add registered users read on the scenario run
	SELECT COUNT(*)
	  INTO v_acl_count
	  FROM security.acl 
	 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid)
	   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW AND sid_id = v_reg_users_sid
	   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
	IF v_acl_count = 0 THEN
		security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), security.acl_pkg.GetDACLIDForSID(v_scenario_run_sid),
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;
 	 
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

exit
