/*
DROP TABLE IDMAP;

CREATE GLOBAL TEMPORARY TABLE IDMAP
(
	NAME				VARCHAR2(256)	NOT NULL,
	OLD_ID				NUMBER(10, 0)	NOT NULL,
	NEW_ID				NUMBER(10, 0)	NULL
)
ON COMMIT DELETE ROWS;
*/
SET SERVEROUTPUT ON
DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_from_app			security_pkg.T_SID_ID;
	v_to_app			security_pkg.T_SID_ID;
	v_project_sid		security_pkg.T_SID_ID;
	v_role_sid			security_pkg.T_SID_ID;
	v_measure_sid		security_pkg.T_SID_ID;
	v_csr_group_class	security_pkg.T_CLASS_ID;
	v_csr_role_class	security_pkg.T_CLASS_ID;
	v_test				NUMBER(10);
BEGIN
	user_pkg.logonadmin(NULL);
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act);
	v_from_app := securableobject_pkg.GetSIDFromPath(v_act, security_pkg.SID_ROOT, '//aspen/applications/&&host_from');
	v_to_app := securableobject_pkg.GetSIDFromPath(v_act, security_pkg.SID_ROOT, '//aspen/applications/&&host_to');

	-- CUSTOMER OPTIONS
	INSERT INTO script (app_sid, script_id, script) (
		SELECT v_to_app, script_id, script
		  FROM script
		 WHERE app_sid = v_from_app
	);

	/*
	DELETE FROM customer_options WHERE app_sid = v_to_app;
	
	INSERT INTO customer_options (
		app_sid, show_regions, restrict_by_region, browse_shows_children, aggregate_task_tree, 
		show_weightings, show_action_type, greyout_unassoc_tasks, allow_perf_override, 
		allow_parent_override, use_actions_v2, show_task_period_pct, default_value_script_id, action_grid_path, 
		aggr_action_grid_path, initiative_end_dtm, region_picker_config, initiative_name_gen_proc, initiative_reminder_alerts, 
		initiative_hide_ongoing_radio, initiative_new_days, initiatives_host, gantt_period_colour, region_level, 
		country_level, property_level, use_standard_region_picker
	) (
		SELECT 
			v_to_app, show_regions, restrict_by_region, browse_shows_children, aggregate_task_tree, 
			show_weightings, show_action_type, greyout_unassoc_tasks, allow_perf_override, 
			allow_parent_override, use_actions_v2, show_task_period_pct, default_value_script_id, action_grid_path, 
			aggr_action_grid_path, initiative_end_dtm, region_picker_config, initiative_name_gen_proc, initiative_reminder_alerts, 
			initiative_hide_ongoing_radio, initiative_new_days, initiatives_host, gantt_period_colour, region_level, 
			country_level, property_level, use_standard_region_picker
		  FROM customer_options
		 WHERE app_sid = v_from_app
	);
	*/
	
	-- PROJECTS
	FOR r IN (
		SELECT project_sid, name, max_period_duration, start_dtm, end_dtm, task_fields_xml, 
			task_period_fields_xml, next_id, ind_sid, icon, abbreviation, pos_group, pos, ongoing_end_dtm, category_level
		  FROM project
		 WHERE app_sid = v_from_app
		   AND is_initiatives = 1
	) LOOP
		
		dbms_output.put_line(r.name);
		
		security_pkg.SetAPP(v_to_app);
		project_pkg.CreateProject(v_act, v_to_app, r.name, r.start_dtm, MONTHS_BETWEEN(r.end_dtm, r.start_dtm), 
			r.max_period_duration, r.task_fields_xml, r.task_period_fields_xml, v_project_sid);
		security_pkg.SetAPP(NULL);
		
		UPDATE project
		   SET pos = r.pos,
		   	   pos_group = r.pos_group,
		   	   icon = r.icon,
		   	   ongoing_end_dtm = r.ongoing_end_dtm, 
		   	   category_level = r.category_level,
		   	   is_initiatives = 1
		 WHERE app_sid = v_to_app
		   AND project_sid = v_project_sid;
		 
		INSERT INTO idmap (name, old_id, new_id) VALUES('project', r.project_sid, v_project_sid);
	END LOOP;
	
	-- TAG GROUPS
	FOR r IN (
		SELECT tag_group_id, name, multi_select, mandatory, render_as, show_in_filter, label
		  FROM tag_group
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO tag_group (
			app_sid, tag_group_id, name, multi_select, mandatory, render_as, show_in_filter, label
		) VALUES (
			v_to_app, tag_group_id_seq.NEXTVAL, r.name, r.multi_select, r.mandatory, r.render_as, r.show_in_filter, r.label
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('tag_group', r.tag_group_id, tag_group_id_seq.CURRVAL);
	END LOOP;
	
	-- PROJECT TAG GROUP
	FOR r IN (
		SELECT tag_group_id, project_sid, pos
		  FROM project_tag_group
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO project_tag_group (
			app_sid, tag_group_id, project_sid, pos
		) (
			SELECT v_to_app, tg.new_id, pr.new_id, r.pos
			  FROM idmap tg, idmap pr
			 WHERE tg.name = 'tag_group'
			   AND tg.old_id = r.tag_group_id
			   AND pr.name = 'project'
			   AND pr.old_id = r.project_sid
		);
	END LOOP;
	
	-- TAG
	FOR r IN (
		SELECT tag_id, tag, explanation
		  FROM tag
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO tag (
			app_sid, tag_id, tag, explanation
		) VALUES (
			v_to_app, tag_id_seq.NEXTVAL, r.tag, r.explanation
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('tag', r.tag_id, tag_id_seq.CURRVAL);
	END LOOP;
	
	-- TAG GROUP MEMBER
	FOR r IN (
		SELECT tag_group_id, tag_id, pos, is_visible
		  FROM tag_group_member
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO tag_group_member (
			app_sid, tag_group_id, tag_id, pos, is_visible
		) (
			SELECT v_to_app, tg.new_id, t.new_id, r.pos, r.is_visible
			  FROM idmap tg, idmap t
			 WHERE tg.name = 'tag_group'
			   AND tg.old_id = r.tag_group_id
			   AND t.name = 'tag'
			   AND t.old_id = r.tag_id
		);
	END LOOP;

	-- MAP/CREATE CSR ROLES
	FOR r IN (
		SELECT role_sid, name, is_metering, is_property_manager, is_delegation
		  FROM csr.role r
		 WHERE app_sid = v_from_app
		   AND r.role_sid IN (
		 	SELECT role_sid 
		 	  FROM task_status_role
		 	 WHERE app_sid = v_from_app
		 )
	) LOOP
		BEGIN
			SELECT role_sid
			  INTO v_role_sid
			  FROM csr.role
			 WHERE app_sid = v_to_app
			   AND LOWER(name) = LOWER(r.name);
		 EXCEPTION
		 	WHEN NO_DATA_FOUND THEN
		 		security_pkg.SetAPP(v_to_app);
		 		csr.role_pkg.SetRole(v_act, v_to_app, r.name, v_role_sid);
		 		security_pkg.SetAPP(NULL);
		 END;
		 INSERT INTO idmap (name, old_id, new_id) VALUES ('csr_role', r.role_sid, v_role_sid);
	END LOOP;
	
	-- TASK STATUS
	
	-- for dealing with NULL lookups
	INSERT INTO idmap (name, old_id, new_id) VALUES ('task_status', -1, -1);
	
	FOR r IN (
		SELECT task_status_id, label, note, is_default, is_live, is_rejected, is_stopped, 
			means_completed, means_terminated, belongs_to_owner, owner_can_see, colour
		  FROM task_status
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO task_status (
			app_sid, task_status_id, label, note, is_default, is_live, is_rejected, is_stopped, 
			means_completed, means_terminated, belongs_to_owner, owner_can_see, colour
		) VALUES (
			v_to_app, task_status_id_seq.NEXTVAL, r.label, r.note, r.is_default, r.is_live, r.is_rejected, r.is_stopped, 
			r.means_completed, r.means_terminated, r.belongs_to_owner, r.owner_can_see, r.colour
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('task_status', r.task_status_id, task_status_id_seq.CURRVAL);
	END LOOP;
	
	-- PROJECT TASK STATUS
	FOR r IN (
		SELECT project_sid, task_status_id
		  FROM project_task_status
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO project_task_status (
			app_sid, project_sid, task_status_id
		) (
			SELECT v_to_app, pr.new_id, ts.new_id
			  FROM idmap pr, idmap ts
			 WHERE pr.name = 'project'
			   AND pr.old_id = r.project_sid
			   AND ts.name = 'task_status'
			   AND ts.old_id = r.task_status_id
		);
	END LOOP;
	
	-- TASK STATUS ROLE
	FOR r IN (
		SELECT task_status_id, role_sid
		  FROM task_status_role
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO task_status_role (
			app_sid, task_Status_id, role_sid
		) (
			SELECT v_to_app, ts.new_id, rl.new_id
			  FROM idmap ts, idmap rl
			 WHERE ts.name = 'task_status'
			   AND ts.old_id = r.task_status_id
			   AND rl.name = 'csr_role'
			   AND rl.old_id = r.role_sid
		);
	END LOOP;
	
	-- TASK STATUS TRANSITION
	FOR r IN (
		SELECT task_status_transition_id, to_task_status_id, from_task_status_id, 
			alert_type_id, ask_for_comment, save_data, button_text, pos
		  FROM task_status_transition
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO task_status_transition (
			app_sid, task_status_transition_id, to_task_status_id, from_task_status_id, 
			alert_type_id, ask_for_comment, save_data, button_text, pos
		) (
			SELECT v_to_app, task_status_transition_id_seq.NEXTVAL, 
				DECODE(sto.new_id, -1, NULL, sto.new_id),
				DECODE(sfrom.new_id, -1, NULL, sfrom.new_id),
				r.alert_type_id, r.ask_for_comment, r.save_data, r.button_text, r.pos
			  FROM idmap sto, idmap sfrom
			 WHERE sto.name = 'task_status'
			   AND sto.old_id = NVL(r.to_task_status_id, -1)
			   AND sfrom.name = 'task_status'
			   AND sfrom.old_id = NVL(r.from_task_status_id, -1)
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('task_status_transition', r.task_status_transition_id, task_status_transition_id_seq.CURRVAL);
	END LOOP;
	
	-- ALLOW TRANSITION
	-- We're going to port anything that is a CSRUSerGroup or a CSRRole, 
	-- so long as we can find an item with the same name on the new site.
	SELECT class_id
	  INTO v_csr_group_class
	  FROM security.securable_object_class 
	 WHERE class_name = 'CSRUserGroup';
	 
	SELECT class_id
	  INTO v_csr_role_class 
	  FROM security.securable_object_class 
	 WHERE class_name = 'CSRRole';
	
	FOR r IN (
		SELECT task_status_transition_id, user_or_group_sid, so.class_id, so.name
		  FROM allow_transition tr, security.securable_object so
		 WHERE tr.app_sid = v_from_app
		   AND so.sid_id = tr.user_or_group_sid
		   AND so.class_id IN (
		   		v_csr_group_class,
		   		v_csr_role_class
		   )
	) LOOP
		IF r.class_id = v_csr_group_class THEN
			-- Try to map the group sid
			INSERT INTO idmap (name, old_id, new_id) (
				SELECT 'csr_user_group', r.user_or_group_sid, sid_id
				  FROM security.securable_object
				 WHERE application_sid_id = v_to_app
				   AND LOWER(name) = LOWER(r.name)
				   AND class_id = r.class_id
				 MINUS 
				SELECT name, old_id, new_id
				  FROM idmap
				 WHERE name = 'csr_user_group'
				   AND old_id = r.user_or_group_sid
			);
			-- Insert the transition permission
			INSERT INTO allow_transition (
				app_sid, task_status_transition_id, user_or_group_sid
			) (
				SELECT v_to_app, tr.new_id, gp.new_id
				  FROM idmap tr, idmap gp
				 WHERE tr.name = 'task_status_transition'
				   AND tr.old_id = r.task_status_transition_id
				   AND gp.name = 'csr_user_group'
				   AND gp.old_id = r.user_or_group_sid
			);
		END IF;
		
		IF r.class_id = v_csr_role_class THEN
			-- We've already mapped the role sids
			-- Insert the transition permission
			INSERT INTO allow_transition (
				app_sid, task_status_transition_id, user_or_group_sid
			) (
				SELECT v_to_app, tr.new_id, rl.new_id
				  FROM idmap tr, idmap rl
				 WHERE tr.name = 'task_status_transition'
				   AND tr.old_id = r.task_status_transition_id
				   AND rl.name = 'csr_role'
				   AND rl.old_id = r.user_or_group_sid
			);
		END IF;
		
	END LOOP;
	
	-- TASK_PERIOD_STATUS
	FOR r IN (
		SELECT task_period_status_id, label, colour, special_meaning, means_pct_complete, means_task_status_id
		  FROM task_period_status
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO task_period_status (
			app_sid, task_period_status_id, label, colour, special_meaning, means_pct_complete, means_task_status_id
		) (
			SELECT v_to_app, task_period_status_id_seq.NEXTVAL, r.label, r.colour, r.special_meaning, r.means_pct_complete, 
				DECODE(ts.new_id, -1, NULL, ts.new_id)
			  FROM idmap ts
			 WHERE ts.name = 'task_status'
			   AND ts.old_id = NVL(r.means_task_status_id, -1)
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('task_period_status', r.task_period_status_id, task_period_status_id_seq.CURRVAL);
	END LOOP;
	
	-- PROJECT TASK PERIOD STATUS
	FOR r IN (
		SELECT project_sid, task_period_status_id
		  FROM project_task_period_status
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO project_task_period_status (
			app_sid, project_sid, task_period_status_id
		) (
			SELECT v_to_app, pr.new_id, tps.new_id
			  FROM idmap pr, idmap tps
			 WHERE pr.name = 'project'
			   AND pr.old_id = r.project_sid
			   AND tps.name = 'task_period_status'
			   AND tps.old_id = r.task_period_status_id
		);
	END LOOP;
	
	-- PERIODIC ALERT
	/*
	INSERT INTO periodic_alert (
		app_sid, alert_type_id, data_sp, recurrence_xml
	) (
		SELECT v_to_app, alert_type_id, data_sp, recurrence_xml
		  FROM periodic_alert
		 WHERE app_sid = v_from_app
	);
	*/
	
	-- MEASURES
	-- For dealing with null lookups
	INSERT INTO idmap (name, old_id, new_id) VALUES ('csr_measure', -1, -1);
	
	-- Try and map/create some measurs
	FOR r IN (
		SELECT DISTINCT m.measure_sid, m.name, m.description, m.scale, m.format_mask, 
			m.regional_aggregation, m.custom_field, m.option_set_id, pct_ownership_applies, m.divisibility
		  FROM ind_template it, csr.measure m
		 WHERE it.app_sid = v_from_app
		   AND (m.measure_sid = it.measure_sid
		     OR m.measure_sid = it.gas_measure_sid)
	) LOOP
		BEGIN
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM csr.measure
			 WHERE app_sid = v_to_app
			   AND LOWER(name) = LOWER(r.name);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				--v_measure_sid := NULL;
				security_pkg.SetAPP(v_to_app);
				csr.measure_pkg.CreateMeasure(
					v_act, security.securableobject_pkg.GetSIDFromPath(v_act, v_to_app, 'Measures'),
					v_to_app, r.name, r.description, r.scale, r.format_mask, r.custom_field, NULL, 0, r.divisibility, v_measure_sid);
				security_pkg.SetAPP(NULL);
		END;
		INSERT INTO idmap (name, old_id, new_id) VALUES ('csr_measure', r.measure_sid, v_measure_sid);
	END LOOP;
	
	-- IND TEMPLATE
	
	-- For dealing with null lookups
	INSERT INTO idmap (name, old_id, new_id) VALUES ('ind_template', -1, -1);
	
	-- XXX: Calculations _might_ reference invaild indicator sids on ported instance, 
	-- although they are usually configured to reference another ind_template or a lookup key
	FOR r IN (
		SELECT ind_template_id, name, description, input_label, tolerance_type, 
			pct_upper_tolerance, pct_lower_tolerance, measure_sid, scale, format_mask, 
			target_direction, info_xml, divisibility, aggregate,
			per_period_duration, one_off_nth_period, is_ongoing, calculation,
			is_stored_calc, calc_period_duration, is_npv, info_text,
			factor_type_id, gas_measure_sid
		  FROM ind_template
		 WHERE app_sid = v_from_app
		   AND name <> 'action_progress' -- This is created wen actions is enabled
	) LOOP
		INSERT INTO ind_template (
			app_sid, ind_template_id, name, description, input_label, tolerance_type, 
			pct_upper_tolerance, pct_lower_tolerance, measure_sid, scale, format_mask, 
			target_direction, info_xml, divisibility, aggregate,
			per_period_duration, one_off_nth_period, is_ongoing, calculation,
			is_stored_calc, calc_period_duration, is_npv, info_text,
			factor_type_id, gas_measure_sid
		) (
			SELECT v_to_app, ind_template_id_seq.NEXTVAL, r.name, r.description, r.input_label, r.tolerance_type, 
				r.pct_upper_tolerance, r.pct_lower_tolerance, ms.new_id, r.scale, r.format_mask, 
				r.target_direction, r.info_xml, r.divisibility, r.aggregate,
				r.per_period_duration, r.one_off_nth_period, r.is_ongoing, r.calculation,
				r.is_stored_calc, r.calc_period_duration, r.is_npv, r.info_text,
				r.factor_type_id, DECODE(gtms.new_id, -1, NULL, gtms.new_id)
			  FROM idmap ms, idmap gtms
			 WHERE ms.name = 'csr_measure'
			   AND ms.old_id = r.measure_sid
			   AND gtms.name = 'csr_measure'
			   AND gtms.old_id = NVL(r.gas_measure_sid, -1)
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('ind_template', r.ind_template_id, ind_template_id_seq.CURRVAL);
		
	END LOOP;

	-- IND_TEMPLATE_GROUP
	FOR r IN (
		SELECT project_sid, pos_group, is_group_mandatory, label, info_text
		  FROM ind_template_group
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO ind_template_group (
			app_sid, project_sid, pos_group, is_group_mandatory, label, info_text
		) (
			SELECT v_to_app, prj.new_id, r.pos_group, r.is_group_mandatory, r.label, r.info_text
			  FROM idmap prj
			 WHERE prj.name = 'project'
			   AND prj.old_id = r.project_sid
		);
	END LOOP;

	-- PROJECT IND TEMPLATE	
	FOR r IN (
		SELECT project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period, default_value, input_dp, 
			saving_template_id, ongoing_template_id, merged_template_id, display_context
		  FROM project_ind_template
		 WHERE app_sid = v_from_app
	) LOOP
		SELECT new_id
		  INTO v_test
		  FROM idmap
		 WHERE name = 'ind_template'
		   AND old_id = r.ind_template_id;
		
		dbms_output.put_line('Inserting '||r.project_sid||', '||r.ind_template_id||' -> '||v_test);
		INSERT INTO project_ind_template (
			app_sid, project_sid, ind_template_id, pos, pos_group, is_mandatory, update_per_period,
			default_value, input_dp, display_context, saving_template_id, ongoing_template_id, merged_template_id
		) (
			SELECT v_to_app, prj.new_id, itpl.new_id, r.pos, r.pos_group, r.is_mandatory, r.update_per_period, r.default_value, r.input_dp, r.display_context,
				DECODE (sav.new_id, -1, NULL, sav.new_id), 
				DECODE (ong.new_id, -1, NULL, ong.new_id), 
				DECODE (mrg.new_id, -1, NULL, mrg.new_id)
			  FROM idmap prj, idmap itpl, idmap sav, idmap ong, idmap mrg
			 WHERE prj.name = 'project'
			   AND prj.old_id = r.project_sid
			   AND itpl.name = 'ind_template'
			   AND itpl.old_id = r.ind_template_id
			   AND sav.name = 'ind_template'
			   AND sav.old_id = NVL(r.saving_template_id, -1)
			   AND ong.name = 'ind_template'
			   AND ong.old_id = NVL(r.ongoing_template_id, -1)
			   AND mrg.name = 'ind_template'
			   AND mrg.old_id = NVL(r.merged_template_id, -1)
		);
	END LOOP;
	
	-- RECKONER
	/*
	FOR r IN (
		SELECT rec.reckoner_id, rec.label, rec.description, rec.script
		  FROM reckoner rec
		 WHERE rec.reckoner_id IN (
		 	SELECT reckoner_id
		 	  FROM reckoner_tag
		 	 WHERE app_sid = v_from_app
		 )
	) LOOP
		INSERT INTO reckoner (
			reckoner_id, label, description, script
		) VALUES (
			reckoner_id_seq.NEXTVAL, r.label, r.description, r.script
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('reckoner', r.reckoner_id, reckoner_id_seq.CURRVAL);
	END LOOP;
	
	-- RECKONER TAG GROUP
	FOR r IN (
		SELECT project_sid, tag_group_id
		  FROM reckoner_tag_group
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO reckoner_tag_group (
			app_sid, project_sid, tag_group_id
		) (
			SELECT v_to_app, pr.new_id, tg.new_id
			  FROM idmap pr, idmap tg
			 WHERE pr.name = 'project'
			   AND pr.old_id = r.project_sid
			   AND tg.name = 'tag_group'
			   AND tg.old_id = r.tag_group_id
		);
	END LOOP;
	
	-- RECKONER TAG
	FOR r IN (
		SELECT project_sid, tag_group_id, tag_id, reckoner_id
		  FROM reckoner_tag
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO reckoner_tag (
			app_sid, project_sid, tag_group_id, tag_id, reckoner_id
		) (
			SELECT v_to_app, pr.new_id, tg.new_id, tag.new_id, rec.new_id
			  FROM idmap pr, idmap tg, idmap tag, idmap rec
			 WHERE pr.name = 'project'
			   AND pr.old_id = r.project_sid
			   AND tg.name = 'tag_group'
			   AND tg.old_id = r.tag_group_id
			   AND tag.name = 'tag'
			   AND tag.old_id = r.tag_id
			   AND rec.name = 'reckoner'
			   AND rec.old_id = r.reckoner_id
		);
	END LOOP;
	
	-- RECKONER CONST
	FOR r IN (
		SELECT DISTINCT rc.reckoner_const_id, rc.name, rc.label, rc.val
		  FROM reckoner_const rc, reckoner_const_dep rcd, reckoner_tag rtg
		 WHERE rtg.app_sid = v_from_app
		   AND rcd.reckoner_id = rtg.reckoner_id
		   AND rc.reckoner_const_id = rcd.reckoner_const_id
	) LOOP
		INSERT INTO reckoner_const (
			reckoner_const_id, name, label, val
		) VALUES (
			reckoner_const_id_seq.NEXTVAL, r.name, r.label, r.val
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('reckoner_const', r.reckoner_const_id, reckoner_const_id_seq.CURRVAL);
	END LOOP;
	
	-- RECKONER CONST DEP
	FOR r IN (
		SELECT DISTINCT rcd.reckoner_id, rcd.reckoner_const_id
		  FROM reckoner_const_dep rcd, reckoner_tag rtg
		 WHERE rtg.app_sid = v_from_app
		   AND rcd.reckoner_id = rtg.reckoner_id
	) LOOP
		INSERT INTO reckoner_const_dep (
			reckoner_id, reckoner_const_id
		) (
			SELECT rec.new_id, const.new_id
			  FROM idmap rec, idmap const
			 WHERE rec.name = 'reckoner'
			   AND rec.old_id = r.reckoner_id
			   AND const.name = 'reckoner_const'
			   AND const.old_id = r.reckoner_const_id
		);
	END LOOP;
	
	-- RECKONER INPUT
	FOR r IN (
		SELECT inp.reckoner_id, inp.reckoner_input_id, inp.name, inp.label, inp.pos
		  FROM reckoner_input inp, reckoner_tag rtg
		 WHERE rtg.app_sid = v_from_app
		   AND inp.reckoner_id = rtg.reckoner_id
	) LOOP
		INSERT INTO reckoner_input (
			reckoner_id, reckoner_input_id, name, label, pos
		) (
			SELECT rec.new_id, reckoner_input_id_seq.NEXTVAL, r.name, r.label, r.pos
			  FROM idmap rec
			 WHERE rec.name = 'reckoner'
			   AND rec.old_id = r.reckoner_id
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('reckoner_input', r.reckoner_input_id, reckoner_input_id_seq.CURRVAL);
	END LOOP;
	
	-- RECKONER OUTPUT
	FOR r IN (
		SELECT outp.reckoner_id, outp.reckoner_output_id, outp.name, outp.label, outp.map_to
		  FROM reckoner_output outp, reckoner_tag rtg
		 WHERE rtg.app_sid = v_from_app
		   AND outp.reckoner_id = rtg.reckoner_id
	) LOOP
		INSERT INTO reckoner_output (
			reckoner_id, reckoner_output_id, name, label, map_to
		) (
			SELECT rec.new_id, reckoner_output_id_seq.NEXTVAL, r.name, r.label, r.map_to
			  FROM idmap rec
			 WHERE rec.name = 'reckoner'
			   AND rec.old_id = r.reckoner_id
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('reckoner_output', r.reckoner_output_id, reckoner_output_id_seq.CURRVAL);
	END LOOP;
	*/
	
	-- IMPORT TEMPLATE
	
	INSERT INTO idmap (name, old_id, new_id) VALUES ('project', -1, -1);
	
	FOR r IN (
		SELECT import_template_id, name, heading_row_idx, worksheet_name, project_sid, workbook, is_default
		  FROM import_template
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO import_template (
			app_sid, import_template_id, name, heading_row_idx, worksheet_name, project_sid, workbook, is_default
		) (
			SELECT v_to_app, import_template_id_seq.NEXTVAL, r.name, r.heading_row_idx, r.worksheet_name, 
				DECODE (prj.new_id, -1, NULL, prj.new_id), r.workbook, r.is_default
			  FROM idmap prj
			 WHERE prj.name = 'project'
			   AND prj.old_id = NVL(r.project_sid, -1)
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('import_template', r.import_template_id, import_template_id_seq.CURRVAL);
	END LOOP;
	
	-- IMPORT TEMPLATE MAPPING
	FOR r IN (
		SELECT import_template_id, to_name, from_idx, from_name
		  FROM import_template_mapping
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO import_template_mapping (
			app_sid, import_template_id, to_name, from_idx, from_name
		) (
			SELECT v_to_app, it.new_id, r.to_name, r.from_idx, r.from_name
			  FROM idmap it
			 WHERE it.name = 'import_template'
			   AND it.old_id = r.import_template_id
		);
	END LOOP;
	
	-- PERIODIC REPORT TEMPLATE
	FOR r IN (
		SELECT report_template_id, description, template_xml
		  FROM periodic_report_template
		 WHERE app_sid = v_from_app
	) LOOP
		INSERT INTO periodic_report_template (
			app_sid, report_template_id, description, template_xml
		) VALUES (
			v_to_app, report_template_id_seq.NEXTVAL, r.description, r.template_xml
		);
		INSERT INTO idmap (name, old_id, new_id) VALUES ('periodic_report_template', r.report_template_id, report_template_id_seq.CURRVAL);
	END LOOP;
	
END;
/

