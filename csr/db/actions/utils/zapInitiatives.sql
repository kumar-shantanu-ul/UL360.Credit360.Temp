/*
// Do this first.
CREATE GLOBAL TEMPORARY TABLE ACTIONS.IDMAP
(
	NAME				VARCHAR2(256)	NOT NULL,
	OLD_ID				NUMBER(10, 0)	NOT NULL,
	NEW_ID				NUMBER(10, 0)	NULL
)
ON COMMIT DELETE ROWS;
*/

BEGIN
	user_pkg.logonadmin('&&host');
	
	-- Prevent problems with weighting calcs when deleting
	UPDATE TASK SET weighting = 0 
	 WHERE app_sid = security_pkg.GetAPP;
	
	-- Delete all tasks
	FOR r IN (
		SELECT task_sid
		  FROM (
			SELECT LEVEL lvl, task_sid
			  FROM task
			 	START WITH parent_task_sid IS NULL
			 	CONNECT BY PRIOR task_sid = parent_task_sid
		) t ORDER BY lvl DESC
	) LOOP
		securableobject_pkg.DeleteSO(security_pkg.GetACT, r.task_sid);
	END LOOP;
	
	-- RECKONER (done before projects as we need the reckoner_tag
	-- table contents to tie the reckoner to the app)	 
	FOR r IN (
		SELECT reckoner_id
	 	  FROM reckoner_tag
	 	 WHERE app_sid = security_pkg.GetAPP
	) LOOP
	
		INSERT INTO idmap(name, old_id)
		 VALUES ('delete_reckoner', r.reckoner_id);
		
		INSERT INTO idmap (name, old_id) (
		     SELECT 'delete_reckoner_const', reckoner_const_id
		       FROM reckoner_const_dep
		      WHERE reckoner_id = r.reckoner_id
		 );
		 
		DELETE FROM reckoner_const_dep
		 WHERE reckoner_id = r.reckoner_id;
		
		DELETE FROM reckoner_input
		 WHERE reckoner_id = r.reckoner_id;
		
		DELETE FROM reckoner_output
		 WHERE reckoner_id = r.reckoner_id;
		
	END LOOP;
	
	DELETE FROM reckoner_const
	 WHERE reckoner_const_id IN (
	 	SELECT old_id
	 	  FROM idmap
	 	 WHERE name = 'delete_reckoner_const'
	 );
	
	DELETE FROM reckoner_tag
	  WHERE app_sid = security_pkg.GetAPP;
	
	DELETE FROM reckoner_tag_group
		 WHERE app_sid = security_pkg.GetAPP;
	
	DELETE FROM reckoner
	 WHERE reckoner_id IN (
	 	SELECT old_id
	 	  FROM idmap
	 	 WHERE name = 'delete_reckoner'
	 );

	-- Delete all projects 
	FOR r IN (
		SELECT project_sid
		  FROM project
	) LOOP
		securableobject_pkg.DeleteSO(security_pkg.GetACT, r.project_sid);
	END LOOP;
	
	-- IMPORT
	DELETE FROM import_template_mapping
	 WHERE app_sid = security_pkg.GetAPP;
	 
	DELETE FROM import_template
	 WHERE app_sid = security_pkg.GetAPP;
	
	DELETE FROM import_mapping_mru
	 WHERE app_sid = security_pkg.GetAPP;
	
	-- PERIODIC REPORT
	DELETE FROM periodic_report_template
	 WHERE app_sid = security_pkg.GetAPP;
	 
	-- ALERT
	DELETE FROM periodic_alert_user
	 WHERE app_sid = security_pkg.GetAPP;
	
	DELETE FROM periodic_alert
	 WHERE app_sid = security_pkg.GetAPP;
	
	-- TAGS
	DELETE FROM tag_group_member
	 WHERE app_sid = security_pkg.GetAPP;
	
	DELETE FROM tag_group
	 WHERE app_sid = security_pkg.GetAPP;
	 
	DELETE FROM tag
	 WHERE app_sid = security_pkg.GetAPP;
	 
	-- INITIATIVES ROLES
	FOR r IN (
		SELECT DISTINCT role_sid
		  FROM task_status_role
	) LOOP 
		DELETE FROM task_status_role
		 WHERE app_sid = security_pkg.GetAPP
		   AND role_sid = r.role_sid
		;
		--securableobject_pkg.DeleteSO(security_pkg.GetACT, r.role_sid);
	END LOOP;
	
	-- Scenario filters
	FOR r IN (
		SELECT scenario_sid, rule_id
		  FROM scenario_filter
		 WHERE app_sid = security_pkg.GetAPP
	) LOOP
		scenario_pkg.DeleteStatusFilter(r.scenario_sid, r.rule_id);
	END LOOP;
	
	-- STATUS	
	DELETE FROM allow_transition
	 WHERE app_sid = security_pkg.GetAPP;

	DELETE FROM task_status_transition
	 WHERE app_sid = security_pkg.GetAPP;
	 
	DELETE FROM task_status_history
	 WHERE app_sid = security_pkg.GetAPP;
	 
	DELETE FROM task_period_status
	 WHERE app_sid = security_pkg.GetAPP;
	 
	DELETE FROM task_status
	 WHERE app_sid = security_pkg.GetAPP;
	
	-- IND TEMPLATE
	DELETE FROM ind_template
	 WHERE app_sid = security_pkg.GetAPP
	   AND name <> 'action_progress';

END;
/
