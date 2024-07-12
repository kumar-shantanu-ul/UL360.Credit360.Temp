CREATE OR REPLACE PACKAGE BODY ACTIONS.scenario_pkg
IS

PROCEDURE GetStatusFilterList(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT f.scenario_sid, f.rule_id, r.description, 0 processing -- TODO: fix display
		  FROM csr.scenario_rule r, scenario_filter f
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.scenario_sid = f.scenario_sid
		   AND r.rule_id = f.rule_id
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.scenario_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	out_details						OUT	security_pkg.T_OUTPUT_CUR,
	out_statuses					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading filter with scenario sid '||in_scenario_sid);
	END IF;
	
	OPEN out_details FOR
		SELECT f.scenario_sid, f.rule_id, r.description
		  FROM csr.scenario_rule r, scenario_filter f
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.scenario_sid = f.scenario_sid
		   AND r.rule_id = f.rule_id
		   AND f.scenario_sid = in_scenario_sid
		   AND r.rule_id = in_rule_id;
		   
	OPEN out_statuses FOR
		SELECT f.task_status_id, ts.label
		  FROM scenario_filter_status f, task_status ts
		 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ts.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND f.scenario_sid = in_scenario_sid
		   AND f.rule_id = in_rule_id
		   AND ts.task_status_id = f.task_status_id;
END;

PROCEDURE SaveStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	in_description					IN	csr.scenario.description%TYPE,
	in_status_ids					IN	security_pkg.T_SID_IDS
)
As
	v_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveStatusFilter(
		in_scenario_sid,
		in_rule_id,
		in_description,
		in_status_ids,
		v_cur
	);
END;

PROCEDURE SaveStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	in_description					IN	csr.scenario.description%TYPE,
	in_status_ids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_scenario_sid					csr.scenario.scenario_sid%TYPE;
	v_rule_id						csr.scenario_rule.rule_id%TYPE;
	v_parent_sid					security_pkg.T_SID_ID;
	v_empty_sids					security_pkg.T_SID_IDS;
	t_status_ids					security.T_SID_TABLE;
	v_merged_run_sid				security_pkg.T_SID_ID;
