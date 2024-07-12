
-- ADD TASK STATUSES, TASK PERIOD STATUSES AND ROLES
DECLARE
	v_approver_role_sid		security_pkg.T_SID_ID;
	v_admin_role_sid		security_pkg.T_SID_ID;
	v_group_sid				security_pkg.T_SID_ID;
	v_task_status_id		task_status.task_status_id%TYPE;
	v_red					NUMBER(10);
	v_amber					NUMBER(10);
	v_green					NUMBER(10);
	v_blue					NUMBER(10);
BEGIN
	user_pkg.logonadmin('&&1');
	--
	-- Useful colours
	v_red := 255;
	v_amber := 63231;
	v_green := 65280;
	v_blue := 16711680;
	--
	-- Fetch role sids
	SELECT role_sid INTO v_approver_role_sid FROM csr.role WHERE name = 'Initiative approver';
	SELECT role_sid INTO v_admin_role_sid FROM csr.role WHERE name = 'Initiative administrator';
	--
	-- TASK STATUS
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Created', 1, 0, 0, 0, 0, 0, 1, v_blue)
		RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	--
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Submitted', 0, 0, 0, 0, 0, 0, 0, v_amber)
	  	RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_approver_role_sid)
	;	
	--
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Approved', 0, 1, 0, 0, 0, 0, 1, v_green)
	  	RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	--
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Rejected', 0, 0, 1, 0, 0, 0, 1, v_red)
	  	RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	--
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Terminated', 0, 0, 0, 0, 0, 1, 0, v_red)
	  	RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	--
	INSERT INTO task_status (task_status_id, app_sid, label, is_default, is_live, is_rejected, is_stopped, means_completed, means_terminated, belongs_to_owner, colour) 
	  VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Finished', 0, 0, 0, 0, 1, 0, 0, v_green)
	  	RETURNING task_status_id INTO v_task_status_id
	;
	INSERT INTO task_status_role (task_status_id, role_sid)
		VALUES (v_task_status_id, v_admin_role_sid)
	;
	
	--
	-- TASK PERIOD STATUS
	INSERT INTO task_period_status (task_period_status_id, app_sid, label, colour) 
		VALUES (task_period_status_id_seq.nextval, security_pkg.GetAPP, 'Behind schedule', v_red);
	
	INSERT INTO task_period_status (task_period_status_id, app_sid, label, colour) 
		VALUES (task_period_status_id_seq.nextval, security_pkg.GetAPP, 'On schedule', v_amber);
		
	INSERT INTO task_period_status (task_period_status_id, app_sid, label, colour) 
		VALUES (task_period_status_id_seq.nextval, security_pkg.GetAPP, 'Ahead on schedule', v_green);
	
	INSERT INTO task_period_status (task_period_status_id, app_sid, label, colour, means_task_status_id) 
		SELECT task_period_status_id_seq.nextval, security_pkg.GetAPP, 'Finished', v_green, task_status_id
		  FROM task_status
		 WHERE app_sid = security_pkg.GetAPP
		   AND label = 'Finished';
		
	INSERT INTO task_period_status (task_period_status_id, app_sid, label, colour, means_task_status_id) 
		SELECT task_period_status_id_seq.nextval, security_pkg.GetAPP, 'Terminated', v_red, task_status_id
		  FROM task_status
		 WHERE app_sid = security_pkg.GetAPP
		   AND label = 'Terminated';
	--
	--
	
	-- Insert trnasitions
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 1, 'Save',
	 		/* FROM: */ NULL,
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Created')
	 	);
	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 2, 'Save',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Created'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Created')
	 	);
	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 3, 'Submit',
	 		/* FROM: */ NULL,
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Submitted')
	 	);
	 	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 4, 'Submit',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Created'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Submitted')
	 	);
	 	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 5, 'Reject',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Submitted'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Rejected')
	 	);	

	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 6, 'Re-submit',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Rejected'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Submitted')
	 	);
	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 7, 'Approve',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Submitted'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Approved')
	 	);
	 	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 8, 'Update',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Approved'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Approved')
	 	);	

	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 9, 'Terminate',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Approved'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Terminated')
	 	);
	
	INSERT INTO task_status_transition (task_status_transition_id, pos, button_text, from_task_status_id, to_task_status_id)
	 	VALUES (task_status_transition_id_seq.NEXTVAL, 10, 'Finish',
	 		/* FROM: */ (SELECT task_status_id FROM task_status WHERE label = 'Approved'),
	 		/* TO:   */ (SELECT task_status_id FROM task_status WHERE label = 'Finished')
	 	); 	
	
	-- Allow any registered user to make any transition
	v_group_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'Groups/RegisteredUsers');
	
	FOR r IN (
		SELECT task_status_transition_id
		  FROM task_status_transition
		 WHERE app_sid = security_pkg.GetAPP
	) LOOP
		BEGIN
			INSERT INTO allow_transition (task_status_transition_id, user_or_group_sid)
				VALUES (r.task_status_transition_id, v_group_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Add the alert tpyes to the correct transitions
	-- ...
	UPDATE task_status_transition
	   SET alert_type_id = 2014 -- Submitted
	 WHERE to_task_status_id = (
	 	SELECT task_status_id
	 	  FROM task_status
	 	 WHERE label = 'Submitted'
	);
	
	UPDATE task_status_transition
	   SET alert_type_id = 2015 -- Rejected
	 WHERE to_task_status_id = (
	 	SELECT task_status_id
	 	  FROM task_status
	 	 WHERE label = 'Rejected'
	);
	
	UPDATE task_status_transition
	   SET alert_type_id = 2016 -- Approved
	 WHERE to_task_status_id = (
	 	SELECT task_status_id
	 	  FROM task_status
	 	 WHERE label = 'Approved'
	);
END;
/

-- INDICATOR TEMPLATES
BEGIN
	user_pkg.logonadmin('&&1');
	--
	-- indicator templates
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'proposed_sav', 'Proposed cost saving', 'Cost saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'usd'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'proposed_sav_ongoing', 'Monthly on-going cost saving', 'Monthly on-going cost saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'usd'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'total_spend', 'Total spend', 'Total spend', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'usd'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'electricity', 'Electricity saved', 'Electricity', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'kwh'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'electricity_saving', 'Proposed electricity saving', 'Electricity: Saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'kwh'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'electricity_ongoing', 'Monthly on-going electricity saving', 'Electricity: Monthly on-going saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'kwh'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
	--
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'paper', 'Paper saved', 'Paper', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'paper_saving', 'Proposed paper saving', 'Paper: Saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'paper_ongoing', 'Monthly on-going paper saving', 'Paper: Monthly on-going saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
	--
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'travel', 'Travel saved', 'Travel', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'miles'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'travel_saving', 'Proposed travel saving', 'Travel: Saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'miles'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'travel_ongoing', 'Monthly on-going travel saving', 'Travel: Monthly on-going saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'miles'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
	--
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'waste', 'Waste saved', 'Waste', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'waste_saving', 'Proposed waste saving', 'Waste: Saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'waste_ongoing', 'Monthly on-going waste saving', 'Waste: Monthly on-going distance saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'tonnes'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
	--
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'water', 'Water saved', 'Water', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'm3'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE
	) VALUES (ind_template_id_seq.nextval, 'water_saving', 'Proposed water saving', 'Water: Saving during the period of the initiative (start to end date)', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'gallons'), 0, '#,##0', 1, NULL, 1, 'SUM')
		;
	--
	INSERT INTO ind_template (
		IND_TEMPLATE_ID, NAME, DESCRIPTION, INPUT_LABEL, APP_SID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, MEASURE_SID, SCALE, FORMAT_MASK, TARGET_DIRECTION, INFO_XML, DIVISIBILITY, AGGREGATE, IS_ONGOING, PER_PERIOD_DURATION
	) VALUES (ind_template_id_seq.nextval, 'water_ongoing', 'Monthly on-going water saving', 'Water: Monthly on-going distance saving after the initiative finishes', security_pkg.GetAPP, 0, 1, 1, (SELECT measure_sid FROM csr.measure WHERE LOWER(name) = 'gallons'), 0, '#,##0', 1, NULL, 1, 'SUM', 1, 1)
		;
