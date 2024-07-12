PROMPT Enter host, scenario name
DECLARE
    v_app_sid 						security.security_pkg.T_SID_ID;
    v_scenario_sid					security.security_pkg.T_SID_ID;
    v_scenarios_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1', 86400);
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Enable scenarios first');
	END;

	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid,
		security.class_pkg.GetClassId('CSRScenario'), '&&2 scenario', v_scenario_sid);
		
	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, interval)
		SELECT v_scenario_sid, '&&2', calc_start_dtm, calc_end_dtm, 'y'
		  FROM csr.customer;

	INSERT INTO csr.scenario_man_run_request (scenario_man_run_request_id, scenario_sid, description, unmerged)
	VALUES (csr.scenario_man_run_req_id_seq.nextval, v_scenario_sid, '&&2', 0);
	
	UPDATE csr.customer 
	   SET scenarios_enabled = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;
/

exit