BEGIN
	
	v_parent_sid := security.securableobject_pkg.GetSIDFromPath(
		SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Scenarios');
	
	IF in_scenario_sid IS NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_parent_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving filter scenario with parent sid '||v_parent_sid);
		END IF;
	ELSE
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving filter with scenario sid '||in_scenario_sid);
		END IF;
	END IF;
	
	-- Create a scenario to contain the rule
	csr.scenario_pkg.SaveScenario(
		in_parent_sid				=> v_parent_sid,		-- Parent sid (securuty tree)
		in_scenario_sid				=> in_scenario_sid, 	-- existing scenario sid (or null for a new scenario)
		in_description				=> in_description, 		-- Description text
		in_indicators				=> v_empty_sids, 		-- Indicators (always empty in this case)
		in_regions					=> v_empty_sids,		-- Regions (always empty in this case)
		in_start_dtm				=> date '1980-01-01',	-- Start date (but arg can't be null)
		in_end_dtm					=> NULL,				-- End date (not used)
		in_period_set_id			=> 1,					-- Interval (but arg can't be null)
		in_period_interval_id		=> 1,
		in_file_based				=> 0,					-- Historically would have been 0, though the current default is 1.
		out_scenario_sid			=> v_scenario_sid
	);
	
	-- Save the rule that will do the status filtering
	csr.scenario_pkg.SaveRule(
		v_scenario_sid,
		in_rule_id,
		in_description,
		3, 							-- Rule type, initiatives ind filter rule
		0,							-- Amount (not used but arg can't be null)
		NULL,						-- Measure conversion id (not used)
		date '1980-01-01',			-- Start date (not used but arg can't be null)
		NULL,						-- End dtm (not used)
		v_empty_sids,				-- Indicators (not used)
		v_empty_sids,				-- Regions (not used)
		v_rule_id
	);
	 
	
	-- Create the scenario runs and set the 
	-- scenario's auto update run sids if required
	SELECT auto_update_run_sid
	  INTO v_merged_run_sid
	  FROM csr.scenario s
	 WHERE scenario_sid = v_scenario_sid
	   AND recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED;
	
	IF v_merged_run_sid IS NULL THEN
		csr.scenario_run_pkg.CreateScenarioRun(
			v_scenario_sid,
			in_description || ' (merged)',
			v_merged_run_sid
		);


		UPDATE csr.scenario
		   SET auto_update_run_sid = v_merged_run_sid,
		       recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
		       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_MERGED
		 WHERE scenario_sid = v_scenario_sid;
	END IF;
	
	-- Update the actions scenario filter tables
	BEGIN
		INSERT INTO scenario_filter
			(scenario_sid, rule_id)
		  VALUES (v_scenario_sid, v_rule_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Scenaro filter already exists, 
				  -- nothing to update in this table
	END;
	
	t_status_ids := security_pkg.SidArrayToTable(in_status_ids);
	
	DELETE FROM scenario_filter_status
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_sid = v_scenario_sid
	   AND rule_id = v_rule_id;
	
	INSERT INTO scenario_filter_status
		(scenario_sid, rule_id, task_status_id)
	  SELECT v_scenario_sid, v_rule_id, column_value
	    FROM TABLE(t_status_ids);	

	-- Add a run request for this scenario
	BEGIN
		INSERT INTO csr.scenario_auto_run_request
			(scenario_sid)
		  VALUES (v_scenario_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- This job already exists 
	END;
	  
	OPEN out_cur FOR
		SELECT scenario_sid, rule_id
		  FROM scenario_filter
		 WHERE scenario_sid = v_scenario_sid
		   AND rule_id = v_rule_id;
END;

PROCEDURE GetStatusFilterInds (
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading filter with scenario sid '||in_scenario_sid);
	END IF;
	
	-- Select a list of indicators whose values will be removed from the data set
	-- That is in this case any ind template indicator instance that is associated
	-- with an initiative not in one of the desired statuses
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM (
		  	SELECT i.ind_sid
		  	  FROM task_ind_template_instance i
		  	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  	 MINUS
		    SELECT i.ind_sid
		      FROM task t, task_ind_template_instance i, scenario_filter_status s
		     WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		       AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		       AND t.task_sid = i.task_sid
		       AND t.task_status_id = s.task_status_id
		       AND s.scenario_sid = in_scenario_sid
		       AND s.rule_id = in_rule_id
		  );
END;

PROCEDURE OnTaskStatusChanged(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
	v_from_status_id			task_status.task_status_id%TYPE;
	v_to_status_id				task_status.task_status_id%TYPE;
BEGIN
	SELECT from_task_status_id, to_task_Status_id
	  INTO v_from_status_id, v_to_status_id
	  FROM task_status_transition tr, task t
	 WHERE t.task_sid = in_task_sid
	   AND tr.task_status_transition_id = t.last_transition_id;
	   
	OnTaskStatusChanged(in_task_sid, v_from_status_id, v_to_status_id);	
END;

PROCEDURE OnTaskStatusChanged(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_from_status_id			task_status.task_status_id%TYPE,
	in_to_status_id				task_status.task_status_id%TYPE
)
AS
BEGIN
	-- Insert run requests for any scenarios 
	-- related to the from/to task status ids
	BEGIN
		INSERT INTO csr.scenario_auto_run_request
			(scenario_sid)
		  SELECT DISTINCT scenario_sid
		    FROM scenario_filter_status
		   WHERE task_status_id IN (
		 	  in_from_status_id, in_to_status_id
		   );
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE DeleteStatusFilter (
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE
)
AS
BEGIN
	-- At the moment there's one scenario per filter 
	-- set so just delete the entire scenario
	securableobject_pkg.DeleteSO(security_pkg.GetACT, in_scenario_sid);
END;

PROCEDURE GetFilterableStatuses (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
			ts.task_status_id, ts.label, ts.note, 
			ts.is_default, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts. means_terminated, ts.belongs_to_owner
		  FROM task_status ts
		 WHERE ts.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ts.show_in_filter = 1
		  	ORDER BY task_status_id
		;
END;

END scenario_pkg;
/