END;
/


-----------------

DECLARE
	v_tag_group_id				tag_group.tag_group_id%TYPE;
	v_energy_project_sid 		security_pkg.T_SID_ID;
	v_waste_project_sid 		security_pkg.T_SID_ID;
	v_water_project_sid 		security_pkg.T_SID_ID;
	v_paper_project_sid 		security_pkg.T_SID_ID;
	v_travel_project_sid 		security_pkg.T_SID_ID;
	v_tag_id					tag.tag_id%TYPE;
	v_task_status_id			task_status.task_status_id%TYPE;
	v_task_period_status_id		task_period_status.task_period_status_id%TYPE;
	v_ind_template_id			ind_template.ind_template_id%TYPE;
BEGIN
	--
	user_pkg.logonadmin('&&1');
    --
    --
	-- ********************************************************************************************
	-- ********************************************************************************************
	--
	--	PROJECTS SETUP
	--
	-- ********************************************************************************************
	-- ********************************************************************************************
	--
	-- Create projects
	project_pkg.CreateProject(security_pkg.GetACT, security_pkg.GetAPP, 'Energy', DATE '2011-04-01', 12, 3, '<fields><field id="description" name="description" description="Description" visibility="public" /></fields>', '<fields/>', v_energy_project_sid);
	project_pkg.CreateProject(security_pkg.GetACT, security_pkg.GetAPP, 'Waste', DATE '2011-04-01', 12, 3, '<fields><field id="description" name="description" description="Description" visibility="public" /></fields>', '<fields/>', v_waste_project_sid);
	project_pkg.CreateProject(security_pkg.GetACT, security_pkg.GetAPP, 'Water', DATE '2011-04-01', 12, 3, '<fields><field id="description" name="description" description="Description" visibility="public" /></fields>', '<fields/>', v_water_project_sid);
	project_pkg.CreateProject(security_pkg.GetACT, security_pkg.GetAPP, 'Paper', DATE '2011-04-01', 12, 3, '<fields><field id="description" name="description" description="Description" visibility="public" /></fields>', '<fields/>', v_paper_project_sid);
	project_pkg.CreateProject(security_pkg.GetACT, security_pkg.GetAPP, 'Travel', DATE '2011-04-01', 12, 3, '<fields><field id="description" name="description" description="Description" visibility="public" /></fields>', '<fields/>', v_travel_project_sid);
	--
	-- Apply project settings
	UPDATE project 
	  SET pos_group = 1,
	  	  is_initiatives = 1,
	  	  ongoing_end_dtm = TO_DATE('2016-01-01', 'YYYY-MM-DD')
	WHERE project_sid IN (
		v_energy_project_sid, 
		v_waste_project_sid, 
		v_water_project_sid, 
		v_paper_project_sid, 
		v_travel_project_sid
	);
	--
	--
	-- ICONS
	UPDATE project SET icon = 'energy_bulb' WHERE project_sid = v_energy_project_sid;
	UPDATE project SET icon = 'waste_bin' WHERE project_sid = v_waste_project_sid;
	UPDATE project SET icon = 'water_cup' WHERE project_sid = v_water_project_sid;
	UPDATE project SET icon = 'paper_stack' WHERE project_sid = v_paper_project_sid;
	UPDATE project SET icon = 'travel_plane' WHERE project_sid = v_travel_project_sid;
	--
	-- Associate sub types with projects
	-- ENERGY
	INSERT INTO tag_group (tag_group_id, app_sid, name, label, multi_select, mandatory, render_as, show_in_filter) VALUES (tag_group_id_seq.nextval, security_pkg.GetAPP, 'initiative_sub_type', 'What type of initiative is it?', 0, 0, 'X', 0) RETURNING tag_group_id INTO v_tag_group_id;
	INSERT INTO project_tag_group (tag_group_id, project_sid, pos) VALUES (v_tag_group_id, v_energy_project_sid, 0);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'PC Monitor switch off') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 1, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Switch off lights') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 2, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Remove desk fan') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 3, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Remove portable heater') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 4, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Unplug chargers') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 5, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Switch printers to powersave mode') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 6, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Switch faxes to powersave mode') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 7, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Switch photocopiers to powersave mode') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 8, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Other') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 9, 1);
	-- WASTE
	INSERT INTO tag_group (tag_group_id, app_sid, name, label, multi_select, mandatory, render_as, show_in_filter) VALUES (tag_group_id_seq.nextval, security_pkg.GetAPP, 'initiative_sub_type', 'What type of initiative is it? (Please select from the list below)', 0, 0, 'X', 0) RETURNING tag_group_id INTO v_tag_group_id;
	INSERT INTO project_tag_group (tag_group_id, project_sid, pos) VALUES (v_tag_group_id, v_waste_project_sid, 0);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Toner recycling') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 1, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Mobile phone recycling') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 2, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Starbuck cup reduction') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 3, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Stop unwanted junk mail') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 4, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Stop unwanted junk faxes') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 5, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Re-use Starbucks drinks trays') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 6, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Other') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 7, 1);
	-- WATER
	INSERT INTO tag_group (tag_group_id, app_sid, name, label, multi_select, mandatory, render_as, show_in_filter) VALUES (tag_group_id_seq.nextval, security_pkg.GetAPP, 'initiative_sub_type', 'What type of initiative is it? (Please select from the list below)', 0, 0, 'X', 0) RETURNING tag_group_id INTO v_tag_group_id;
	INSERT INTO project_tag_group (tag_group_id, project_sid, pos) VALUES (v_tag_group_id, v_water_project_sid, 0);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Stop leaks') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 1, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Other') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 2, 1);
	-- PAPER
	INSERT INTO tag_group (tag_group_id, app_sid, name, label, multi_select, mandatory, render_as, show_in_filter) VALUES (tag_group_id_seq.nextval, security_pkg.GetAPP, 'initiative_sub_type', 'What type of initiative is it? (Please select from the list below)', 0, 0, 'X', 0) RETURNING tag_group_id INTO v_tag_group_id;
	INSERT INTO project_tag_group (tag_group_id, project_sid, pos) VALUES (v_tag_group_id, v_paper_project_sid, 0);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Double sided printing') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 1, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Paper friendly meetings') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 2, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Other') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 3, 1);
	-- TRAVEL
	INSERT INTO tag_group (tag_group_id, app_sid, name, label, multi_select, mandatory, render_as, show_in_filter) VALUES (tag_group_id_seq.nextval, security_pkg.GetAPP, 'initiative_sub_type', 'What type of initiative is it? (Please select from the list below)', 0, 0, 'X', 0) RETURNING tag_group_id INTO v_tag_group_id;
	INSERT INTO project_tag_group (tag_group_id, project_sid, pos) VALUES (v_tag_group_id, v_travel_project_sid, 0);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Video-conference instead of flying') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 1, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Train not plane') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 2, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Meeting centre rather than flying') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 3, 1);
	INSERT INTO tag (tag_id, tag) VALUES (tag_id_seq.nextval, 'Other') RETURNING tag_id INTO v_tag_id;
	INSERT INTO tag_group_member (tag_group_id, tag_id, pos, is_visible) VALUES (v_tag_group_id, v_tag_id, 4, 1);
	--
	-- TASK STATUSES
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Created';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Submitted';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Approved';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Rejected';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Terminated';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	SELECT task_status_id INTO v_task_status_id FROM task_status WHERE app_sid = security_pkg.GetAPP AND label = 'Finished';
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_energy_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_waste_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_water_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_paper_project_sid, v_task_status_id);
	INSERT INTO project_task_status (project_sid, task_status_id) VALUES (v_travel_project_sid, v_task_status_id);
	--
	-- TASK PERIOD STATUSES
	SELECT task_period_status_id INTO v_task_period_status_id FROM task_period_status WHERE app_sid = security_pkg.GetAPP AND label = 'Behind schedule';
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_energy_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_waste_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_water_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_paper_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_travel_project_sid, v_task_period_status_id);
	--
	SELECT task_period_status_id INTO v_task_period_status_id FROM task_period_status WHERE app_sid = security_pkg.GetAPP AND label = 'On schedule';
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_energy_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_waste_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_water_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_paper_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_travel_project_sid, v_task_period_status_id);
	--
	SELECT task_period_status_id INTO v_task_period_status_id FROM task_period_status WHERE app_sid = security_pkg.GetAPP AND label = 'Ahead on schedule';
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_energy_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_waste_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_water_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_paper_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_travel_project_sid, v_task_period_status_id);
	--
	SELECT task_period_status_id INTO v_task_period_status_id FROM task_period_status WHERE app_sid = security_pkg.GetAPP AND label = 'Finished';
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_energy_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_waste_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_water_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_paper_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_travel_project_sid, v_task_period_status_id);
	--
	SELECT task_period_status_id INTO v_task_period_status_id FROM task_period_status WHERE app_sid = security_pkg.GetAPP AND label = 'Terminated';
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_energy_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_waste_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_water_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_paper_project_sid, v_task_period_status_id);
	INSERT INTO project_task_period_status (project_sid, task_period_status_id) VALUES (v_travel_project_sid, v_task_period_status_id);
	--
	--
	-- insert pos groups
	--
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_energy_project_sid, 0);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_waste_project_sid, 0);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_water_project_sid, 0);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_paper_project_sid, 0);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_travel_project_sid, 0);
	--
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_energy_project_sid, 100);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_waste_project_sid, 100);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_water_project_sid, 100);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_paper_project_sid, 100);
	INSERT INTO ind_template_group (project_sid, pos_group) VALUES (v_travel_project_sid, 100);
	-- 
	-- associate indicator templates
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'proposed_sav';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 100, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 100, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 100, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 100, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 100, 100, 1, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'proposed_sav_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 101, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 101, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 101, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 101, 100, 1, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 101, 100, 1, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'total_spend';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 150, 100, 1, 0, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 150, 100, 1, 0, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 150, 100, 1, 0, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 150, 100, 1, 0, 0, 2);
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 150, 100, 1, 0, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'electricity';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 0, 0, 0, 1, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'electricity_saving';		
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 1, 0, 0, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'electricity_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_energy_project_sid, v_ind_template_id, 2, 0, 0, 0, 2);
	--
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'paper';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 0, 0, 0, 1, 6);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'paper_saving';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 1, 0, 0, 0, 6);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'paper_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_paper_project_sid, v_ind_template_id, 2, 0, 0, 0, 6);
	--
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'travel';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 0, 0, 0, 1, 2);
	--
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'travel_saving';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 1, 0, 0, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'travel_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_travel_project_sid, v_ind_template_id, 2, 0, 0, 0, 2);
	--
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'waste';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 0, 0, 0, 1, 6);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'waste_saving';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 1, 0, 0, 0, 6);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'waste_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_waste_project_sid, v_ind_template_id, 2, 0, 0, 0, 6);
	--
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'water';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 0, 0, 0, 1, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'water_saving';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 1, 0, 0, 0, 2);
	--
	SELECT ind_template_id
	  INTO v_ind_template_id
	  FROM ind_template
	 WHERE name = 'water_ongoing';
	INSERT INTO project_ind_template (project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, input_dp) VALUES (v_water_project_sid, v_ind_template_id, 2, 0, 0, 0, 2);
