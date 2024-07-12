DECLARE
    v_app_sid 						security.security_pkg.T_SID_ID;
    v_scenarios_sid					security.security_pkg.T_SID_ID;
    v_scenario_sid					security.security_pkg.T_SID_ID;
    v_scenario_run_sid 				security.security_pkg.T_SID_ID;
BEGIN
    security.user_pkg.logonadmin('&&1', 86400);
    v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- Find or create the merged cube test (XXX: move to csr_data_pkg?)
	BEGIN
		v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Scenarios object not found -- run EnableScenarios.sql first');
	END;
	
	BEGIN
		v_scenario_run_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_scenarios_sid, 'New calc engine scenario run');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_scenario_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_scenarios_sid, 'New calc engine scenario');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), v_scenarios_sid,
						security.class_pkg.GetClassId('CSRScenario'), 'New calc engine scenario', v_scenario_sid);
						
					INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
						SELECT v_scenario_sid, 'New calc engine scenario', calc_start_dtm, calc_end_dtm, 1, 4, 0
						  FROM csr.customer;
			END;
	
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
	END;
 	 
	INSERT INTO csr.scenario_auto_run_request (scenario_sid, full_recompute)
		SELECT scenario_sid, 1
		  FROM csr.scenario_run 
		 WHERE scenario_run_sid = v_scenario_run_sid;
END;
/

exit
