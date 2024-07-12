DECLARE
	v_count				NUMBER;
	v_app_sid			NUMBER;
BEGIN

	security.user_pkg.logonadmin('&&host');

	v_app_sid := security.security_pkg.GetApp();
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_region_sid;
	
	IF v_count = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'No region sids in temp_region_sid'); END IF;
	
	-- Include any child regions
	INSERT INTO csr.temp_region_sid
	SELECT DISTINCT region_sid
	  FROM csr.region
	 START WITH region_sid IN (SELECT region_sid FROM csr.temp_region_sid)
	CONNECT BY PRIOR region_sid = parent_sid
	MINUS
	SELECT region_sid FROM csr.temp_region_sid;
	
	-- Include regions that link to selected regions
	INSERT INTO csr.temp_region_sid
	SELECT DISTINCT region_sid FROM csr.region WHERE link_to_region_sid IN (SELECT region_sid FROM csr.temp_region_sid)
	MINUS
	SELECT region_sid FROM csr.temp_region_sid;
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_tree
	 WHERE app_sid = security_pkg.GetApp
	   AND region_tree_root_sid IN (SELECT region_sid FROM csr.temp_region_sid);
	
	IF v_count > 0 THEN RAISE_APPLICATION_ERROR(-20001, 'temp_region_sid contains sids of region trees roots'); END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_region_sid
	 WHERE region_sid NOT IN (SELECT region_sid FROM csr.region);
	
	IF v_count > 0 THEN RAISE_APPLICATION_ERROR(-20001, 'temp_region_sid contains sids of SOs that aren''t in the region table'); END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_start_point
	 WHERE region_sid IN (SELECT region_sid FROM csr.temp_region_sid);
	
	IF v_count > 0 THEN RAISE_APPLICATION_ERROR(-20001, 'temp_region_sid contains sids used by '||v_count||' users as mount points'); END IF;
	-- delete any regions that link to this object
	FOR r IN (SELECT r.region_sid FROM csr.region r JOIN csr.temp_region_sid tr ON r.link_to_region_sid = tr.region_sid)
	LOOP		
		security.securableobject_pkg.DeleteSO(security.security_pkg.getact, r.region_sid);
	END LOOP;
	
	-- unhook imports
	UPDATE csr.IMP_REGION SET MAPS_TO_REGION_SID = NULL
	 WHERE MAPS_TO_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	-- add a recalc job for our parent, as long as it's not the trash or the app
	csr.region_pkg.AddAggregateJobs(security.security_pkg.GetApp, NULL);

	-- delete all values associated with this region
	UPDATE csr.IMP_VAL SET SET_VAL_ID = NULL WHERE SET_VAL_ID IN
		(SELECT VAL_ID FROM csr.VAL WHERE region_sid IN (select region_sid FROM csr.temp_region_sid))
	     AND app_sid = v_app_sid;
	DELETE FROM csr.val_note 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.val_file 
	 WHERE val_id IN (SELECT val_id
						FROM csr.val
					   WHERE region_sid IN (select region_sid FROM csr.temp_region_sid))
	     AND app_sid = v_app_sid;
	DELETE FROM csr.val 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM /*+cardinality (VC 10000) */ csr.val_change vc
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.target_dashboard_value 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.dashboard_item 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.tpl_report_tag_dv_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.dataview_region_description
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.dataview_region_member
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.form_region_member
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.target_dashboard_reg_member
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.pct_ownership_change
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.pct_ownership 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)	 
	     AND app_sid = v_app_sid;
	FOR r IN (
		SELECT sheet_value_id 
		  FROM csr.sheet_value
		WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	        AND app_sid = v_app_sid
	) 
	LOOP
		csr.sheet_pkg.INTERNAL_DeleteSheetValue(r.sheet_value_Id);
	END LOOP;
	DELETE FROM csr.delegation_region_description
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.delegation_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.region_tag
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.region_owner
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	-- Delete this and all inherited roles
	DELETE FROM csr.region_role_member 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	DELETE FROM csr.region_role_member 
	 WHERE inherited_from_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	  
	-- clean out actions
	DELETE FROM actions.task_recalc_region WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.aggr_task_period_override WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.aggr_task_period WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.task_period_override WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.task_period WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.task_period_file_upload WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM actions.task_region WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	DELETE FROM actions.project_region_role_member 
	 WHERE region_sid IN (
	 	SELECT NVL(link_to_region_sid, region_sid) region_sid
	 	  FROM csr.region
	 	 	START WITH region_sid IN (select region_sid FROM csr.temp_region_sid)
	 	 	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	 )
	AND app_sid = v_app_sid;
	
	
	-- TODO: Handle meters properly or prevent trying to delete them
	-- Clean out meter alarms
	--meter_alarm_pkg.OnDeleteRegion(in_sid_id);
	
	-- Remove meter issues
	FOR r IN (
		SELECT issue_id
		  FROM csr.issue i
			JOIN csr.issue_meter ii ON i.issue_meter_id = ii.issue_meter_id
		 WHERE ii.region_sid IN (select region_sid FROM csr.temp_region_sid)
	         AND i.app_sid = v_app_sid
		 UNION
		SELECT issue_id
		  FROM csr.issue i
			JOIN csr.issue_sheet_value ii ON i.issue_sheet_value_id = ii.issue_sheet_value_id
		 WHERE ii.region_sid IN (select region_sid FROM csr.temp_region_sid)
	         AND i.app_sid = v_app_sid
	) LOOP	
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	END LOOP;
	
	-- Remove region reference from raw data issues
	UPDATE csr.issue_meter_raw_data
	   SET region_sid = NULL
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	-- clean out meter stuff
	DELETE FROM csr.meter_list_cache
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.meter_reading 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.meter 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	-- clean out linked documents
	DELETE FROM csr.region_proc_doc 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.region_proc_file 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	-- clean up divisional reporting stuff 
	DELETE FROM csr.property_division 
         WHERE division_id IN (
		SELECT division_id FROM csr.division WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	  ) OR region_sid IN (select region_sid FROM csr.temp_region_sid)
	AND app_sid = v_app_sid;
	  
	-- Clean out energy star
	--energy_star_pkg.OnDeleteRegion(in_act_id, in_sid_id);
	--!!CONTENT OF energy_star_pkg.OnDeleteRegion AS OF 26/02/2015!!
	UPDATE csr.est_building
	   SET region_sid = NULL
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	UPDATE csr.est_space
	   SET region_sid = NULL
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	UPDATE csr.est_meter
	   SET region_sid = NULL
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	--!!
	
	DELETE FROM csr.lease_space
	 WHERE space_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.property_photo
	 WHERE space_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.property_photo
	 WHERE property_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.space
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.property 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	DELETE FROM csr.division 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.scenario_run_val
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;	 
	DELETE FROM csr.scenario_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.tab_portlet_user_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	

	DELETE FROM csr.current_supplier_score
	 WHERE company_sid IN (
	 	SELECT company_sid
	 	  FROM csr.supplier
	 	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	 )
	 AND app_sid = v_app_sid;
	
	DELETE FROM csr.supplier_score_log
	 WHERE supplier_sid IN (
	 	SELECT company_sid
	 	  FROM csr.supplier
	 	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	 )
	 AND app_sid = v_app_sid;
	
	DELETE FROM csr.supplier
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.region_description
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.region_metric_val
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.region_set_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	--XXX: should probably support this properly
	
	DELETE FROM csr.deleg_plan_deleg_region_deleg
	 WHERE applied_to_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	DELETE FROM csr.deleg_plan_deleg_region_deleg
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.deleg_plan_deleg_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.deleg_plan_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	 FOR r IN (
		SELECT issue_id
		FROM csr.issue
		WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid
	 ) LOOP
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	 END LOOP;

	DELETE FROM csr.imp_conflict_val
	 WHERE imp_conflict_id IN (
	 	SELECT imp_conflict_id
	 	  FROM csr.imp_conflict
	 	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid) 
	     AND app_sid = v_app_sid
	 );
 
	DELETE FROM csr.imp_conflict
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.dataview_zone
	 WHERE start_val_region_sid IN (select region_sid FROM csr.temp_region_sid)
		OR end_val_region_sid IN (select region_sid FROM csr.temp_region_sid)
	  AND app_sid = v_app_sid;

	DELETE FROM csr.val_note
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.snapshot_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	UPDATE csr.section_module
	   SET region_sid = NULL
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.scenario_rule_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	UPDATE csr.pending_region 
	   SET maps_to_region_sid = NULL
	 WHERE maps_to_region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 	 
	DELETE FROM csr.factor_history
	 WHERE factor_id IN (
	 	SELECT factor_id
	 	  FROM csr.factor
	 	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid
	 );
 
	DELETE FROM csr.factor
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	DELETE FROM csr.tpl_report_schedule_region
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.ruleset_run_finding
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.ruleset_run
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	 
	DELETE FROM csr.tpl_report_sched_saved_doc
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;

	DELETE FROM csr.region 
	 WHERE region_sid IN (select region_sid FROM csr.temp_region_sid)
	     AND app_sid = v_app_sid;
	
	DELETE FROM security.group_members
	 WHERE group_sid_id IN (select region_sid FROM csr.temp_region_sid);
	     --AND app_sid = v_app_sid; NO APP_SID
	
	DELETE FROM security.group_table
	 WHERE sid_id IN (select region_sid FROM csr.temp_region_sid);
	     --AND app_sid = v_app_sid; NO APP_SID
	
	DELETE FROM security.acl
     WHERE sid_id IN (select region_sid FROM csr.temp_region_sid);
	     --AND app_sid = v_app_sid; NO APP_SID
	
	DELETE FROM security.securable_object
	 WHERE sid_id IN (select region_sid FROM csr.temp_region_sid)
	     AND application_sid_id = v_app_sid;
END;
/