END;
/

-- UPDATE TO SAVING RELATIONSHIPS
BEGIN
	--
  user_pkg.logonadmin('&&1');
	--
  UPDATE project_ind_template 
     SET saving_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'electricity_saving') 
   WHERE project_sid = (SELECT project_sid FROM project WHERE name = 'Energy')
     AND ind_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'electricity')
  ;
  
  UPDATE project_ind_template 
     SET saving_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'paper_saving') 
   WHERE project_sid = (SELECT project_sid FROM project WHERE name = 'Paper')
     AND ind_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'paper')
  ;
  
  UPDATE project_ind_template 
     SET saving_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'water_saving') 
   WHERE project_sid = (SELECT project_sid FROM project WHERE name = 'Water')
     AND ind_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'water')
  ;
  
  UPDATE project_ind_template 
     SET saving_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'waste_saving') 
   WHERE project_sid = (SELECT project_sid FROM project WHERE name = 'Waste')
     AND ind_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'waste')
  ;
  
  UPDATE project_ind_template 
     SET saving_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'travel_saving') 
   WHERE project_sid = (SELECT project_sid FROM project WHERE name = 'Travel')
     AND ind_template_id = (SELECT ind_template_id FROM ind_template WHERE name = 'travel')
  ;
END;
/

-- Simple periodic report template
BEGIN
	
	INSERT INTO periodic_report_template (report_template_id, description, template_xml)
		VALUES (report_template_id_seq.NEXTVAL, 'Forecast values', 
		'<sheet>			
			<report leaf="true" interval="1" type="forecast">
				<column name="TaskName" label="Initiative name"/>
				<column name="StartDtm" label="Initiative start date"/>
				<column name="EndDtm" label="Initiative end date"/>
				<values/>
			</report>
		</sheet>');
	
	INSERT INTO periodic_report_template (report_template_id, description, template_xml)
		VALUES (report_template_id_seq.NEXTVAL, 'Actual values', 
		'<sheet>			
			<report leaf="true" interval="1" type="actual">
				<column name="TaskName" label="Initiative name"/>
				<column name="StartDtm" label="Initiative start date"/>
				<column name="EndDtm" label="Initiative end date"/>
				<values/>
			</report>
		</sheet>');
END;
/

--COMMIT;
