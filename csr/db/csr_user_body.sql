CREATE OR REPLACE PACKAGE BODY CSR.Csr_User_Pkg
IS

-- security interface procs
PROCEDURE CreateObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_club_sid						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
IS
	v_sid security_pkg.T_SID_ID;
BEGIN
	-- create container for my charts
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'Charts', v_sid);
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'Workspace', v_sid);
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'CMS Filters', v_sid);
	securableobject_pkg.createSO(in_act, in_club_sid, security_pkg.SO_CONTAINER, 'Pivot tables', v_sid);
END CreateObject;

PROCEDURE RenameObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
IS
BEGIN
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		UPDATE csr_user
		   SET user_name = LOWER(in_new_name),
			   last_modified_dtm = SYSDATE
		 WHERE csr_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
		 
		UPDATE superadmin
		   SET user_name = LOWER(in_new_name)
		 WHERE csr_user_sid = in_sid_id;
	END IF;
END RenameObject;

PROCEDURE DeleteObject(
	in_act							IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
IS
BEGIN
	
	UPDATE chain.compound_filter
	   SET created_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	chain.company_user_pkg.DeleteObject(in_act, in_sid_id);
	
	DELETE FROM audit_log 
	 WHERE object_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM audit_log 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM pending_val_log 
	 WHERE set_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM region_owner 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	DELETE FROM ind_start_point 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	 
	DELETE FROM region_start_point 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	-- COVER
	-- user is  they are deleted they can't cover anyone anymore or be covered by anyone
	DELETE FROM delegation_user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM delegation_user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM audit_user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM audit_user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM group_user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM group_user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM role_user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM role_user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM issue_user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM issue_user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_cover
	 WHERE user_being_covered_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_cover
	 WHERE user_giving_cover_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	 
	DELETE FROM delegation_user 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM region_role_member 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM sheet_alert
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM audit_alert
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM approval_step_sheet_alert
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM delegation_terminated_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM delegation_terminated_alert
	 WHERE raised_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_message_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_message_alert
	 WHERE raised_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM new_delegation_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM new_delegation_alert
	 WHERE raised_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM new_planned_deleg_alert
	 WHERE (notify_user_sid = in_sid_id OR raised_by_user_sid = in_sid_id)
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM sheet_created_alert
	 WHERE (notify_user_sid = in_sid_id OR raised_by_user_sid = in_sid_id)
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM delegation_change_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM delegation_change_alert
	 WHERE raised_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_inactive_man_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_inactive_sys_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_inactive_rem_alert
	 WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM issue_involvement 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
		
	UPDATE issue_log
	   SET logged_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE logged_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE issue
	   SET owner_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE owner_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE issue
	   SET raised_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE raised_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE issue
	   SET assigned_to_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE assigned_to_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM tab_user 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE r_report
	   SET requested_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE requested_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM r_report_job
	 WHERE batch_job_id IN (
		SELECT batch_job_id FROM batch_job
		 WHERE requested_by_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	 ) AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM alert_bounce
	 WHERE alert_id IN (
		SELECT alert_id
		  FROM alert
		 WHERE to_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	)
	  AND app_sid = SYS_CONTEXT('SECURITY','APP');
	  
	DELETE FROM alert
	 WHERE to_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM alert_batch_run 
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM autocreate_user 
	 WHERE created_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE trash 
	   SET trashed_by_sid = NULL 
	 WHERE trashed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM form_allocation_user 
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM superadmin 
	 WHERE csr_user_sid = in_sid_id;
	DELETE FROM user_setting_entry
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM tab_portlet_user_region
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	DELETE FROM user_measure_conversion
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM deleg_plan_job
	 WHERE batch_job_id IN (SELECT batch_job_id
	 						  FROM batch_job
	 						 WHERE requested_by_user_sid = in_sid_id
							   AND app_sid = SYS_CONTEXT('SECURITY','APP'));

	DELETE FROM batch_job_cms_import
	 WHERE batch_job_id IN (SELECT batch_job_id
	 						  FROM batch_job
	 						 WHERE requested_by_user_sid = in_sid_id
							   AND app_sid = SYS_CONTEXT('SECURITY','APP'));

	DELETE FROM batch_job_batched_import
	 WHERE batch_job_id IN (SELECT batch_job_id
	 						  FROM batch_job
	 						 WHERE requested_by_user_sid = in_sid_id
							   AND app_sid = SYS_CONTEXT('SECURITY','APP'));
							   
	DELETE FROM batch_job_batched_export
	 WHERE batch_job_id IN (SELECT batch_job_id
	 						  FROM batch_job
	 						 WHERE requested_by_user_sid = in_sid_id
							   AND app_sid = SYS_CONTEXT('SECURITY','APP'));

	DELETE FROM batch_job
	 WHERE requested_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	  
	UPDATE csr_user
	   SET line_manager_sid = NULL,
		   last_modified_dtm = SYSDATE
	 WHERE line_manager_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');	
	
	DELETE FROM issue_action_log
	 WHERE logged_by_user_sid = in_sid_id OR assigned_to_user_sid = in_sid_id OR re_user_sid = in_sid_id 
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	--DELETE FROM flow_state_log
	-- WHERE set_by_user_sid = in_sid_id
	--   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE flow_state_log
	   SET set_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE set_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM flow_item_generated_alert
	 WHERE to_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE flow_item_generated_alert
	   SET from_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE from_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE internal_audit
	   SET auditor_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE auditor_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE internal_audit
	   SET created_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE non_compliance
	   SET created_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	DELETE FROM doc_download
	 WHERE downloaded_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE sheet_history
	   SET from_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE from_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE sheet_value_change
	   SET changed_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE val
	   SET changed_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE val_change
	   SET changed_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE deleted_delegation
	   SET deleted_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE deleted_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE delegation
	   SET created_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE doc_current
	   SET locked_by_sid = NULL
	 WHERE locked_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE doc_version
	   SET changed_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM doc_notification 
	 WHERE notify_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM doc_subscription 
	 WHERE notify_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	UPDATE dataview
	   SET last_updated_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE last_updated_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE sheet_value
	   SET set_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE set_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM imp_vocab
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE imp_session
	   SET owner_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE owner_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM region_set_region
	 WHERE region_set_id IN (
		SELECT region_set_id
		  FROM region_set
		 WHERE owner_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		)
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM region_set
	 WHERE owner_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM ind_set_ind
	 WHERE ind_set_id IN (
		SELECT ind_set_id
		  FROM ind_set
		 WHERE owner_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		)
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM ind_set
	 WHERE owner_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE section_version
	   SET approved_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE approved_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE section_version
	   SET changed_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE section
	   SET checked_out_to_sid = NULL,
		   checked_out_dtm = NULL,
		   checked_out_version_number = NULL
	 WHERE checked_out_to_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM section_alert
     WHERE notify_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	   
	--Report settings
	UPDATE tpl_report_sched_batch_run
	   SET next_fire_time = NULL
	 WHERE schedule_sid IN (
		SELECT schedule_sid
		  FROM tpl_report_schedule
		 WHERE owner_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	 );
	
	UPDATE tpl_report_schedule
	   SET owner_user_sid = NULL
	 WHERE owner_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	DELETE FROM approval_step_user
	 WHERE user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	   
	UPDATE approval_step_user
	   SET fallback_user_sid = NULL
	 WHERE fallback_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM issue_alert
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE postit
	   SET created_by_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE issue
	   SET resolved_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE resolved_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE issue
	   SET rejected_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE rejected_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE issue
	   SET closed_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE closed_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM issue_log_read
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE supplier_score_log
	   SET changed_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE changed_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	DELETE FROM scenario_email_sub
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE scenario
	   SET created_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE scenario_run
	   SET last_run_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE last_run_by_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM cookie_policy_consent
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');	
	
	DELETE FROM csr_user 
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE compliance_permit
	   SET created_by = security_pkg.SID_BUILTIN_ADMINISTRATOR
	 WHERE created_by = in_sid_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	DELETE FROM user_profile
	 WHERE csr_user_sid = in_sid_id;

END DeleteObject;

PROCEDURE MoveObject(
	in_act						IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
)
IS
BEGIN
	NULL;
END MoveObject;

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
)
AS
BEGIN
	FOR r IN (
		SELECT trash_sid, description
		  FROM trash t, security.securable_object so
		 WHERE so.class_id = class_pkg.GetClassId('CSRUser')
		   AND t.trash_sid = so.sid_id
	) LOOP
		csr_data_pkg.WriteAuditLogEntry(
			SYS_CONTEXT('SECURITY', 'ACT'),
			csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
			SYS_CONTEXT('SECURITY', 'APP'),
			r.trash_sid,
			'User "{0}" restored', 
			r.description);
	END LOOP;
END;

-- User callbacks
PROCEDURE LogOff(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_suppress_audit		NUMBER;
BEGIN
	SELECT NVL(MIN(val), 0)
	  INTO v_suppress_audit
	  FROM transaction_context
	 WHERE key = 'suppress_audit';

	-- write to audit log if not suppressed
	IF NOT v_suppress_audit = 1 THEN
		SELECT app_sid 
		  INTO v_app_sid
		  FROM csr_user
		 WHERE csr_user_sid = in_sid_id
	       AND app_sid = SYS_CONTEXT('SECURITY','APP');
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_LOGOFF, v_app_sid, in_sid_id, 'Logged off');
	END IF;
END;

PROCEDURE UNSEC_AddGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
	in_group_sid	IN security_pkg.T_SID_ID
)
AS 
BEGIN 
	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END;

PROCEDURE UNSEC_DeleteGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_region_sid		IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	DELETE FROM security.group_members 
     WHERE member_sid_id = in_member_sid
       AND group_sid_id = in_region_sid; 
END;

PROCEDURE LogOn(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_act_timeout			IN security_pkg.T_ACT_TIMEOUT,
	in_logon_type			IN security_pkg.T_LOGON_TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_suppress_audit		NUMBER;
	v_superadmin			NUMBER;
	v_user_name				VARCHAR2(255);
	v_audit_type			NUMBER;
	v_audit_msg				VARCHAR2(255);
BEGIN
	--security_pkg.debugmsg('LogOn callback with app sid = '||SYS_CONTEXT('SECURITY','APP')||' and act = '||SYS_CONTEXT('SECURITY','ACT')||' vs '||in_act_id);
	SELECT NVL(MIN(val), 0)
	  INTO v_suppress_audit
	  FROM transaction_context
	 WHERE key = 'suppress_audit';

	-- update last login type if is not batch log on e.g. batch job/schedule task
	UPDATE csr_user
	   SET last_logon_type_id = in_logon_type
	 WHERE csr_user_sid = in_sid_id
	   AND DECODE(last_logon_type_id, in_logon_type, 1, 0) = 0
	   AND in_logon_type != security.security_pkg.LOGON_TYPE_BATCH
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	-- write to audit log if not suppressed
	IF NOT v_suppress_audit = 1 THEN
		SELECT app_sid, full_name||' ('||user_name||')'
		  INTO v_app_sid, v_user_name
		  FROM csr_user
		 WHERE csr_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		-- The SU logon is audited in LogonAsUser, so their act is recorded as the performing SID.
		IF NOT in_logon_type = csr_data_pkg.LOGON_TYPE_SU THEN
			CASE in_logon_type
				WHEN security.security_pkg.LOGON_TYPE_BATCH THEN
					v_audit_type := csr_data_pkg.AUDIT_TYPE_BATCH_LOGON;
					v_audit_msg := 'Logged on';
				WHEN security.security_pkg.LOGON_TYPE_SSO THEN
					v_audit_type := csr_data_pkg.AUDIT_TYPE_SSO_LOGON;
					v_audit_msg := 'Logged on via SSO';
				ELSE
					v_audit_type := csr_data_pkg.AUDIT_TYPE_LOGON;
					v_audit_msg := 'Logged on';
			END CASE;
			csr_data_pkg.WriteAuditLogEntry(in_act_id, v_audit_type, v_app_sid, in_sid_id, v_audit_msg);
		END IF;
	END IF;
		
	-- check if user is superadmin
	SELECT COUNT(*)
	  INTO v_superadmin
	  FROM superadmin
	 WHERE csr_user_sid = in_sid_id;
	IF v_superadmin = 1 THEN
		security_pkg.SetContext('IS_SUPERADMIN', 1);
	END IF;
END;



PROCEDURE LogonFailed(
	in_sid_id				IN security_pkg.T_SID_ID,
	in_error_code			IN NUMBER,
	in_message			    IN VARCHAR2
)
AS
    PRAGMA AUTONOMOUS_TRANSACTION;  -- have to do this as we're certain to get rolled back with RAISE_APPLICATION_ERROR later
 	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- write to audit log
	BEGIN
        SELECT app_sid 
          INTO v_app_sid
          FROM csr_user
         WHERE csr_user_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN; -- ignore
    END;
	csr_data_pkg.WriteAuditLogEntryForSid(in_sid_id, csr_data_pkg.AUDIT_TYPE_LOGON_FAILED, v_app_sid, in_sid_id, in_message);
    COMMIT;
END;


PROCEDURE GetAccountPolicy(
	in_sid_id				IN	security_pkg.T_SID_ID,
	out_policy_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT MIN(val)
	  INTO out_policy_sid
	  FROM transaction_context
	 WHERE key = 'account_policy_sid';
	IF out_policy_sid IS NULL THEN
		SELECT MIN(account_policy_sid)
		  INTO out_policy_sid
		  FROM customer c, csr_user cu
		 WHERE cu.app_sid = c.app_sid AND cu.csr_user_sid = in_sid_id
		-- Super-admins are once again excluded from policy, as they must authenticate with SSO
		-- now, and it never made much sense to apply any particular customer's policy to them
		-- anyway.
		   AND NOT EXISTS(SELECT * FROM superadmin sa WHERE sa.csr_user_sid = in_sid_id);
	END IF;
END;

FUNCTION IsSSOUser(
	in_user_sid		 	IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
	v_user_is_sso		NUMBER;
BEGIN
	SELECT MAX(CASE WHEN LOWER(cu.user_name) = 'sso' AND cu.hidden = 1 THEN 1 ELSE 0 END)
	  INTO v_user_is_sso
	  FROM csr_user cu
	 WHERE cu.csr_user_sid = in_user_sid;

	RETURN v_user_is_sso = 1;
END;

--called from security.AccountPolicyHelper.ExpireAccounts to disable user based on policy
PROCEDURE DisableAccount(
	in_act_id						IN	Security_Pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID;
BEGIN
	IF (NOT IsSSOUser(in_user_sid)) AND in_app_sid IS NOT NULL THEN

		UNSEC_DelRolesFromUserIfNeeded(
			in_app_sid => in_app_sid,
			in_user_sid => in_user_sid
		);

		user_pkg.UNSEC_DisableAccount(in_user_sid);

		csr_data_pkg.WriteAuditLogEntryForSid(
			in_sid_id => security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_audit_type_id => csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT,
			in_app_sid => in_app_sid,
			in_object_sid => in_user_sid,
			in_description => 'Account Expired'
		);

		RaiseUserInactiveSysAlert(in_user_sid, in_app_sid);
	END IF;
END;

FUNCTION is_account_due_to_expire(
	in_user_sid		 			IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
	v_expiration_dtm			security.user_table.expiration_dtm%TYPE;
	v_account_enabled			security.user_table.account_enabled%TYPE;
BEGIN
	SELECT ut.expiration_dtm, ut.account_enabled
	  INTO v_expiration_dtm, v_account_enabled
	  FROM security.user_table ut
	 WHERE ut.sid_id = in_user_sid;

	RETURN v_expiration_dtm IS NOT NULL AND SYSDATE >= v_expiration_dtm AND v_account_enabled = 1;
END;

FUNCTION is_account_inactive(
	in_user_sid		 			IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
	v_policy_sid		 		security_pkg.T_SID_ID;
	v_expire_inactive			security.account_policy.expire_inactive%TYPE;
	v_last_logon				security.user_table.last_logon%type;
BEGIN
	GetAccountPolicy(in_user_sid, v_policy_sid);

	IF v_policy_sid IS NULL THEN
		RETURN FALSE;
	END IF;

	SELECT expire_inactive
	  INTO v_expire_inactive
	  FROM security.account_policy
	 WHERE sid_id = v_policy_sid;

	SELECT last_logon
	  INTO v_last_logon
	  FROM security.user_table
	 WHERE sid_id = in_user_sid;

	RETURN v_expire_inactive IS NOT NULL AND v_last_logon < SYSDATE - v_expire_inactive;
END;

PROCEDURE UNSEC_DelRolesFromUserIfNeeded(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS
	v_remove_roles_inactive			NUMBER(1) := 0;
	v_remove_roles_on_date			NUMBER(1) := 0;
BEGIN
	IF is_account_inactive(in_user_sid) = TRUE THEN
		SELECT MAX(remove_roles_on_account_expir)
		  INTO v_remove_roles_inactive
		  FROM csr.customer
		 WHERE app_sid = in_app_sid;
	END IF;

	IF is_account_due_to_expire(in_user_sid) = TRUE THEN
		SELECT remove_roles_on_deactivation
		  INTO v_remove_roles_on_date
		  FROM csr.csr_user
		 WHERE csr_user_sid = in_user_sid;
	END IF;

	IF (v_remove_roles_inactive + v_remove_roles_on_date > 0) AND (NOT IsSSOUser(in_user_sid)) AND in_app_sid IS NOT NULL THEN
		role_pkg.UNSEC_DeleteAllRolesFromUser(in_app_sid, in_user_sid);
	END IF;
END;

PROCEDURE CheckRegisteredUser
IS
	v_act_id	security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF user_pkg.IsUserInGroup(
		v_act_id, 
		securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp(), 'Groups/RegisteredUsers')) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied due to lack of membership in Groups/RegisteredUsers '||
			'for the application with sid '||security_pkg.GetApp()||
			' using the act '||v_act_id);
	END IF;
END;

PROCEDURE CreateUserForApproval(
  	in_user_name				IN	CSR_USER.user_NAME%TYPE,
	in_password 				IN	VARCHAR2, -- nullable
   	in_full_name				IN	CSR_USER.full_NAME%TYPE,
	in_email		 			IN	CSR_USER.email%TYPE,
	in_job_title				IN	CSR_USER.job_title%TYPE,
	in_phone_number				IN	CSR_USER.phone_number%TYPE,
	in_chain_company_sid 		IN	security_pkg.T_SID_ID,
	in_redirect_to_url			IN	autocreate_user.redirect_to_url%TYPE,
	out_sid_id					OUT	security_pkg.T_SID_ID,
	out_guid					OUT	security_pkg.T_ACT_ID
)
AS
	v_original_act			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
   	v_original_user_sid 	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_ucd_act 				security_pkg.T_ACT_ID;
	v_normalized_user_name	csr_user.user_name%TYPE := LOWER(TRIM(in_user_name));
	v_require_new_password	autocreate_user.require_new_password%TYPE DEFAULT 0;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Create users for approval') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Create users for approval" capability');
	END IF;
	
	-- do this as the user creator daemon
	v_ucd_act := LogonUserCreatorDaemon;
	
	-- umm mailbox stuff needs things in Oracle session
	security_pkg.SetACTAndSID(v_ucd_act, v_original_user_sid);
	
	IF in_password IS NULL THEN
		v_require_new_password := 1;
	END IF;
	
	BEGIN
		CreateUser(
			in_act						=> v_ucd_act, 
			in_app_sid					=> security_pkg.GetApp, 
			in_user_name				=> v_normalized_user_name,
			in_password					=> in_password,
			in_full_name				=> in_full_name,
			in_friendly_name			=> null,
			in_email					=> in_email,
			in_job_title				=> in_job_title,
			in_phone_number				=> in_phone_number,
			in_info_xml					=> null,
			in_send_alerts				=> 1,
			in_enable_aria				=> 0,
			in_line_manager_sid			=> null,
			in_primary_region_sid		=> null,
			in_chain_company_sid		=> in_chain_company_sid,
			out_user_sid				=> out_sid_id);
		
		-- restore context ASAP
		security_pkg.SetACTAndSID(v_original_act, v_original_user_sid);
		
		deactivateUser(
			in_act							=> v_ucd_act, 
			in_user_sid						=> out_sid_id,
			in_raise_user_inactive_alert	=> 0
		);
							
		-- Add an entry into the autocreate_user table, we'll 
		-- use this guid to validate the user's e-mail account
		out_guid := user_pkg.generateACT;
		AddAutoAccount(v_normalized_user_name, out_guid, out_sid_id, v_require_new_password, in_redirect_to_url);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- restore context
			security_pkg.SetACTAndSID(v_original_act, v_original_user_sid);
			out_sid_id := securableobject_pkg.getSidFromPath(v_ucd_act, security_pkg.getApp, 'users/' || v_normalized_user_name);
			-- check if they're in the auto approve magic table
			-- first of all we might have rejected them before, so give them another chance
			UPDATE autocreate_user
			   SET rejected_dtm = null
			 WHERE created_user_sid = out_sid_id;
			 
			BEGIN
				SELECT guid
				  INTO out_guid
				  FROM autocreate_user
				 WHERE created_user_sid = out_sid_id
				   AND approved_dtm IS NULL;
			EXCEPTION	
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An active user already exists with this user name');
			END;			
		WHEN OTHERS THEN
			-- restore context
			security_pkg.SetACTAndSID(v_original_act, v_original_user_sid);
			RAISE;
	END;
END;

PROCEDURE CreateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE DEFAULT NULL,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE DEFAULT NULL,
	in_phone_number					IN  CSR_USER.phone_number%TYPE DEFAULT NULL,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE DEFAULT 0,
	in_line_manager_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_chain_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_primary_region_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_user_ref						IN  csr_user.user_ref%TYPE DEFAULT NULL,
	in_account_expiry_enabled		IN	security.user_table.account_expiry_enabled%TYPE DEFAULT 1,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
	v_start_points					security_pkg.T_SID_IDS;
BEGIN
	INTERNAL_CreateUser(
		in_act						=> in_act, 
		in_app_sid					=> in_app_sid, 
		in_user_name				=> in_user_name,
		in_password					=> in_password,
		in_full_name				=> in_full_name,
		in_friendly_name			=> in_friendly_name,
		in_email					=> in_email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_info_xml					=> in_info_xml,
		in_send_alerts				=> in_send_alerts,
		in_enable_aria				=> in_enable_aria,
		in_line_manager_sid			=> in_line_manager_sid,
		in_primary_region_sid		=> in_primary_region_sid,
		in_user_ref					=> in_user_ref,
		in_account_expiry_enabled	=> in_account_expiry_enabled,
		out_user_sid				=> out_user_sid);
	
	-- make sure they have region start points
	SetRegionStartPoints(out_user_sid, v_start_points);
	
	-- now call supplier hooks. We do it this way round because we still want top-co users to be managed
	-- with the normal CR360 user functionality, i.e. default behaviour for creating users is that they're
	-- top co users.
	-- XXX: ugh -- chain dependency. CSR won't compile without chain now
	supplier_pkg.ChainCompanyUserCreated(out_user_sid, in_chain_company_sid);
END;

-- NOTE: This is called by chain.company_user_pkg
PROCEDURE INTERNAL_CreateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE,
	in_line_manager_sid				IN  security_pkg.T_SID_ID,
	in_primary_region_sid			IN	security_pkg.T_SID_ID,
	in_user_ref						IN  csr_user.user_ref%TYPE,
	in_account_expiry_enabled		IN	security.user_table.account_expiry_enabled%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
    v_user_sid 				security_pkg.T_SID_ID;
    v_group_sid 			security_pkg.T_SID_ID;
    v_user_guid				security_pkg.T_ACT_ID;
    v_start_points			security_pkg.T_SID_IDS;
    v_user_mailbox_sid		security_pkg.T_SID_ID;
    v_users_mailbox_sid		security_pkg.T_SID_ID;
   	v_normalized_user_name	csr_user.user_name%TYPE := LOWER(TRIM(in_user_name));
	v_upgrade_auth			NUMBER(1) := 0;
BEGIN
	INSERT INTO transaction_context (key, val)
		SELECT 'account_policy_sid', account_policy_sid
		  FROM customer
		 WHERE app_sid = in_app_sid;
		 
	user_pkg.CreateUser(
		in_act_id					=> in_act,
		in_parent_sid				=> securableobject_pkg.GetSIDFromPath(in_act, in_app_sid, 'Users'),
		in_login_name				=> v_normalized_user_name,
		in_plaintext_password		=> NULL,
		in_class_id					=> class_pkg.GetClassID('CSRUser'),
		in_account_expiry_enabled	=> in_account_expiry_enabled,
		out_user_sid				=> v_user_sid
	);

	v_group_sid := securableobject_pkg.GetSIDFromPath(in_act, in_app_sid, 'Groups/RegisteredUsers');
	-- add user to group
	security.Group_Pkg.addMember(in_act, v_user_sid, v_group_sid);
	
	v_user_guid := user_pkg.GenerateACT;
	
	INSERT INTO CSR_USER 
		(app_sid, csr_user_sid, user_name, full_NAME, 
		friendly_name, 
		email, 
		job_title, phone_number, 
		info_xml, 
		send_alerts,
		enable_aria,
		line_manager_sid,
		primary_region_sid,
		guid,
		user_ref)
	VALUES (
		in_app_sid, v_user_sid, v_normalized_user_name, in_full_name, 
		NVL(in_friendly_name, REGEXP_SUBSTR(in_full_name,'[^ ]+', 1, 1)), 
		TRIM(in_email), -- just in case
		in_job_title, in_phone_number,
		in_info_xml,
		in_send_alerts, 
		in_enable_aria,
		in_line_manager_sid,
		in_primary_region_sid,
		v_user_guid,
		in_user_ref);

	-- TODO: The new auth code is opt-in for now, while it is being tested in live. This should
	--	eventually be removed.
	BEGIN
		SELECT enable_java_auth
		  INTO v_upgrade_auth
		  FROM csr.customer
		 WHERE app_sid = in_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_upgrade_auth := 0;
	END;

	IF v_upgrade_auth = 1 THEN
		user_pkg.EnableJavaAuth(v_user_sid);
	END IF;

	IF in_password IS NOT NULL THEN
		user_pkg.ChangePasswordBySID(in_act, in_password, v_user_sid);
	END IF;

	out_user_sid := v_user_sid;	
	
	-- create a mailbox
	v_users_mailbox_sid := alert_pkg.GetSystemMailbox('Users');
	mail.mail_pkg.createMailbox(v_users_mailbox_sid, v_user_sid, v_user_mailbox_sid);
	acl_pkg.AddACE(in_act, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_group_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	acl_pkg.AddACE(in_act, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
			
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, in_app_sid, out_user_sid, 'User created');

    -- make sure they have ind start points
	SetIndStartPoints(v_user_sid, v_start_points);
END;

PROCEDURE SetUserRef(
	in_csr_user_sid					IN security_pkg.T_SID_ID,
	in_user_ref						IN csr_user.user_ref%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_csr_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE csr_user
	   SET user_ref = in_user_ref
	 WHERE csr_user_sid = in_csr_user_sid;
END;

PROCEDURE SetHiddenStatus(
	in_csr_user_sid					IN security_pkg.T_SID_ID,
	in_hidden						IN csr_user.hidden%TYPE
)
AS
	v_hidden						csr_user.hidden%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_csr_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT hidden
	  INTO v_hidden
	  FROM csr_user
	 WHERE csr_user_sid = in_csr_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	IF v_hidden != in_hidden THEN
		UPDATE csr_user
		   SET hidden = in_hidden
		 WHERE csr_user_sid = in_csr_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), 
			csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'), 
			in_csr_user_sid, 'Hidden', v_hidden, in_hidden);
	END IF;
END;

PROCEDURE createSuperAdmin(
	in_act			 				IN	security_pkg.T_ACT_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_password 					IN	VARCHAR2,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	out_user_sid 					OUT security_pkg.T_SID_ID
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_csr_sid				security_pkg.T_SID_ID;
	v_group_sid				security_pkg.T_SID_ID;
	v_registered_users_sid	security_pkg.T_SID_ID;
    v_user_guid				security_pkg.T_ACT_ID;
    v_user_mailbox_sid		security_pkg.T_SID_ID;
    v_users_mailbox_sid		security_pkg.T_SID_ID;
    v_stored_app_sid		security_pkg.T_SID_ID;
    v_stored_act			security_pkg.T_ACT_ID;
    v_builtin_admin_act		security_pkg.T_ACT_ID;
    v_dacl_id				security_pkg.T_ACL_ID;
   	v_normalized_user_name	csr_user.user_name%TYPE := LOWER(TRIM(in_user_name));
BEGIN
	-- we fiddle with this, so just keep track of it for now
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');

	IF in_password IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot create a super admin account with a password!');
	END IF;
	
	-- clear this down -- superadmmin stuff doesn't want
	-- to be constrainted by RLS
	security_pkg.SetApp(NULL);

	-- clear out policy too for superadmins
	DELETE FROM transaction_context
	 WHERE key = 'account_policy_sid';
	
	v_csr_sid := securableobject_pkg.GetSIDFromPath(in_act,0,'csr');

	user_pkg.CreateUser(
		in_act_id					=> in_act,
		in_parent_sid				=> securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/Users'),
		in_login_name				=> v_normalized_user_name,
		in_plaintext_password		=> in_password,
		in_class_id					=> class_pkg.GetClassID('CSRUser'),
		in_account_expiry_enabled	=> 0,
		out_user_sid				=> v_user_sid
	);
	     
	v_group_sid := securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/SuperAdmins');
	-- add user to group
	security.Group_Pkg.addMember(in_act, v_user_sid, v_group_sid);
	v_user_guid := user_pkg.GenerateACT;

	-- save into the superadmins table
	INSERT INTO superadmin (csr_user_sid, user_name, full_name, friendly_name, email, guid)
	VALUES (v_user_sid, v_normalized_user_name, in_full_name, in_friendly_name, in_email, v_user_guid);

	-- superadmins belong to all applications
	INSERT INTO csr_user (app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden, enable_aria)
		SELECT c.app_sid, v_user_sid, v_normalized_user_name, in_full_name, in_friendly_name, in_email, v_user_guid, 1, 0
		  FROM customer c;
	
	UPDATE csr_user 
	   SET hidden = 0 
	 WHERE app_sid = (SELECT app_sid FROM customer WHERE host = 'www.credit360.com')
	   AND csr_user_sid = v_user_sid;
	
	-- superadmins therefore have to have mailboxes in all applications
	-- We'll login as builtin/administrator for this bit...
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetACT(v_builtin_admin_act);
	FOR r IN (
		SELECT app_sid FROM customer
	) 
	LOOP
		security_pkg.SetApp(r.app_sid);
		v_registered_users_sid := securableobject_pkg.GetSIDFromPath(v_builtin_admin_act, r.app_sid, 'Groups/RegisteredUsers');
		BEGIN
			v_users_mailbox_sid := alert_pkg.GetSystemMailbox('Users');
			-- ought not be null
			IF v_users_mailbox_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'The application with sid '||r.app_sid||' does not have a Users mailbox');
			END IF;
		EXCEPTION
			WHEN mail.mail_pkg.MAILBOX_NOT_FOUND OR mail.mail_pkg.PATH_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'The application with sid '||r.app_sid||' does not have a Users mailbox');
		END;
		mail.mail_pkg.createMailbox(v_users_mailbox_sid, v_user_sid, v_user_mailbox_sid);
		v_dacl_id := acl_pkg.GetDACLIDForSID(v_user_mailbox_sid);
		IF v_dacl_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'The user mailbox with sid '||v_user_mailbox_sid||' and parent '||v_users_mailbox_sid||' does not have a dacl id');
		END IF;
		acl_pkg.AddACE(v_builtin_admin_act, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(v_builtin_admin_act, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
	security_pkg.SetApp(NULL);
	
    -- backfill startpoints
    INSERT INTO ind_start_point (app_sid, user_sid, ind_sid)
        SELECT app_sid, v_user_sid, ind_root_sid
          FROM customer;

    INSERT INTO region_start_point (app_sid, user_sid, region_sid)
        SELECT app_sid, v_user_sid, region_root_sid
          FROM customer;

	security_pkg.SetACT(v_stored_act, v_stored_app_sid);

	out_user_sid := v_user_sid;		
END;

FUNCTION IsSuperAdmin
RETURN NUMBER
AS
BEGIN
	RETURN IsSuperAdmin(SYS_CONTEXT('SECURITY','SID'));
END;

FUNCTION IsSuperAdmin (
	in_user_sid						IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_cnt	NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_cnt
	  FROM superadmin
	 WHERE csr_user_sid = in_user_sid;
	RETURN CASE WHEN in_user_sid = 3 THEN 1 ELSE v_cnt END;
END;

FUNCTION IsAriaUser
RETURN NUMBER
AS
	v_val	NUMBER;
BEGIN
	SELECT enable_aria
	  INTO v_val
	  FROM csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND csr_user_sid = SYS_CONTEXT('SECURITY','SID');
	
	RETURN v_val;
END;

/**
 * Set some basic details (called by userSettings). We deliberately don't let them set the
 * username since the user shouldn't fiddle with their own name (from a security perspective).
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 * @param in_full_name					Their real Name (e.g. 'Fred Bloggs')	
 * @param in_email						Email address
 */
PROCEDURE setBasicDetails(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_info_xml                     IN  CSR_USER.info_xml%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE
)
AS
	v_user_name					csr_user.user_name%TYPE;
	v_send_alerts				csr_user.send_alerts%TYPE;
	v_enable_aria				csr_user.enable_aria%TYPE;
	v_line_manager_sid			csr_user.line_manager_sid%TYPE;
BEGIN
	SELECT user_name, send_alerts, enable_aria, line_manager_sid
	  INTO v_user_name, v_send_alerts, v_enable_aria, v_line_manager_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
		  
	amendUser(
		in_act			 				=> security_pkg.getACT,
		in_user_sid		 				=> in_user_sid,
		in_user_name					=> v_user_name,
		in_full_name					=> in_full_name,
		in_friendly_name				=> in_friendly_name,
		in_email		 				=> TRIM(in_email),		-- just in case
		in_job_title					=> in_job_title,
		in_phone_number					=> in_phone_number,
		in_active						=> null, 				-- amendUser leaves this alone if it's null
		in_info_xml						=> in_info_xml,
		in_send_alerts					=> v_send_alerts,
		in_enable_aria					=> v_enable_aria,
		in_line_manager_sid				=> v_line_manager_sid,
		in_primary_region_sid			=> null
	);
END;


PROCEDURE SetExtraInfoValue(
	in_act		IN	security_pkg.T_ACT_ID,
	in_user_sid	IN	security_pkg.T_SID_ID,
	in_key		IN	VARCHAR2,		
	in_value	IN	VARCHAR2
)
AS
	v_path 			VARCHAR2(255) := '/fields/field[@name="'||in_key||'"]';
	v_new_node 		VARCHAR2(1024) := '<field name="'||in_key||'">'||htf.escape_sc(in_value)||'</field>';
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing user information');
	END IF;
	
	UPDATE CSR_USER
	   SET INFO_XML = 
			CASE
				WHEN info_xml IS NULL THEN
					APPENDCHILDXML(XMLType('<fields/>'), '/fields',  XmlType(v_new_node))
		    	WHEN EXISTSNODE(info_xml, v_path||'/text()') = 1 THEN
		    		UPDATEXML(info_xml, v_path||'/text()', htf.escape_sc(in_value))
		    	WHEN EXISTSNODE(info_xml, v_path) = 1 THEN
		    		UPDATEXML(info_xml, v_path, XmlType(v_new_node))
		    	ELSE
		    		APPENDCHILDXML(info_xml, '/fields', XmlType(v_new_node))
			END,
		   LAST_MODIFIED_DTM = SYSDATE
	WHERE csr_user_sid = in_user_sid
	  AND app_sid = SYS_CONTEXT('SECURITY','APP')
	RETURNING app_sid INTO v_app_sid;
	
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Set {0} to {1}', in_key, in_value);
END;


/*
	This version amends the settings, but only where a null hasn't been passed. Where null it uses the existing value so that nothing
	gets changed. That does mean that you can't clear any of the settings, but that is expected. 
*/
PROCEDURE amendUserWhereInputNotNull(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_user_name					IN	CSR_USER.user_NAME%TYPE,
	in_full_name					IN	CSR_USER.full_NAME%TYPE,
	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE,
	in_line_manager_sid				IN  security_pkg.T_SID_ID,
	in_primary_user_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_remove_roles_on_deact		IN	csr_user.remove_roles_on_deactivation%TYPE DEFAULT 0
)
AS
	CURSOR c IS 
		SELECT 	NVL(in_user_name, user_name) user_name, 
				NVL(in_full_name, full_name) full_name, 
				NVL(in_friendly_name, friendly_name) friendly_name, 
				NVL(in_email, email) email,
				NVL(in_job_title, job_title) job_title,
				NVL(in_phone_number, phone_number) phone_number,
				NVL(in_active, User_pkg.GetAccountEnabled(in_act, in_user_sid)) active,
				NVL(in_info_xml, info_xml) info_xml,
				NVL(in_send_alerts, send_alerts) send_alerts,
				NVL(in_enable_aria, enable_aria) enable_aria,
				NVL(in_line_manager_sid, line_manager_sid) line_manager_sid,
				NVL(in_primary_user_sid, primary_region_sid) primary_region_sid,
				NVL(in_remove_roles_on_deact, remove_roles_on_deactivation) remove_roles_on_deactivation
		  FROM csr_user
		 WHERE csr_user_sid = in_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	r c%ROWTYPE;
BEGIN

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The user with sid '||in_user_sid||'  was not found');
	END IF;
	CLOSE c;

	amendUser(	
		in_act							=> in_act, 
		in_user_sid						=> in_user_sid, 
		in_user_name					=> r.user_name,
		in_full_name					=> r.full_name,
		in_friendly_name				=> r.friendly_name,
		in_email						=> r.email,
		in_job_title					=> r.job_title,
		in_phone_number					=> r.phone_number,
		in_active						=> r.active,
		in_info_xml						=> r.info_xml,
		in_send_alerts					=> r.send_alerts,
		in_enable_aria					=> r.enable_aria,
		in_line_manager_sid				=> r.line_manager_sid,
		in_primary_region_sid			=> r.primary_region_sid,
		in_remove_roles_on_deact		=> r.remove_roles_on_deactivation
	);

END;

PROCEDURE anonymiseUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_user_name					IN	CSR_USER.user_NAME%TYPE						DEFAULT SYS_GUID(),
	in_full_name					IN	CSR_USER.full_NAME%TYPE						DEFAULT SYS_GUID(),
	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE					DEFAULT SYS_GUID(),
	in_job_title					IN  CSR_USER.job_title%TYPE						DEFAULT SYS_GUID(),
	in_info_xml						IN  csr_user.info_xml%TYPE						DEFAULT NULL
)
AS
	v_is_superadmin				NUMBER(1);
	v_is_enabled 				NUMBER(1);
	v_is_anonymised				NUMBER(1);
	v_anonymised_user_name		CSR_USER.user_NAME%TYPE;
	v_has_profile 				BINARY_INTEGER;
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN

	SELECT COUNT(*)
	  INTO v_is_superadmin
	  FROM csr.superadmin
	 WHERE csr_user_sid = in_user_sid;

	IF v_is_superadmin > 0 THEN
		RETURN; -- ignore
	END IF;

	SELECT account_enabled
	  INTO v_is_enabled
	  FROM security.user_table
	 WHERE sid_id = in_user_sid;

	IF v_is_enabled = 1 THEN
		RETURN; -- ignore
	END IF;

	SELECT COUNT(*)
	  INTO v_is_anonymised
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND anonymised = 1;

	IF v_is_anonymised > 0 THEN
		RETURN; -- ignore
	END IF;

	user_profile_pkg.UserHasProfile(in_user_sid, v_has_profile);

	v_anonymised_user_name := LOWER(NVL(in_user_name, SYS_GUID()));

	IF v_has_profile = 1 THEN
		DELETE FROM csr.user_profile
		 WHERE csr_user_sid = in_user_sid
		   AND app_sid = v_app_sid;
	END IF;
		-- Can't call amend user as it will add entries to the logs which will indentify the user so update table directly
		UPDATE csr_user 
		   SET user_name = v_anonymised_user_name,
			   full_name = NVL(in_full_name, SYS_GUID()),
			   friendly_name =  NVL(in_friendly_name, SYS_GUID()),
			   email = CONCAT(csr_user_sid, '@credit360.com'),
			   job_title = NVL(in_job_title, SYS_GUID()),
			   phone_number = SYS_GUID(),
			   info_xml = in_info_xml,
			   last_modified_dtm = SYSDATE,
			   send_alerts = 0,
			   user_ref = null,
			   anonymised = 1
		WHERE csr_user_sid = in_user_sid
		  AND app_sid = v_app_sid;

		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, 
			in_user_sid, 'Anonymised', 0, 1);

		IF csr.trash_pkg.IsInTrash(in_act, in_user_sid) = 1 THEN
			--Set the trash SO_NAME to the previous SO GUID
			UPDATE csr.trash t
			   SET t.so_name = v_anonymised_user_name, t.description = v_anonymised_user_name
			 WHERE t.trash_sid = in_user_sid;
		ELSE
			--Anonymise SO name
			security.securableobject_pkg.RenameSO(in_act, in_user_sid, v_anonymised_user_name);
		END IF;

		DeleteAuditLogsAfterAnonymisation(in_user_sid);
		csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_ANONYMISED, v_app_sid, in_user_sid, 'Anonymised');
END;

PROCEDURE DeleteAuditLogsAfterAnonymisation(
	in_object_sid		IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE 
	  FROM csr.audit_log
	 WHERE object_sid = in_object_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE amendUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
   	in_user_name					IN	CSR_USER.user_NAME%TYPE,
   	in_full_name					IN	CSR_USER.full_NAME%TYPE,
   	in_friendly_name				IN	CSR_USER.friendly_NAME%TYPE,
	in_email		 				IN	CSR_USER.email%TYPE,
	in_job_title					IN  CSR_USER.job_title%TYPE,
	in_phone_number					IN  CSR_USER.phone_number%TYPE,
	in_active						IN  security_pkg.T_USER_ACCOUNT_ENABLED,
	in_info_xml						IN  csr_user.info_xml%TYPE,
	in_send_alerts					IN	csr_user.send_alerts%TYPE,
	in_enable_aria					IN  csr_user.enable_aria%TYPE					DEFAULT 0,
	in_line_manager_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_primary_region_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_remove_roles_on_deact		IN	csr_user.remove_roles_on_deactivation%TYPE	DEFAULT 0
)
AS		  
	CURSOR c IS 
		SELECT cu.app_sid, cu.user_name, cu.full_name, cu.email, cu.job_title, cu.phone_number, cu.friendly_name, 
			   cu.info_xml, c.user_info_xml_fields, cu.send_alerts, cu.enable_aria,
			   cu.line_manager_sid, cu.primary_region_sid, cu.remove_roles_on_deactivation
		  FROM csr_user cu, customer c
		 WHERE cu.csr_user_sid = in_user_sid
		   AND cu.app_sid = c.app_sid
		   AND c.app_sid = SYS_CONTEXT('SECURITY','APP');

	r						c%ROWTYPE;
	v_normalized_user_name	csr_user.user_name%TYPE := LOWER(TRIM(in_user_name));
	v_friendly_name			csr_user.friendly_name%TYPE;
	v_email					csr_user.email%TYPE := TRIM(in_email); -- just in case
	v_have_edit_details_cap	BOOLEAN;
	v_is_anonymised			csr_user.anonymised%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to write to the object with sid '||in_user_sid);
	END IF;
   	
	v_have_edit_details_cap := csr_data_pkg.CheckCapability('Edit user details');
	
	SELECT anonymised
	  INTO v_is_anonymised
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	IF v_is_anonymised = 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User is anonymised '||in_user_sid);
	END IF;

	-- read some bits about the old user
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The user with sid '||in_user_sid||'  was not found');
	END IF;
	CLOSE c;

	-- if they're in the trash then don't try and rename
	IF securableobject_pkg.GetName(in_act, in_user_sid) is not null and trash_pkg.IsInTrash(in_act, in_user_sid) = 0 THEN
		securableobject_pkg.renameSo(in_act, in_user_sid, v_normalized_user_name);
	END IF;
	
	v_friendly_name := NVL(in_friendly_name, REGEXP_SUBSTR(in_FULL_NAME,'[^ ]+', 1, 1));

	IF NOT v_have_edit_details_cap THEN
		-- Throw error if a change would occur.
		IF r.user_name != v_normalized_user_name OR 
		   r.full_name != in_full_name OR 
		   r.friendly_name != v_friendly_name OR 
		   r.job_title != in_job_title OR 
		   r.phone_number != in_phone_number THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to change the user details.');
		END IF;
	END IF;
	
	UPDATE csr_user 
	   SET user_name = v_normalized_user_name,
		   full_name = in_full_name,
		   friendly_name =  v_friendly_name,
		   email = v_email,
		   job_title = in_job_title,
		   phone_number = in_phone_number,
		   info_xml = in_info_xml,
		   send_alerts = in_send_alerts,
		   enable_aria = in_enable_aria,
		   line_manager_sid = in_line_manager_sid,
		   primary_region_sid = in_primary_region_sid,
		   last_modified_dtm = SYSDATE,
		   remove_roles_on_deactivation = in_remove_roles_on_deact
	 WHERE csr_user_sid = in_user_sid	 
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	-- audit changes
	IF v_have_edit_details_cap THEN
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'User name', r.user_name, v_normalized_user_name);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Full name', r.full_name, in_full_name);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Email', r.email, in_email);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Job title', r.job_title, in_job_title);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Phone number', r.phone_number, in_phone_number);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Friendly name', r.friendly_name, v_friendly_name);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Primary region', r.primary_region_sid, in_primary_region_sid);
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
			in_user_sid, 'Remove roles on deactivation flag', r.remove_roles_on_deactivation, in_remove_roles_on_deact);
	END IF;
	
	-- info xml
	csr_data_pkg.AuditInfoXmlChanges(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, r.user_info_xml_fields, r.info_xml, in_info_xml);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Send alerts', r.send_alerts, in_send_alerts);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Enable enhanced accessibility', r.enable_aria, in_enable_aria);	
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Line manager', r.line_manager_sid, in_line_manager_sid);
	csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, r.app_sid, 
		in_user_sid, 'Primary region', r.primary_region_sid, in_primary_region_sid);
		
	IF null_pkg.ne(in_primary_region_sid, r.primary_region_sid) THEN
		audit_pkg.UNSEC_SyncRegionsForUser(in_user_sid);
	END IF;
	
	-- Change the active flag (if it isn't null and not in the trash)
	IF in_active = 1 AND trash_pkg.IsInTrash(in_act, in_user_sid) = 0 THEN
		activateUser(in_act, in_user_sid);
	ELSIF in_active = 0 THEN
		deactivateUser(in_act, in_user_sid);
	END IF;
END amendUser;

PROCEDURE SetUserEmail(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_email		 				IN	CSR_USER.email%TYPE
)
AS
	v_user_name			csr_user.user_name%TYPE;
	v_email				csr_user.email%TYPE;
BEGIN
	-- this will barf if it fails or if act has wrong permissions on user
	-- if they're in the trash then don't try and rename
	
	SELECT user_name, email
	  INTO v_user_name, v_email
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF securableobject_pkg.GetName(in_act, in_user_sid) IS NOT NULL AND trash_pkg.IsInTrash(in_act, in_user_sid) = 0 THEN
		securableobject_pkg.renameSo(in_act, in_user_sid, LOWER(v_user_name));
	END IF;
	
	IF in_email != v_email THEN
		UPDATE csr_user
		   SET email = in_email,
			   last_modified_dtm = SYSDATE
		 WHERE csr_user_sid = in_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
		
		csr_data_pkg.AuditValueChange(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'),
			in_user_sid, 'Email', v_email, in_email);
	END IF;
END;

PROCEDURE AddIndStartPoint(
	in_user_sid						IN	csr_user.csr_user_sid%TYPE,
	in_ind_sid						IN	ind.ind_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Access denied adding indicator start point with sid '||in_ind_sid);
	END IF;

	UNSEC_AddGroupMember(in_user_sid, in_ind_sid);

	INSERT INTO ind_start_point (user_sid, ind_sid)
	VALUES (in_user_sid, in_ind_sid);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'),
		csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'),
		in_user_sid, 'Added start point "{0}"',
		indicator_pkg.INTERNAL_GetIndPathString(in_ind_sid));
END;

PROCEDURE SetIndStartPoints(
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_ind_sids						IN	security_pkg.T_SID_IDS
)
AS
	v_ind_sids					security.T_SID_TABLE;
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_current_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_ind_root_sids				security_pkg.T_SID_IDS;
	v_cnt						NUMBER;
BEGIN
	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Access denied modifying indicator start points for user sid '||in_user_sid);
	END IF;
	-- delete old
	FOR r in (
		SELECT isp.user_sid, isp.ind_sid 
		  FROM ind_start_point isp, ind i
		 WHERE isp.user_sid = in_user_sid 
		   AND isp.ind_sid = i.ind_sid 
		   AND isp.app_sid = i.app_sid 
		   AND i.app_sid = v_app_sid
		   AND isp.app_sid = v_app_sid
		 MINUS
		SELECT in_user_sid, COLUMN_VALUE ind_sid
		  FROM TABLE(v_ind_sids)
	)
	LOOP
		DELETE FROM ind_start_point
		 WHERE user_sid = in_user_sid and ind_sid = r.ind_sid;

		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, r.ind_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
				'Access denied removing indicator start point with sid '||r.ind_sid);
		END IF;
		UNSEC_DeleteGroupMember(in_user_sid, r.ind_sid);

		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 
			'Removed start point "{0}"', 
			indicator_pkg.INTERNAL_GetIndPathString(r.ind_sid));
	END LOOP;

	-- insert new
	FOR r IN (
		SELECT in_user_sid, COLUMN_VALUE ind_sid FROM TABLE(v_ind_sids)
		 MINUS
		SELECT isp.user_sid, isp.ind_sid 
		  FROM ind_start_point isp, ind i
		 WHERE isp.user_sid = in_user_sid 
		   AND isp.ind_sid = i.ind_sid
		   AND isp.app_sid = i.app_sid 
		   AND i.app_sid = v_app_sid
		   AND isp.app_sid = v_app_sid
	)
	LOOP
		AddIndStartPoint(in_user_sid, r.ind_sid);
	END LOOP;

	-- lock the user row so the count is accurate
	SELECT 1
	  INTO v_cnt
	  FROM csr_user
	 WHERE app_sid = v_app_sid AND csr_user_sid = in_user_sid FOR UPDATE;

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind_start_point
	 WHERE app_sid = v_app_sid AND user_sid = in_user_sid;

	-- poke the root sid in as we must always have an ind start point
	IF v_cnt = 0 THEN
		
		-- The creating user may not have access to the root ind sid... so try and use their mount point instead.
		-- default to root_sid if the creating user doesn't have one (e.g. BuiltIn Admin)
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM ind_start_point
		 WHERE app_sid = v_app_sid AND user_sid = v_current_user_sid;
		
		IF v_cnt = 0 THEN
			SELECT ind_root_sid
			  BULK COLLECT INTO v_ind_root_sids
			  FROM customer
			 WHERE app_sid = v_app_sid;
		ELSE 
			SELECT ind_sid
			  BULK COLLECT INTO v_ind_root_sids
			  FROM ind_start_point
			 WHERE app_sid = v_app_sid
			   AND user_sid = v_current_user_sid;
		END IF;
		
		v_ind_sids := security_pkg.SidArrayToTable(v_ind_root_sids);
		
		FOR r IN (SELECT column_value ind_root_sid FROM TABLE(v_ind_sids))
		LOOP
			AddIndStartPoint(in_user_sid, r.ind_root_sid);
		END LOOP;
	END IF;
END;

PROCEDURE AddRegionStartPoint(
	in_user_sid						IN	csr_user.csr_user_sid%TYPE,
	in_region_sid					IN	region.region_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Access denied modifying region start points for user sid '||in_user_sid);
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Access denied adding region start point with sid '||in_region_sid);
	END IF;
	UNSEC_AddGroupMember(in_user_sid, in_region_sid);

	INSERT INTO region_start_point (user_sid, region_sid)
	VALUES (in_user_sid, in_region_sid);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'),
		csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'),
		in_user_sid, 'Added start point "{0}"',
		region_pkg.INTERNAL_GetRegionPathString(in_region_sid));
END;

PROCEDURE SetRegionStartPoints(
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS
)
AS
	v_region_sids					security.T_SID_TABLE;
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_current_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_region_root_sids				security_pkg.T_SID_IDS;
	v_cnt							NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Access denied modifying region start points for user sid '||in_user_sid);
	END IF;
	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	-- delete old
	FOR r in (
		SELECT rsp.user_sid, rsp.region_sid 
		  FROM region_start_point rsp, region r
		 WHERE rsp.user_sid = in_user_sid 
		   AND rsp.region_sid = r.region_sid 
		   AND rsp.app_sid = r.app_sid 
		   AND r.app_sid = v_app_sid
		   AND rsp.app_sid = v_app_sid
		 MINUS
		SELECT in_user_sid, COLUMN_VALUE region_sid
		  FROM TABLE(v_region_sids)
	) LOOP
		DELETE FROM region_start_point
		 WHERE user_sid = in_user_sid AND region_sid = r.region_sid;

		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, r.region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
				'Access denied removing region start point with sid '||r.region_sid);
		END IF;
		UNSEC_DeleteGroupMember(in_user_sid, r.region_sid);

		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 
			'Removed start point "{0}"', 
			region_pkg.INTERNAL_GetRegionPathString(r.region_sid));
	END LOOP;

	-- insert new
	FOR r IN (
		SELECT in_user_sid, COLUMN_VALUE region_sid
		  FROM TABLE(v_region_sids)
		 MINUS
		SELECT rsp.user_sid, rsp.region_sid 
		  FROM region_start_point rsp, region r
		 WHERE rsp.user_sid = in_user_sid 
		   AND rsp.region_sid = r.region_sid
		   AND rsp.app_sid = r.app_sid 
		   AND r.app_sid = v_app_sid
		   AND rsp.app_sid = v_app_sid
	) LOOP
		AddRegionStartPoint(in_user_sid, r.region_sid);
	END LOOP;
	
	-- lock the user row so the count is accurate
	SELECT 1
	  INTO v_cnt
	  FROM csr_user
	 WHERE app_sid = v_app_sid AND csr_user_sid = in_user_sid FOR UPDATE;

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM region_start_point
	 WHERE app_sid = v_app_sid AND user_sid = in_user_sid;

	-- poke the root sid in as we must always have an region start point
	IF v_cnt = 0 THEN
		
		-- The creating user may not have access to the root region sid... so try and use their mount point instead.
		-- default to root_sid if the creating user doesn't have one (e.g. BuiltIn Admin)
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM region_start_point
		 WHERE app_sid = v_app_sid AND user_sid = v_current_user_sid;
		
		IF v_cnt = 0 THEN
			SELECT region_root_sid
			  BULK COLLECT INTO v_region_root_sids
			  FROM customer
			 WHERE app_sid = v_app_sid;
		ELSE 
			SELECT region_sid
			  BULK COLLECT INTO v_region_root_sids
			  FROM region_start_point
			 WHERE app_sid = v_app_sid
			   AND user_sid = v_current_user_sid;
		END IF;
		
		v_region_sids := security_pkg.SidArrayToTable(v_region_root_sids);

		FOR r IN (SELECT column_value region_root_sid FROM TABLE(v_region_sids))
		LOOP
			AddRegionStartPoint(in_user_sid, r.region_root_sid);
		END LOOP;
	END IF;
	
	chain.filter_pkg.ClearCacheForUser (
		in_user_sid => in_user_sid
	);
END;

/**
 * Activates a user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE activateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check the old active flag and only do this once to prevent excess audit log entries
	IF User_pkg.GetAccountEnabled(in_act, in_user_sid) = 1 THEN
		RETURN;
	END IF;
	
	SELECT app_sid 
	  INTO v_app_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	UPDATE chain.chain_user
	   SET deleted = 0
	 WHERE user_sid = in_user_sid;

	User_pkg.EnableAccount(in_act, in_user_sid);
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Activated');
END;

/**
 * Deactivates a user's account, optionally clearing the send_alerts flag.
 *
 * @param in_act						Access token
 * @param in_user_sid					User sid
 * @param in_disable_alerts				If nonzero, prevents the user from receiving future alerts by
 *										clearing the send_alerts flag on the csr_user table.
 * @param in_raise_user_inactive_alert	If nonzero user inactive (manual) alert is raised else not
 */
PROCEDURE deactivateUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID,
	in_disable_alerts				IN	NUMBER DEFAULT 0,
	in_raise_user_inactive_alert	IN	NUMBER DEFAULT 1,
	in_remove_from_roles			IN	NUMBER DEFAULT 0
)
AS		  
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	IF in_disable_alerts != 0 THEN
		UPDATE csr_user
		   SET send_alerts = 0 
		 WHERE csr_user_sid = in_user_sid
		   AND app_sid = v_app_sid
		   AND send_alerts != 0;
	END IF;

	IF in_remove_from_roles = 1 THEN
		role_pkg.DeleteAllRolesFromUser(in_user_sid);
	END IF;

	-- Check the old active flag and only do this once to prevent excess audit log entries
	IF User_pkg.GetAccountEnabled(in_act, in_user_sid) != 0 THEN
		user_pkg.DisableAccount(in_act, in_user_sid);
		csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Deactivated');

		IF in_raise_user_inactive_alert != 0 THEN
			RaiseUserInactiveManAlert(in_user_sid, v_app_sid);
		END IF;
	END IF;
	
END;

/**
 * Deletes (deactivates and puts in trash) user's account
 *
 * @param in_act						Access token
 * @param in_user_sid					User Sid
 */
PROCEDURE DeleteUser(
	in_act			 				IN	security_pkg.T_ACT_ID,
	in_user_sid		 				IN	security_pkg.T_SID_ID
)
AS		  
	v_app_sid		security_pkg.T_SID_ID;
	v_user_name		csr_user.user_name%TYPE;
BEGIN
	-- Exclude superadmins. They're a pain to restore when deleted by mistake. If you want to delete a superadmin,
	-- make it a normal logon first.
	SELECT app_sid, user_name
	  INTO v_app_sid, v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid	   
	   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND NOT EXISTS(SELECT 1 FROM superadmin WHERE csr_user_sid = in_user_sid);

	csr_user_pkg.deactivateUser(in_act, in_user_sid, in_disable_alerts=>1, in_remove_from_roles=>1);
	
	-- don't continue if already in trash prevent excess audit log entries
	IF trash_pkg.IsInTrash(in_act, in_user_sid) = 1 THEN
		RETURN;
	END IF;

	trash_pkg.TrashObject(in_act, in_user_sid, 
		securableobject_pkg.GetSIDFromPath(in_act, v_app_sid, 'Trash'), v_user_name);

	UPDATE chain.chain_user
	   SET deleted = 1
	 WHERE user_sid = in_user_sid;
	
	-- as they are deleted they can't cover anyone anymore or be covered by anyone
	FOR r IN (
		SELECT user_cover_id 
		  FROM user_cover
		 WHERE app_sid = security_pkg.getApp
		   AND ((user_giving_cover_sid = in_user_sid) OR (user_being_covered_sid = in_user_sid))
	) LOOP
		user_cover_pkg.FullyEndCover(r.user_cover_id);
	END LOOP;
	
	-- remove them from child users
	UPDATE csr_user
	   SET line_manager_sid = NULL,
		   last_modified_dtm = SYSDATE
	 WHERE line_manager_sid = in_user_sid;
	 
	-- FB 14468 -- fair point.
	DELETE FROM delegation_user
	  WHERE user_sid = in_user_sid;
	  
	  
	-- XXX: what if this delegation now has no users?
	-- ideally the UI should warn the user in this situation.
	
	--Templated reports settings
	UPDATE tpl_report_sched_batch_run
	   SET next_fire_time = NULL
	 WHERE schedule_sid IN (
		SELECT schedule_sid
		  FROM tpl_report_schedule
		 WHERE owner_user_sid = in_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
	 );
	
	UPDATE tpl_report_schedule
	   SET owner_user_sid = NULL
	 WHERE owner_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');	
	
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, v_app_sid, in_user_sid, 'Deleted');
END;

PROCEDURE AddAutoCreateUser(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_name			IN	autocreate_user.user_name%TYPE,
	out_guid 				OUT Security_Pkg.T_ACT_ID
)
AS
BEGIN
	-- we send back a GUID so that the client's intranet server can get their
	-- client to forward the GUID to us and we know it's really them
	out_guid := user_pkg.GenerateACT;
	
	BEGIN
		INSERT INTO autocreate_user 
			(app_sid, user_name, guid, requested_dtm) 
		VALUES
			(in_app_sid, LOWER(in_user_name), TRIM(out_guid), SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- just update the requested date, keep the GUID just in case they request 
			-- twice in quick succession or something
			UPDATE autocreate_user
			   SET requested_dtm = SYSDATE
			 WHERE app_sid = in_app_sid
		       AND user_name = LOWER(in_user_name)
		  RETURNING guid INTO out_guid;
	END;
END AddAutoCreateUser;

PROCEDURE GetAutoCreateUser(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT created_user_sid, user_name 
		  FROM autocreate_user
		 WHERE guid = in_guid
           AND app_sid = in_app_sid;
END;

PROCEDURE GetAutoCreateUserBySid(
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT guid
		  FROM autocreate_user
		 WHERE created_user_sid = in_user_sid;
	
END;

PROCEDURE GetUser(
	in_act 							IN	security_pkg.T_ACT_ID,
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN 
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading information for the user with sid '||in_user_sid);
	END IF;
	GetUser_INSECURE(in_user_sid, out_cur);
END;

PROCEDURE GetUserAndStartPoints(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_user_cur					OUT SYS_REFCURSOR,
	out_isp_cur						OUT SYS_REFCURSOR,
	out_rsp_cur						OUT SYS_REFCURSOR
)
AS
BEGIN 
	GetUser(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, out_user_cur);
	
	OPEN out_isp_cur FOR
		SELECT isp.ind_sid, id.description
		  FROM ind_start_point isp, ind_description id
		 WHERE isp.user_sid = in_user_sid
	 	   AND id.app_sid = isp.app_sid AND id.ind_sid = isp.ind_sid
	   	   AND id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

	OPEN out_rsp_cur FOR
		SELECT rsp.region_sid, rd.description
		  FROM region_start_point rsp, region_description rd
		 WHERE rsp.user_sid = in_user_sid
	 	   AND rd.app_sid = rsp.app_sid AND rd.region_sid = rsp.region_sid
	   	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
END;

PROCEDURE GetCurrentUserAndStartPoints(
	out_user_cur					OUT SYS_REFCURSOR,
	out_isp_cur						OUT SYS_REFCURSOR,
	out_rsp_cur						OUT SYS_REFCURSOR
)
AS
BEGIN 
	GetUserAndStartPoints(SYS_CONTEXT('SECURITY', 'SID'), out_user_cur, out_isp_cur, out_rsp_cur);
END;

PROCEDURE GetUser_INSECURE(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_context_original_sid			NUMBER;
	v_cookie_policy_accepted 		cookie_policy_consent.accepted%TYPE DEFAULT 0;
BEGIN
	SELECT SYS_CONTEXT('SECURITY', 'ORIGINAL_LOGIN_SID')
	  INTO v_context_original_sid
	  FROM DUAL;

	IF v_context_original_sid IS NOT NULL AND in_user_sid != v_context_original_sid THEN
		v_cookie_policy_accepted := 1;
	ELSE
		BEGIN
			SELECT accepted
			  INTO v_cookie_policy_accepted
			  FROM ( 
				SELECT cpc.accepted, RANK() OVER (ORDER BY cookie_policy_consent_id DESC) rn
				  FROM cookie_policy_consent cpc
				 WHERE cpc.app_sid = SYS_CONTEXT('SECURITY','APP')
				   AND cpc.csr_user_sid = in_user_sid 
				   AND cpc.created_dtm > SYSDATE - 365
			  )
			 WHERE rn = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	OPEN out_cur FOR
        -- TODO: remove last_logon_dtm_fmt??
		SELECT cu.csr_user_sid, cu.guid, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm,
			   TO_CHAR(ut.last_but_one_logon, 'Dy, dd Mon yyyy hh24:mi')||' GMT' last_logon_dtm_fmt,
			   cu.app_sid, ut.account_enabled active, extract(cu.info_xml,'/').getClobVal() info_xml, ut.last_but_one_logon,
			   ut.expiration_dtm, cu.remove_roles_on_deactivation,
			   cu.send_alerts, cu.job_title, cu.email, cu.enable_aria, cu.phone_number, 
			   cu.line_manager_sid, mu.full_name line_manager_full_name, cu.hidden,
			   cu.primary_region_sid, pr.description primary_region_name, cu.user_ref,
			   (SELECT region_sid 
			      FROM (
					SELECT region_sid, rownum rn FROM region_owner WHERE user_sid = in_user_sid
				  ) 
				 WHERE rn = 1
				) default_region_sid, -- TODO: alter UI to set this in a column (and drop region_owner table in favour of roles...)
			    v_cookie_policy_accepted cookie_policy_accepted, cu.anonymised
		  FROM csr_user cu
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id AND ut.sid_id = in_user_sid
		  LEFT JOIN csr_user mu ON cu.line_manager_sid = mu.csr_user_sid
		  LEFT JOIN v$region pr ON cu.primary_region_sid = pr.region_sid
		 WHERE cu.csr_user_sid = in_user_sid 
		   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetUsers(
	in_user_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_user_cur					OUT	SYS_REFCURSOR
)
AS
	v_user_sids						security.T_ORDERED_SID_TABLE;
	v_ordered_user_sids				security.T_ORDERED_SID_TABLE;
	v_allowed_user_sids				security.T_SO_TABLE;
	v_first_sid						csr_user.csr_user_sid%TYPE;
BEGIN
	-- Check the permissions / existence of user sids as directed
	v_ordered_user_sids := security_pkg.SidArrayToOrderedTable(in_user_sids);
	v_allowed_user_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security_pkg.SidArrayToTable(in_user_sids), 
		security_pkg.PERMISSION_READ
	);

	-- skipping missing and denied can be done in one step
	-- paths: skip missing=M, skip denied=D MD; cases 00, 01, 10, 11
	IF in_skip_missing = 1 AND in_skip_denied = 1 THEN -- 11
		SELECT security.T_ORDERED_SID_ROW(ou.sid_id, ou.pos)
		  BULK COLLECT INTO v_user_sids
		  FROM csr_user cu,
		  	   TABLE(v_ordered_user_sids) ou,
		  	   TABLE(v_allowed_user_sids) au
		 WHERE cu.csr_user_sid = ou.sid_id
		   AND au.sid_id = cu.csr_user_sid
		   AND au.sid_id = ou.sid_id;
		   
	-- otherwise check separately, according to preferences
	ELSE
		IF in_skip_missing = 1 THEN -- 10 (M=1 and D!=1 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(ou.sid_id, ou.pos)
			  BULK COLLECT INTO v_user_sids
			  FROM csr_user cu,
			  	   TABLE(v_ordered_user_sids) ou
			 WHERE cu.csr_user_sid = ou.sid_id;
			 
			v_ordered_user_sids := v_user_sids;
		ELSE -- 00 or 01
			-- report missing, if any
			SELECT MIN(ou.sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_user_sids) ou
			  LEFT JOIN csr_user cu
			    ON cu.csr_user_sid = ou.sid_id
			 WHERE cu.csr_user_sid IS NULL;

			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The user with sid '||v_first_sid||' does not exist');			
			END IF;
		END IF;
		
		IF in_skip_denied = 1 THEN -- 01 (D=1 and M!=0 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(ou.sid_id, ou.pos)
			  BULK COLLECT INTO v_user_sids
			  FROM TABLE(v_allowed_user_sids) au
			  JOIN TABLE(v_ordered_user_sids) ou
			    ON au.sid_id = ou.sid_id;
		ELSE -- 00 or 10
			SELECT MIN(sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_user_sids)
			 WHERE sid_id NOT IN (
			 		SELECT sid_id
			 		  FROM TABLE(v_allowed_user_sids));
			  
			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
					'Read permission denied on the user with sid '||v_first_sid);
			END IF;
			
			-- 00 => no user sids set, use input
			IF in_skip_missing = 0 THEN
				v_user_sids := v_ordered_user_sids;
			END IF;
		END IF;
	END IF;
	
	OPEN out_user_cur FOR
		SELECT cu.csr_user_sid, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.account_enabled active
		  FROM TABLE(v_user_sids) s, csr_user cu, security.user_table ut
		 WHERE s.sid_id = cu.csr_user_sid
		   AND cu.csr_user_sid = ut.sid_id;
END;

PROCEDURE GetUserBasicDetails(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	CheckRegisteredUser();
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.friendly_name, cu.email, cu.primary_region_sid, ut.account_enabled active
		  FROM csr_user cu, security.user_table ut
		 WHERE cu.csr_user_sid = in_user_sid AND cu.csr_user_sid = ut.sid_id	   
		   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

-- Returns a mapping of groups as they appear in security.group_members to the groups whose membership they imply
-- In the returned table, sid_id is the column to join to security.group_members and parent_sid_id is the implied group membership.
FUNCTION GetGroupMembershipLookup
RETURN security.T_SO_TABLE
AS
	v_table								security.T_SO_TABLE;
	v_groups_sid						security.security_pkg.T_SID_ID;
	v_groups_table						security.T_SO_TABLE;
BEGIN
	BEGIN
		v_groups_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Groups');
		v_groups_table := SecurableObject_pkg.GetChildrenAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_groups_sid);
	EXCEPTION
		WHEN OTHERS THEN
			IF SQLCODE = security.security_pkg.ERR_ACCESS_DENIED THEN
				v_groups_table := security.T_SO_TABLE();
			ELSE
				RAISE;
			END IF;
	END;
	
	SELECT security.T_SO_ROW(sid_id, root_sid_id, NULL, NULL, NULL, NULL, NULL)
	  BULK COLLECT INTO v_table
	  FROM (
			SELECT sid_id, CONNECT_BY_ROOT sid_id root_sid_id
			  FROM (
					SELECT so.sid_id, gm.member_sid_id
					  FROM security.securable_object so
					  LEFT JOIN security.group_members gm ON gm.group_sid_id = so.sid_id
			  )
			  START WITH sid_id IN ( SELECT DISTINCT sid_id FROM TABLE(v_groups_table) )
		   	CONNECT BY NOCYCLE PRIOR member_sid_id = sid_id
	  ) GROUP BY sid_id, root_sid_id;

	RETURN v_table;
END;

PROCEDURE GetUserBasicDetails(
	in_user_sid 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR,
	out_groups_cur					OUT SYS_REFCURSOR
)
AS
	v_groups_lookup					security.T_SO_TABLE := GetGroupMembershipLookup;
BEGIN
	-- this does the security
	GetUserBasicDetails(in_user_sid, out_cur);
	
	OPEN out_groups_cur FOR
		SELECT so.sid_id group_sid, so.parent_sid_id parent_sid, so.name
		  FROM security.securable_object so
		  JOIN (
				SELECT gl.parent_sid_id
				  FROM TABLE(v_groups_lookup) gl
				  JOIN security.group_members gm ON gm.group_sid_id = gl.sid_id
				 WHERE gm.member_sid_id = in_user_sid
			  GROUP BY gl.parent_sid_id
		  ) t ON so.sid_id = t.parent_sid_id
		ORDER BY group_sid;
END;

PROCEDURE GetUserLineManager(
	in_act							IN	security_pkg.T_ACT_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_mgr_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading line manager for the user with sid '||in_user_sid);
	END IF;
	
	SELECT line_manager_sid
	  INTO v_mgr_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_mgr_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'No line manager found for user with sid '||in_user_sid);
	END IF;

	GetUser_INSECURE(v_mgr_sid, out_cur);
END;

FUNCTION UNSEC_GetRegStartPointsAsTable(
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT NULL
)
RETURN security.T_SID_TABLE
AS
	v_result						security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_result
	  FROM region_start_point
	 WHERE user_sid = in_user_sid;
	RETURN v_result;
END;

FUNCTION GetRegionStartPointsAsTable(
	in_user_sid						IN	security_pkg.T_SID_ID
)
RETURN security.T_SID_TABLE
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading information for the user with sid '||in_user_sid);
	END IF;
	RETURN UNSEC_GetRegStartPointsAsTable(in_user_sid);
END;

FUNCTION GetRegionStartPointsAsTable
RETURN security.T_SID_TABLE
AS
BEGIN
	RETURN UNSEC_GetRegStartPointsAsTable(SYS_CONTEXT('SECURITY', 'SID'));
END;

PROCEDURE GetAllUsers(
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	in_group_sid					IN 	security_pkg.T_SID_ID,
	in_filter_name					IN  csr_user.full_name%TYPE,
	in_role_sid						IN 	security_pkg.T_SID_ID,
	in_region_sid					IN 	security_pkg.T_SID_ID,
	in_include_forms				IN  INTEGER,
	in_menu_permissions				IN  INTEGER,
	out_users						OUT SYS_REFCURSOR,
	out_groups						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_roles						OUT SYS_REFCURSOR,
	out_ind_start_points			OUT SYS_REFCURSOR,
	out_region_start_points			OUT SYS_REFCURSOR,
	out_extra_fields				OUT SYS_REFCURSOR,
	out_forms						OUT SYS_REFCURSOR,
	out_menu						OUT SYS_REFCURSOR,
	out_user_groups					OUT SYS_REFCURSOR,
	out_group_members				OUT SYS_REFCURSOR,
	out_menu_permissions			OUT SYS_REFCURSOR
)
IS
	v_has_filter				NUMBER;
	v_selected_user_sids		security.T_SID_TABLE;
	v_users_sid					security_pkg.T_SID_ID;
	v_menu_root_node_sid		security_pkg.T_SID_ID;
	v_setup_menu_sid			security_pkg.T_SID_ID;
	v_login_menu_sid			security_pkg.T_SID_ID;
	v_logout_menu_sid			security_pkg.T_SID_ID;
	v_user_groups_sid			security_pkg.T_SID_ID;
BEGIN
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF in_group_sid > -1 OR in_role_sid > -1 OR in_region_sid > -1 THEN
		v_has_filter := 1;
	ELSE
		v_has_filter := 0;
	END IF;
	
	IF v_has_filter = 0 THEN
		SELECT cu.csr_user_sid
		  BULK COLLECT INTO v_selected_user_sids
		  FROM v$csr_user cu
		 WHERE cu.hidden = 0
		   AND cu.parent_sid_id = v_users_sid
		   AND user_name !='UserCreatorDaemon'
		   AND (( lower(cu.full_name) LIKE '%'||in_filter_name||'%' OR lower(cu.user_name) LIKE '%'||in_filter_name||'%' )
				OR in_filter_name IS NULL);
	ELSE
		SELECT cu.csr_user_sid
		  BULK COLLECT INTO v_selected_user_sids
		  FROM v$csr_user cu
		 WHERE cu.hidden = 0
		   AND user_name !='UserCreatorDaemon'
		   AND cu.parent_sid_id = v_users_sid
		   AND (( lower(cu.full_name) LIKE '%'||in_filter_name||'%' OR lower(cu.user_name) LIKE '%'||in_filter_name||'%' )
				OR in_filter_name IS NULL)
		   AND (in_group_sid IS NULL OR in_group_sid = -1 OR cu.csr_user_sid IN (
				SELECT sid_id FROM TABLE(security.Group_Pkg.GetMembersAsTable(in_act_id, in_group_sid))
		   ))
		   AND (in_role_sid IS NULL OR in_role_sid = -1 OR cu.csr_user_sid IN (
				SELECT user_sid FROM region_role_member WHERE role_sid = in_role_sid
		   ))
		   AND (in_region_sid IS NULL OR in_region_sid = -1 OR cu.csr_user_sid IN (
				SELECT user_sid FROM region_role_member WHERE region_sid = in_region_sid
		   ));
	END IF;

	OPEN out_users FOR
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid, cu.active, cu.user_name, cu.full_name, cu.friendly_name, cu.email,
			   cu.last_logon last_logon_dtm, lt.label last_logon_type, cu.created_dtm, cu.line_manager_sid,
			   cu.expiration_dtm, cu.language, cu.culture, cu.timezone, cu.info_xml, cu.send_alerts,
			   mu.full_name line_manager_full_name, NVL(mu.active,0) line_manager_active, cu.user_ref
		  FROM v$csr_user cu
		  JOIN logon_type lt ON cu.last_logon_type_id = lt.logon_type_id
		  LEFT JOIN superadmin sa ON cu.csr_user_sid = sa.csr_user_sid
		  LEFT JOIN v$csr_user mu ON cu.line_manager_sid = mu.csr_user_sid
		 WHERE cu.csr_user_sid IN (
			SELECT column_value FROM TABLE(v_selected_user_sids)
		 )
		   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP')
		 ORDER BY cu.user_name;

	OPEN out_groups FOR
		SELECT so.sid_id group_sid, so.parent_sid_id parent_sid, so.class_id, so.name, cu.csr_user_sid
		  FROM security.securable_object so, security.group_members gm, v$csr_user cu
		 WHERE so.sid_id = gm.group_sid_id
		   AND gm.member_sid_id = cu.csr_user_sid
		   AND so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_regions FOR
		SELECT cu.csr_user_sid, r.region_sid, r.description
		  FROM v$region r, region_owner ro, v$csr_user cu
		 WHERE r.region_sid = ro.region_sid
		   AND ro.user_sid = cu.csr_user_sid
		   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.csr_user_sid IN (
			SELECT column_value FROM TABLE(v_selected_user_sids)
		   );

	OPEN out_roles FOR
		SELECT r.name role_name, reg.description region_description, cu.csr_user_sid
		  FROM role r, region_role_member rrm, v$region reg, v$csr_user cu
		 WHERE r.role_sid = rrm.role_sid
		   AND rrm.user_Sid = cu.csr_user_sid
		   AND rrm.region_sid = reg.region_sid
		   AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
		   AND reg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.csr_user_sid IN (
			SELECT column_value FROM TABLE(v_selected_user_sids)
		   )
		 ORDER BY role_name, region_description;

	OPEN out_ind_start_points FOR
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid, i.ind_sid, i.description
		  FROM v$csr_user cu, ind_start_point isp, v$ind i
		 WHERE isp.app_sid = cu.app_sid AND isp.user_sid = cu.csr_user_sid 
		   AND isp.app_sid = i.app_sid AND isp.ind_sid = i.ind_sid
		   AND cu.csr_user_sid IN (
			SELECT column_value FROM TABLE(v_selected_user_sids)
		   )
		 ORDER BY cu.csr_user_sid;

	OPEN out_region_start_points FOR
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid, r.region_sid, r.description
		  FROM v$csr_user cu, region_start_point rsp, v$region r
		 WHERE rsp.app_sid = cu.app_sid AND rsp.user_sid = cu.csr_user_sid 
		   AND rsp.app_sid = r.app_sid AND rsp.region_sid = r.region_sid
		   AND cu.csr_user_sid IN (
			SELECT column_value FROM TABLE(v_selected_user_sids)
		   )
		 ORDER BY cu.csr_user_sid;

	OPEN out_extra_fields FOR
		SELECT user_info_xml_fields 
		  FROM customer 
		 WHERE app_sid = in_app_sid;

	IF in_include_forms = 1 THEN
		OPEN out_forms FOR
			SELECT du.user_sid, d.name, d.start_dtm, d.end_dtm
			  FROM delegation_user du
			  JOIN delegation d ON d.delegation_sid = du.delegation_sid
			 ORDER BY du.user_sid;
	END IF;
	
	IF in_menu_permissions = 1 THEN	
		
		v_menu_root_node_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'Menu');
	
		BEGIN
			SELECT m.sid_id
			  INTO v_setup_menu_sid
			  FROM security.menu m
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			 WHERE m.action = '/csr/site/admin/config/global.acds'
			   AND so.parent_sid_id = v_menu_root_node_sid;
		EXCEPTION
			 WHEN NO_DATA_FOUND
			 THEN v_setup_menu_sid := -1; -- just handling sites that don't have the setup tab (i.e. example.credit360.com')
		END;
		
		BEGIN
			v_login_menu_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'menu/login');
		EXCEPTION
			 WHEN security.Security_Pkg.OBJECT_NOT_FOUND
			 THEN v_login_menu_sid := -1;
		END;
		
		BEGIN
			v_logout_menu_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'menu/logout');
		EXCEPTION
			 WHEN security.Security_Pkg.OBJECT_NOT_FOUND
			 THEN v_logout_menu_sid := -1;
		END;
		
		OPEN out_menu FOR
			SELECT so.sid_id, so.parent_sid_id, so.name, so.dacl_id, level so_level, rownum rown, m.description, m.action, m.pos, m.context
			  FROM security.securable_object so, security.menu m
			 WHERE so.sid_id NOT IN (v_setup_menu_sid, v_login_menu_sid, v_logout_menu_sid)
			   AND so.parent_sid_id NOT IN (v_setup_menu_sid)
			   AND so.sid_id = m.sid_id
			 START WITH so.parent_sid_id = v_menu_root_node_sid
			 CONNECT BY PRIOR so.sid_id = so.parent_sid_id
			 ORDER SIBLINGS BY m.pos;
		
		v_user_groups_sid := security.securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'groups');
		
		OPEN out_user_groups FOR
			SELECT sid_id, name
			  FROM security.securable_object
			 WHERE parent_sid_id IN (v_user_groups_sid)
			   AND application_sid_id = in_app_sid
			   AND name != 'Everyone'
			 ORDER BY name;

		OPEN out_group_members FOR
			SELECT gm.group_sid_id, so.sid_id member
			  FROM security.group_members gm
			  JOIN security.securable_object so ON gm.member_sid_id = so.sid_id
			 WHERE group_sid_id IN (SELECT sid_id
									  FROM security.securable_object
									 WHERE class_id IN (SELECT DISTINCT class_id
									                      FROM security.securable_object
														 WHERE parent_sid_id IN (v_user_groups_sid))
									   AND application_sid_id = in_app_sid)
			   AND so.class_id = class_pkg.GetClassId('CSRUser')
			 ORDER BY gm.group_sid_id;
		
		OPEN out_menu_permissions FOR
			WITH g as ( -- get user groups for the site
			SELECT sid_id, name
			  FROM security.securable_object
			 WHERE parent_sid_id = v_user_groups_sid 
			   AND application_sid_id = in_app_sid
			 ORDER BY name)
			,m as ( -- get menu items for the site
			SELECT so.sid_id, so.parent_sid_id, so.name, so.dacl_id, level so_level, rownum rown, m.description, m.action, m.pos, m.context
			  FROM security.securable_object so, security.menu m
			 WHERE so.sid_id = m.sid_id
				   START WITH so.parent_sid_id = v_menu_root_node_sid
				   CONNECT BY PRIOR so.sid_id = so.parent_sid_id
				   ORDER SIBLINGS BY m.pos)
			 -- check permissions on each menu item for each group (the ones that are returned have read access)
			 SELECT m.sid_id as menu_sid, g.sid_id as group_sid, a.ace_type
			   FROM g
			   JOIN security.acl a ON a.sid_id = g.sid_id
			   JOIN m ON a.acl_id = m.dacl_id
			  WHERE bitand(a.permission_set,1) = 1
			  ORDER BY m.sid_id, a.acl_index;
		
	END IF;
	
END;


/**
 * Gets list of all users
 *
 * @param in_act						Access token.
 * @param in_app_sid				THe CSR schema
 * 
 * The output rowset is of the form:
 * csr_user_sid, user_name, full_name, email, last_logon_dtm
 *
 * WHAT IS THE PURPOSE OF in_parent_sid
 */
-- seems to be just called by \site\forms\allocateUsers.xml
-- TODO: try to can at some point?
PROCEDURE GetAllActiveUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_parent_sid 	IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_order_by 	IN VARCHAR2, 
	out_cur			OUT SYS_REFCURSOR
)
IS	   
	v_order_by	VARCHAR2(1000);
BEGIN				   		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'csr_user_sid,active,user_name,full_name,friendly_name,email,last_logon_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;


	IF in_group_sid IS NULL OR in_group_sid=-1 THEN
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm, TO_CHAR(ut.last_logon,''Dy dd-Mon-yyyy hh24:mi'')||'' GMT'' last_logon_formatted' 
			||' FROM CSR_USER cu,'
            ||' TABLE(security.securableobject_Pkg.GetChildrenAsTable(:act_id, :parent_sid))t, security.user_table ut '
			||' WHERE t.sid_id = cu.csr_user_sid AND t.sid_id = ut.sid_id AND ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1 AND cu.hidden = 0'||v_order_by USING in_act_id, in_parent_sid;
	ELSE						
		OPEN out_cur FOR
			'SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.friendly_name, cu.email, ut.last_logon last_logon_dtm, TO_CHAR(ut.last_logon,''Dy dd-Mon-yyyy hh24:mi'')||'' GMT'' last_logon_formatted' 
			||' FROM CSR_USER cu, '
			||' TABLE(security.Group_Pkg.GetMembersAsTable(:act_id, :group_sid))g, security.user_table ut '
			||' WHERE g.sid_id = cu.csr_user_sid AND g.sid_id = ut.sid_id AND ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1 AND cu.hidden = 0'||v_order_by USING in_act_id, in_group_sid;
	END IF;	
	-- 
  
END;


/*
XXX: try to can this 
*/
PROCEDURE GetUsers(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,	 
	out_cur			OUT SYS_REFCURSOR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, 
			TO_CHAR(ut.last_logon,'Dy dd-Mon-yyyy hh24:mi')||' GMT' last_logon_formatted
		  FROM csr_user cu, security.user_table ut
		 WHERE app_sid = in_app_sid AND ut.sid_id = cu.csr_user_sid AND cu.hidden = 0;
END;


/*
just called by:
site\delegation\auditTrail.xml
site\objectives\objectivePane.xml
*/
PROCEDURE GetUsers_ASP(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,	 
	out_cur			OUT SYS_REFCURSOR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, 
			TO_CHAR(ut.last_logon,'Dy dd-Mon-yyyy hh24:mi')||' GMT' last_logon_formatted
		  FROM csr_user cu, security.user_table ut
		 WHERE app_sid = in_app_sid AND ut.sid_id = cu.csr_user_sid AND cu.hidden = 0;
END;


-- appears to be unused
-- XXX: try to can this
PROCEDURE GetUsersInGroup(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,
	in_group_sid	IN 	security_pkg.T_SID_ID, 	 
	out_cur			OUT SYS_REFCURSOR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, ut.account_enabled active, cu.user_name, cu.full_name, cu.email, ut.last_logon last_logon_dtm, 
			   TO_CHAR(ut.last_logon,'Dy dd-Mon-yyyy hh24:mi')|| ' GMT' last_logon_formatted
		  FROM csr_user cu, security.user_table ut, TABLE(security.Group_Pkg.GetMembersAsTable(in_act_id, in_group_sid))g
		 WHERE app_sid = in_app_sid 
		   AND g.sid_id = cu.csr_user_sid AND g.sid_id = ut.sid_id AND cu.csr_user_sid = ut.sid_id AND cu.hidden = 0 
		   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

-- Used by Export Framework; User exporter.
PROCEDURE GetUsersWithGroupsAndRoles(
	out_user_cur		OUT	SYS_REFCURSOR,
	out_roles_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
)
AS
	v_users_sid				security.security_pkg.T_SID_ID;
	v_group_class_id		security.security_pkg.T_CLASS_ID;
	v_user_class_id			security.security_pkg.T_CLASS_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID;
BEGIN

	/* SECURITY! */
	-- Checking read access on the root "Users" node; This SP is used by batch exports and should be running
	-- in the builtin admin context, and this have this permission. But here just in case!
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users');
	
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_users_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading Users');
	END IF;

	 v_group_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	 v_user_class_id := security.class_pkg.GetClassId('CSRUser');
	
	OPEN out_user_cur FOR
		SELECT csr_user_sid, email, full_name, user_name, send_alerts, friendly_name, info_xml,
			   hidden, active, last_logon, created_dtm, expiration_dtm, language, 
			   culture, timezone, line_manager_sid, primary_region_sid
		  FROM v$csr_user
		 WHERE parent_sid_id = v_users_sid
		   AND app_sid = v_app_sid;
	
	OPEN out_roles_cur FOR
		SELECT rrm.user_sid, rrm.region_sid, rrm.role_sid, rrm.inherited_from_sid, re.description region_description, ro.name role_name
		  FROM region_role_member rrm
		  JOIN v$region re 	ON rrm.region_sid = re.region_sid
		  JOIN role ro 		ON rrm.role_sid = ro.role_sid
		  JOIN security.securable_object so ON rrm.user_sid = so.sid_id
		 WHERE so.parent_sid_id = v_users_sid
		   AND rrm.app_sid = v_app_sid;

	OPEN out_groups_cur FOR
		SELECT member_sid_id, group_sid_id
		  FROM security.group_members gm
		  JOIN security.securable_object so ON gm.group_sid_id = so.sid_id
		  JOIN security.securable_object so2 ON gm.member_sid_id = so2.sid_id
		 WHERE so.class_id = v_group_class_id
		   AND so2.class_id = v_user_class_id
		   AND so.application_sid_id = v_app_sid
		   and so2.parent_sid_id = v_users_sid
		 ORDER BY member_sid_id;

END;

PROCEDURE Search(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr_user.full_name%TYPE,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT SYS_REFCURSOR
)
IS	   
BEGIN				   		
	Search(in_act_id, in_app_sid, in_group_sid, NULL, NULL, in_filter_name, in_order_by, out_cur);
END;

/**
 * Gets a list of users matching specified search criteria.
 * 
 * @param in_act_id				The requesting user's access token.
 *
 *								Required permissions:
 *									- PERMISSION_LIST_CONTENTS on in_app_sid/Users
 *									- PERMISSION_READ on in_group_sid (if specified)
 *									- PERMISSION_READ on in_region_sid (if specified)
 *									- PERMISSION_READ on in_role_sid (if specified)
 *
 * @param in_app_sid			The sid of the application/CSR object to search under.
 *
 * @param in_group_sid			The sid of the group to filter users by, or null.
 *
 * @param in_role_sid			The sid of the role to filter users by, or null. 
 *
 * @param in_region_sid			The sid of the region to filter users by, or null. Users in a role for the specified 
 *								region either explicitly or by inheritance (or any region not specified) are returned.
 *
 * @param in_filter_name		A case-insensitive string to filter full names by, or null.
 *
 * @param in_order_by			A string containing the comma-delimited list of columns to order the results by, or 
 *								null to use the default order (last_logon_dtm desc). Any valid ORDER BY clause can be
 *								used here, but must be limited to sorting on the following columns: csr_user_sid, 
 *								active, user_name, full_name, email, last_logon_dtm, created_dtm.
 *
 * @param out_cur				A cursor that yields the result set:
 *
 *							 		Name                                      Null?    Type
 *							 		----------------------------------------- -------- ----------------------------
 *							 		CSR_USER_SID                              NOT NULL NUMBER(10)
 *							 		ACTIVE                                    NOT NULL NUMBER(1)
 *							 		USER_NAME                                 NOT NULL VARCHAR2(256)
 *							 		FULL_NAME                                          VARCHAR2(256)
 *							 		EMAIL                                              VARCHAR2(256)
 *							 		LAST_LOGON_DTM                            NOT NULL DATE
 *							 		LAST_LOGON_FORMATTED                               VARCHAR2(19)
 *							 		CREATED_DTM                               NOT NULL DATE
 *							 		CREATED_FORMATTED                                  VARCHAR2(19)
 *							 		SEND_ALERTS                               NOT NULL NUMBER(1)
 */
PROCEDURE Search(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,	 
	in_group_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_role_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_filter_name	IN	csr_user.full_name%TYPE DEFAULT NULL,
	in_order_by 	IN	VARCHAR2 DEFAULT NULL, 
	out_cur			OUT	SYS_REFCURSOR
)
IS
	v_group_members		security.T_SO_TABLE;
	v_name_pattern		csr.csr_user.full_name%TYPE;
	v_sql				VARCHAR2(4000);
	v_order_by			VARCHAR2(4000);
	v_users_sid			security_pkg.T_SID_ID;
BEGIN
	-- Assert PERMISSION_LIST_CONTENTS on /Users 
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- Assert PERMISSION_READ permission on other filter parameters
	IF (in_role_sid IS NOT NULL AND 
	    NOT security_pkg.IsAccessAllowedSID(in_act_id, in_role_sid, security_pkg.PERMISSION_READ))
	OR (in_region_sid IS NOT NULL AND 
		NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ))
	OR (in_group_sid IS NOT NULL AND
		NOT security_pkg.IsAccessAllowedSID(in_act_id, in_group_sid, security_pkg.PERMISSION_READ))
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- Materialize list of group members
	IF in_group_sid IS NOT NULL THEN
		-- Note: asserts PERMISSION_READ on in_group_sid
		v_group_members := security.Group_Pkg.GetMembersAsTable(in_act_id, in_group_sid);
	END IF;

	-- Prepare ORDER BY clause
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'csr_user_sid,active,user_name,full_name,email,last_logon_dtm,created_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;

		-- ignore case and padding spaces for name sorting
		v_order_by := REPLACE(v_order_by, 'full_name', 'LOWER(LTRIM(full_name))');
	ELSE
		v_order_by := ' ORDER BY last_logon_dtm DESC';
	END IF;

	-- Convert filter into a glob
	IF in_filter_name IS NOT NULL THEN
		v_name_pattern := '%' || LOWER(in_filter_name) || '%';
	END IF;

	-- Oracle quirk: parameters are bound by position, names are documentary
	v_sql := '
		SELECT cu.csr_user_sid, 
			   ut.account_enabled active,
			   cu.user_name,
			   cu.full_name,
			   cu.email, 
			   ut.last_logon last_logon_dtm,
			   REPLACE(TO_CHAR(ut.last_logon, ''yyyy-mm-dd hh24:mi:ss''), '' '', ''T'') last_logon_formatted, 
			   cu.created_dtm,
			   REPLACE(TO_CHAR(cu.created_dtm, ''yyyy-mm-dd hh24:mi:ss''), '' '', ''T'') created_formatted,
			   cu.send_alerts
		  FROM csr.csr_user cu
		  JOIN security.securable_object so	ON cu.csr_user_sid = so.sid_id AND cu.app_sid = so.application_sid_id
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id 
		  LEFT JOIN (SELECT DISTINCT * FROM TABLE(:v_group_members)) g ON cu.csr_user_sid = g.sid_id
		 WHERE cu.app_sid = :in_app_sid 
		   AND cu.hidden = 0
		   AND so.name != ''UserCreatorDaemon''
		   AND (:v_name_pattern IS NULL OR LOWER(cu.full_name) LIKE :v_name_pattern OR LOWER(cu.user_name) LIKE :v_name_pattern)
		   AND (:in_group_sid IS NULL OR g.sid_id IS NOT NULL) ';

	-- Oracle seems to have a hard time optimising the query if we don't add this part conditionally.
	IF in_role_sid IS NOT NULL OR in_region_sid IS NOT NULL THEN
		v_sql := v_sql || '
		   AND EXISTS(	
				SELECT * 
				  FROM csr.region_role_member rrm
				 WHERE rrm.app_sid = cu.app_sid
				   AND rrm.user_sid = cu.csr_user_sid 
				   AND (:in_role_sid IS NULL OR rrm.role_sid = :in_role_sid)
				   AND (:in_region_sid IS NULL OR rrm.region_sid = :in_region_sid)
			 ) ';

		v_sql := v_sql || v_order_by;

		OPEN out_cur FOR v_sql
			USING v_group_members, in_app_sid, v_name_pattern, v_name_pattern, v_name_pattern, in_group_sid, in_role_sid,
				  in_role_sid, in_region_sid, in_region_sid; 
	ELSE 
		v_sql := v_sql || v_order_by;

		OPEN out_cur FOR v_sql
			USING v_group_members, in_app_sid, v_name_pattern, v_name_pattern, v_name_pattern, in_group_sid;
	END IF;
END;

PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
)
AS
BEGIN
	FilterUsers(in_filter, 0, out_cur, out_total_num_users);
END;

PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
)
IS
	v_no_excluded_user_sids		security_pkg.T_SID_IDS;
BEGIN
	FilterUsers(in_filter, in_include_inactive, v_no_excluded_user_sids, out_cur, out_total_num_users); 
END;

-- For RestAPI to specify user limit/max size (it needs all users).
PROCEDURE FilterUsers(  
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	in_max_size			IN	NUMBER,							-- Used to limit the number of users returned.
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
)
IS
	v_no_excluded_user_sids		security_pkg.T_SID_IDS;
BEGIN
	FilterUsers(in_filter, in_include_inactive, v_no_excluded_user_sids, in_max_size, out_cur, out_total_num_users); 
END;

PROCEDURE FilterUsers(  
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- mainly for finding users except user X - e.g. on a user edit page.
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
)
IS
	v_table					T_USER_FILTER_TABLE;
	v_exclude_user_sids		security.T_SID_TABLE;
BEGIN
	-- Filter users and limit by 500. Could be a default?
	FilterUsers(in_filter, in_include_inactive, in_exclude_user_sids, csr_user_pkg.MAX_USERS, out_cur, out_total_num_users);
END;

PROCEDURE FilterUsers(  
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- Mainly for finding users except user X - e.g. on a user edit page.
	in_max_size					IN	NUMBER,					-- Used to limit the number of users returned.
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
)
IS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_table							T_USER_FILTER_TABLE;
	v_exclude_user_sids				security.T_SID_TABLE;
	v_show_email					NUMBER;
	v_show_user_name				NUMBER;
	v_show_user_ref					NUMBER;
BEGIN
	v_exclude_user_sids := security_pkg.SidArrayToTable(in_exclude_user_sids);
	FilterUsersToTable(in_filter, in_include_inactive, v_table);

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;

	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, in_max_size max_size
		  FROM csr_user cu, TABLE(v_table) t
		 WHERE cu.csr_user_sid = t.csr_user_sid
		   AND cu.app_sid = v_app_sid
		   AND cu.csr_user_sid NOT IN (SELECT column_value FROM TABLE(v_exclude_user_sids));
	
	OPEN out_cur FOR
		SELECT csr_user_sid, full_name, email, user_name, user_ref, account_enabled, user_sid, sid,
			   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref, guid
		  FROM (
			SELECT x.csr_user_sid, x.full_name, x.email, x.user_name, x.user_ref, x.account_enabled, x.user_sid, x.sid, x.guid
			   FROM (
				SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, t.account_enabled,
					   cu.csr_user_sid user_sid, cu.csr_user_sid sid,  -- yes I know! but we use csr_user_sid AND sid in some legacy things
					   cu.guid
				  FROM csr_user cu, TABLE(v_table) t, security.user_table ut
				  -- first name, or last name (space separator)
				 WHERE cu.app_sid = security_pkg.GetApp()
				   AND cu.csr_user_sid = t.csr_user_sid
				   AND cu.csr_user_sid = ut.sid_id
				   AND cu.app_sid = v_app_sid
				   AND cu.csr_user_sid NOT IN (SELECT column_value FROM TABLE(v_exclude_user_sids))
				   AND NOT EXISTS( SELECT NULL FROM trash WHERE trash_sid = cu.csr_user_sid)
			)x
		  ORDER BY x.account_enabled DESC,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.email)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_ref)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   LOWER(TRIM(x.full_name))
		)
		WHERE ROWNUM <= in_max_size
		ORDER BY ROWNUM;
END;

PROCEDURE FilterUsersSinceDate(  
	in_filter				IN	VARCHAR2,
	in_include_inactive		IN	NUMBER DEFAULT 0,
    in_modified_since_dtm	IN	audit_log.audit_date%TYPE,
	out_users_cur			OUT SYS_REFCURSOR,
	out_user_groups_cur		OUT SYS_REFCURSOR,
	out_groups_cur			OUT SYS_REFCURSOR
)   
IS
	v_groups_lookup						security.T_SO_TABLE := GetGroupMembershipLookup;
	v_group_members_table				T_USER_GROUP_TABLE;
	v_filtered_users					T_USER_FILTER_TABLE;
	v_users_since_date					T_USER_FILTER_TABLE;
BEGIN	
	FilterUsersToTable(in_filter, in_include_inactive, v_filtered_users);
	
	IF in_modified_since_dtm IS NOT NULL THEN
		SELECT T_USER_FILTER_ROW(t.csr_user_sid, t.account_enabled, t.is_sa)
		  BULK COLLECT INTO v_users_since_date
		  FROM csr_user cu
		  JOIN TABLE(v_filtered_users) t ON cu.csr_user_sid = t.csr_user_sid
		 WHERE cu.last_modified_dtm >= in_modified_since_dtm;
	ELSE
		v_users_since_date := v_filtered_users;
	END IF;

	OPEN out_users_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, t.account_enabled,
			   cu.csr_user_sid user_sid, cu.primary_region_sid
		  FROM csr_user cu
		  JOIN TABLE(v_users_since_date) t ON cu.csr_user_sid = t.csr_user_sid;
		  
	SELECT T_USER_GROUP_ROW(user_sid, group_sid)
	  BULK COLLECT INTO v_group_members_table
	  FROM (
			SELECT gm.member_sid_id user_sid, gl.parent_sid_id group_sid
			  FROM TABLE(v_groups_lookup) gl
			  JOIN security.group_members gm ON gm.group_sid_id = gl.sid_id	 
	  ) GROUP BY user_sid, group_sid;
	  
	OPEN out_user_groups_cur FOR
		SELECT csr_user_sid user_sid, group_sid
		  FROM TABLE(v_group_members_table)
		 ORDER BY csr_user_sid, group_sid;

	OPEN out_groups_cur FOR
		SELECT so.sid_id group_sid, so.parent_sid_id parent_sid, so.name
		  FROM security.securable_object so
		 WHERE so.sid_id IN (
			SELECT DISTINCT group_sid
			  FROM TABLE(v_group_members_table)
		 )
		 ORDER BY group_sid;
END;

PROCEDURE FilterUsersToTable (
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_table			OUT T_USER_FILTER_TABLE
)
AS
	v_sa_cnt 				NUMBER(10);
	v_topco_sid				security_pkg.T_SID_ID;
	v_can_see_all_companies	NUMBER(10);
BEGIN
	CheckRegisteredUser();
	
	-- ok -- we exclude all non top-co users for chain stuff
	SELECT MIN(top_company_sid)
	  INTO v_topco_sid
	  FROM chain.customer_options
	 WHERE app_sid = security_pkg.GetApp;

	SELECT NVL(MIN(can_see_all_companies), 0)
	  INTO v_can_see_all_companies
	  FROM chain.company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	SELECT COUNT(*) 
	  INTO v_sa_cnt
	  FROM superadmin
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY','SID');

	SELECT T_USER_FILTER_ROW(cu.csr_user_sid, ut.account_enabled, CASE WHEN sa.csr_user_sid IS NOT NULL THEN 1 ELSE 0 END)
	  BULK COLLECT INTO out_table
	  FROM csr_user cu, security.user_table ut, customer c, superadmin sa
	  -- first name, or last name (space separator)
	 WHERE ((LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(cu.full_name)) LIKE '% ' || LOWER(in_filter) || '%')
	    OR (LOWER(TRIM(cu.email)) LIKE LOWER(in_filter) || '%')
	    OR (LOWER(TRIM(cu.user_name)) LIKE LOWER(in_filter) || '%')
		OR (LOWER(TRIM(cu.user_ref)) LIKE LOWER(in_filter) || '%'))
	   AND cu.app_sid = c.app_sid
	   AND ut.sid_id = cu.csr_user_sid 
	   AND cu.csr_user_sid = sa.csr_user_sid(+)
	   AND (ut.account_enabled = 1 OR in_include_inactive = 1) -- Only show active users.
	   AND (sa.csr_user_sid IS NULL OR v_sa_cnt > 0)
	   AND c.app_sid = security_pkg.GetApp() 
	   AND cu.hidden = 0  -- hidden is for excluding things like UserCreatorDaemon
	   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND (
			v_topco_sid IS NULL OR v_can_see_all_companies = 1 OR ( --this should allow filtering to work on sites with chain enabled that have users that are not members of topCo
			(chain.helper_pkg.IsSidTopCompany(SYS_CONTEXT('SECURITY','CHAIN_COMPANY')) = 1 OR SYS_CONTEXT('SECURITY','CHAIN_COMPANY') IS NULL)  --if the session company is topco or null
				AND cu.csr_user_sid NOT IN ( --select all users that are not part of supplier companies (ie. alll topco + no comp users)
					SELECT user_sid FROM chain.v$company_user WHERE company_sid <> NVL(SYS_CONTEXT('SECURITY','CHAIN_COMPANY'), v_topco_sid)
				)
			)
			OR cu.csr_user_sid IN (
				SELECT user_sid FROM chain.v$company_user WHERE company_sid = NVL(SYS_CONTEXT('SECURITY','CHAIN_COMPANY'), v_topco_sid)
			)
	   );
END;

PROCEDURE FilterUsersInRole(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_role_name					IN	role.name%TYPE,
	in_region_sid					IN	region.region_sid%TYPE	DEFAULT NULL,  -- If NULL get all.
	in_filter						IN	VARCHAR2,
	out_users						OUT	SYS_REFCURSOR,
	out_total_num_users				OUT SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_max_size						NUMBER := csr_user_pkg.MAX_USERS;
	v_role_sid						role.role_sid%TYPE;
	v_filtered_users				T_USER_FILTER_TABLE;
	v_region_sids					security.T_SID_TABLE := security.T_SID_TABLE();
	v_show_email					NUMBER;
	v_show_user_name				NUMBER;
	v_show_user_ref					NUMBER;	
BEGIN
	-- Filter users first.
	FilterUsersToTable(in_filter, 0, v_filtered_users);
	
	-- There should only be one role with this name
	-- although there isn't a DB constraint to enforce that...
	BEGIN
		SELECT role_sid
		  INTO v_role_sid
		  FROM role
		 WHERE name = in_role_name;
		-- Make a fuss with a nicer error message if the role wasn't found.
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Role: "'||in_role_name||'" not found -- '||SQLERRM);
	END;
	
	-- Check for permissions on role sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_role_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading role sid '||v_role_sid);
	END IF;
		
	IF in_region_sid IS NULL THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM region_start_point
		 WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
		   AND app_sid = v_app_sid;
	ELSE
		v_region_sids.extend;
		v_region_sids(v_region_sids.count) := in_region_sid;
	END IF;

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;

	OPEN out_total_num_users FOR
		SELECT COUNT(DISTINCT rrm.user_sid) total_num_users, v_max_size max_size
		  FROM region_role_member rrm, TABLE(v_region_sids) rt, TABLE(v_filtered_users) u 
		 WHERE rt.column_value = rrm.region_sid
		   AND u.csr_user_sid = rrm.user_sid
		   AND rrm.role_sid = v_role_sid;
		   
	-- DISTINCT on user_sid so we don't get multiple results for the same user
	-- (could be multiple regions).
	OPEN out_users FOR
		SELECT csr_user_sid, full_name, email, user_name, user_ref, account_enabled, user_sid, sid,
			   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
		  FROM (
			SELECT x.csr_user_sid, x.full_name, x.email, x.user_name, x.user_ref, x.account_enabled, x.user_sid, x.sid
			  FROM (
				SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, r.account_enabled,
					   r.user_sid, r.user_sid sid
				  FROM (SELECT DISTINCT(rrm.user_sid) user_sid, rrm.role_sid, u.account_enabled
						  FROM region_role_member rrm, TABLE(v_region_sids) rt, TABLE(v_filtered_users) u 
						 WHERE rt.column_value = rrm.region_sid
						   AND u.csr_user_sid = rrm.user_sid) r, 
						csr_user cu
				 WHERE cu.app_sid = v_app_sid
				   AND r.user_sid = cu.csr_user_sid
				   AND r.role_sid = v_role_sid
			) x
			 ORDER BY account_enabled DESC,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.email)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_ref)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   LOWER(TRIM(full_name))
		)
		 WHERE ROWNUM <= v_max_size
		 ORDER BY ROWNUM;
END;

PROCEDURE GetDACL(
	in_act_id			IN security_pkg.T_ACT_ID,
    in_sid_id			IN security_pkg.T_SID_ID,
	out_cursor			OUT SYS_REFCURSOR 
)
AS 
	v_dacl_id security_pkg.T_ACL_ID;
BEGIN 
	-- Check read permissions permission first
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_READ_PERMISSIONS) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
    v_dacl_id := security.acl_pkg.GetDACLIdForSID(in_sid_id);
	
	OPEN out_cursor FOR	
	    SELECT acl_id, acl_index, ace_type, ace_flags, a.sid_id, permission_set,
				NVL(u.full_name, so.name) name
	      FROM security.acl a, csr_user u, security.securable_object so
	     WHERE acl_id = v_dacl_id
		   AND u.csr_user_sid(+) = a.sid_id
		   AND so.sid_id = a.sid_id
	  ORDER BY acl_index;
END;


-- TODO: change to do this based on groups
PROCEDURE IsLogonAsUserAllowed(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid 		IN 	security_pkg.T_SID_ID,
	out_result			OUT	BINARY_INTEGER
)
IS														   
	v_result		NUMBER(10);
	v_sid_id		security_pkg.T_SID_ID;
	v_parent_sid_id	security_pkg.T_SID_ID;
	v_dacl_id		security_pkg.T_ACL_ID;
	v_class_id		security_pkg.T_CLASS_ID;
	v_name			security_pkg.T_SO_NAME;
	v_flags			security_pkg.T_SO_FLAGS;
	v_owner			security_pkg.T_SID_ID;
	v_cur			SYS_REFCURSOR;
	v_cug_class_id	security_pkg.T_CLASS_ID;
	v_cr_class_id	security_pkg.T_CLASS_ID;
	v_cu_class_id	security_pkg.T_CLASS_ID;
BEGIN	
	v_cug_class_id := class_pkg.GetClassID('CSRUserGroup');	
	v_cr_class_id := class_pkg.GetClassID('CSRRole');	
	out_result := 0;
	
	-- which groups is this user in? Check each one...(also check the group object is of the right type)
	security.Group_Pkg.GetGroupsOfWhichSOIsMember(in_act_id, in_user_sid, v_cur);
	WHILE TRUE LOOP
		FETCH v_cur INTO v_sid_id, v_parent_sid_id, v_dacl_id, v_class_id, v_name, v_flags, v_owner;
		EXIT WHEN v_cur%NOTFOUND;
		IF v_class_id IN (v_cug_class_id, v_cr_class_id) AND Security_pkg.IsAccessAllowedSID(in_act_id, v_sid_id, Csr_Data_Pkg.PERMISSION_LOGON_AS_USER) THEN
			out_result := 1;
			RETURN;
		END IF;
	END LOOP;
	
	-- try the user directly
	v_cu_class_id := class_pkg.GetClassID('CSRUser');	
	securableobject_pkg.GetSO(in_act_id, in_user_sid, v_cur);
	FETCH v_cur INTO v_sid_id, v_parent_sid_id, v_dacl_id, v_class_id, v_name, v_flags, v_owner;
	IF v_class_id = v_cu_class_id AND Security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, Csr_Data_Pkg.PERMISSION_LOGON_AS_USER) THEN
		out_result := 1;
		RETURN;
	END IF;
END;

FUNCTION IsLogonAsUserAllowedSQL(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid 		IN 	security_pkg.T_SID_ID
)
RETURN BINARY_INTEGER
AS
	v_result		BINARY_INTEGER;
BEGIN
	IsLogonAsUserAllowed(
		in_act_id => in_act_id,
		in_user_sid => in_user_sid,
		out_result => v_result
	);

	return v_result;
END;

PROCEDURE LogonAsUser(					
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	out_act_id			OUT Security_Pkg.T_ACT_ID
)
AS	
	v_app_sid				security_pkg.T_SID_ID;
	v_user_name				varchar2(255);
	v_timeout				NUMBER(10);
	v_superadmin			NUMBER;
	v_pre_logon_as_user_sid	NUMBER;
	v_context_original_sid	NUMBER;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	
	-- Make sure the user didn't login to their current session via logon as; We don't
	-- allow "chained" logins.
	SELECT SYS_CONTEXT('SECURITY', 'ORIGINAL_LOGIN_SID')
	  INTO v_context_original_sid
	  FROM DUAL;
	
	IF v_context_original_sid IS NOT NULL THEN
	    RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHAINED_LOGIN, 'Chained login disallowed.');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_superadmin
	  FROM superadmin
	 WHERE csr_user_sid = in_sid_id;
	 
	IF v_superadmin = 1 THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT act_timeout
	  INTO v_timeout
	  FROM security.website w, customer c
	 WHERE LOWER(website_name)= LOWER(c.host)
	   AND c.app_sid = v_app_sid;

	SELECT full_name||' ('||user_name||')', SYS_CONTEXT('SECURITY', 'SID')
	  INTO v_user_name, v_pre_logon_as_user_sid
	  FROM csr_user
	 WHERE csr_user_sid = in_sid_id
	   AND app_sid = v_app_sid;
	
	security.user_pkg.LogonAuthenticated(in_sid_id, v_timeout, v_app_sid, csr_data_pkg.LOGON_TYPE_SU, out_act_id);
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_LOGON_SU, v_app_sid, in_sid_id, 'Logged on as {0}', v_user_name, security_pkg.GetSID());

	--clear chain company set in session
	security.security_pkg.SetContext('CHAIN_COMPANY', null);
	-- Set original sid to the context so that we can, eg, blocked chained logins
	security.security_pkg.SetContext('ORIGINAL_LOGIN_SID', v_pre_logon_as_user_sid);
END;

PROCEDURE IssueTemporarySSOACT(
	in_sid_id						IN	security_pkg.T_SID_ID,
	out_act_id						OUT	security_pkg.T_ACT_ID
)
AS
BEGIN
	-- suppress auditing on the temporary ACT as it creates too much noise
	INSERT INTO transaction_context (key, val)
	VALUES ('suppress_audit', 1);

	user_pkg.LogonAuthenticated(in_sid_id, 180, out_act_id);
END;

PROCEDURE DestroyTemporarySSOACT(
	in_act_id						IN security_pkg.T_ACT_ID
)
AS
BEGIN
	-- suppress auditing on the temporary ACT as it creates too much noise
	INSERT INTO transaction_context (key, val)
	VALUES ('suppress_audit', 1);

	user_pkg.LogOff(in_act_id);
END;

PROCEDURE LogonSSOUser(
	in_sid_id						IN	security_pkg.T_SID_ID,
	out_act_id						OUT	security_pkg.T_ACT_ID
)
AS
	v_timeout						security.website.act_timeout%TYPE;
BEGIN
	 SELECT act_timeout
	   INTO v_timeout
	   FROM security.website w, customer c
	  WHERE LOWER(website_name) = c.host
	    AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	LogonSSOUser(in_sid_id, SYS_CONTEXT('SECURITY', 'APP'), v_timeout, out_act_id);
END;

PROCEDURE LogonSSOUser(
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_timeout						IN	security.website.act_timeout%TYPE,
	out_act_id						OUT	security_pkg.T_ACT_ID
)
AS
	v_act_id						security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(in_sid_id, in_timeout, in_app_sid, security.security_pkg.LOGON_TYPE_SSO, v_act_id);
	out_act_id := v_act_id;
END;

-- use with appropriate care!! Doesn't write back to Oracle session
FUNCTION LogonUserCreatorDaemon
RETURN security_pkg.T_ACT_ID
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_act		security_pkg.T_ACT_ID;
BEGIN
	v_user_sid := SecurableObject_Pkg.GetSIDFromPath(Security_Pkg.ACT_GUEST, SYS_CONTEXT('SECURITY','APP'), 'users/UserCreatorDaemon');
			 
	-- we don't want to set the security context
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(v_user_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	RETURN v_act;
END;


PROCEDURE GetUsersForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_list	IN	VARCHAR2,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active, cu.user_name,
			   cu.friendly_name, cu.email, cu.enable_aria, cu.line_manager_sid, cu.primary_region_sid,
			   cu.user_ref, cu.anonymised
		  FROM TABLE(Utils_Pkg.SplitString(in_user_list,','))l, csr_user cu, security.user_table ut
		 WHERE l.item = cu.csr_user_sid
		   AND l.item = ut.sid_id
		   AND ut.sid_id = cu.csr_user_sid
		   AND ut.account_enabled = 1
		   --AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ) = 1
	  ORDER BY l.pos;
END;


PROCEDURE CreateGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid	IN	security_pkg.T_ACT_ID,
	in_group_name	IN	security_pkg.T_SO_NAME,
	out_group_sid	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	GROUP_pkg.CreateGroupWithClass(in_act_id, in_parent_sid, security_pkg.GROUP_TYPE_SECURITY, in_group_name,
		class_pkg.GetClassId('CSRUserGroup'), out_group_sid);	
		
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_GROUP_CHANGE, security_pkg.GetAPP, security_pkg.GetSID, 'Created group "{0}"', in_group_name);
END;

FUNCTION GetUserNameFromSid(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	v_username				csr_user.user_name%TYPE;
BEGIN
	SELECT user_name INTO v_username 
	  FROM csr.csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	RETURN v_username;
END;

PROCEDURE GetUserApprovalList(
	in_start_row			IN	NUMBER,
	in_end_row				IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	 OPEN out_cur FOR
		SELECT total_rows, rn, guid, requested_dtm, activated_dtm, approved_dtm,
			   req_user_sid, req_user_name, req_full_name, email req_email,
			   app_user_sid, app_user_name, app_full_name
		  FROM (
	        SELECT COUNT(*) OVER () AS total_rows, rownum rn, x.*
	          FROM (
	            SELECT au.guid, au.requested_dtm, au.activated_dtm, au.approved_dtm,
	                 requ.csr_user_sid req_user_sid, requ.user_name req_user_name, requ.full_name req_full_name, requ.email,
	                 appu.csr_user_sid app_user_sid, appu.user_name app_user_name, appu.full_name app_full_name
	            FROM v$autocreate_user au, csr_user requ, csr_user appu
	           WHERE au.app_sid = security_pkg.GetApp
	             AND requ.csr_user_sid = au.created_user_sid
	             AND appu.csr_user_sid(+) = au.approved_by_user_sid
	           ORDER BY requested_dtm DESC
	        ) x
		 )
		 WHERE rn > in_start_row 
		   AND rn <= in_end_row
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, req_user_sid, security_pkg.PERMISSION_READ)=1
		;
END;

PROCEDURE AddAutoAccount(
	in_user_name			IN	autocreate_user.user_name%TYPE,
	in_guid					IN	autocreate_user.guid%TYPE,	
	in_created_user_sid		IN  security_pkg.T_SID_ID,
	in_require_new_password	IN	autocreate_user.require_new_password%TYPE,
	in_redirect_to_url		IN	autocreate_user.redirect_to_url%TYPE
)
AS
BEGIN
	INSERT INTO autocreate_user (
		user_name, app_sid, guid, created_user_sid, require_new_password, redirect_to_url
	) VALUES(
		in_user_name, SYS_CONTEXT('SECURITY','APP'), in_guid, in_created_user_sid, in_require_new_password, in_redirect_to_url
	);
END;	

PROCEDURE ApproveAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_activated_dtm			autocreate_user.activated_dtm%TYPE;
	v_rejected_dtm			autocreate_user.rejected_dtm%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Check the request has not been rejected and that the 
	-- request has been 'activated' via the e-mail link
	SELECT activated_dtm, rejected_dtm
	  INTO v_activated_dtm, v_rejected_dtm
	  FROM autocreate_user
	 WHERE created_user_sid = in_user_sid;
	
	IF v_activated_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_ACTIVATED, 'The auto create user request for user with sid '||in_user_sid||' has not been activated by the user');
	END IF;
	
	IF v_rejected_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_ALREADY_REJECTED, 'The auto create user request for user with sid '||in_user_sid||' has already been rejected');
	END IF;
	
	UPDATE autocreate_user
	   SET approved_dtm = SYSDATE,
	   	   approved_by_user_sid = security_pkg.GetSid
	 WHERE app_sid = security_pkg.GetApp
	   AND created_user_sid = in_user_sid;
	   	   
	-- Activate the account
	ActivateAutoAccount(in_user_sid);
END;

PROCEDURE ActivateAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Activate the account
	ActivateUser(security_pkg.GetAct, in_user_sid);
	
	-- Add the user to the default group
	SELECT self_reg_group_sid
	  INTO v_group_sid
	  FROM customer
	 WHERE app_Sid = security_pkg.GetApp;
	 
	group_pkg.AddMember(security_pkg.GetAct, in_user_sid, v_group_sid);	
END;

PROCEDURE RejectAutoAccount(
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_approved_dtm			autocreate_user.approved_dtm%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- Check the request has not already been approved
	SELECT approved_dtm
	  INTO v_approved_dtm
	  FROM autocreate_user
	 WHERE created_user_sid = in_user_sid;
	
	IF v_approved_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_ACTIVATED, 'The auto create user request for user with sid '||in_user_sid||' has already been approved');
	END IF;
	
	-- Ensure the account is deactivated
	deactivateUser(
		in_act							=> security_pkg.GetAct, 
		in_user_sid						=> in_user_sid,
		in_raise_user_inactive_alert	=> 0
	);
	
	-- Reject the request
	UPDATE autocreate_user
	   SET rejected_dtm = SYSDATE
	 WHERE created_user_sid = in_user_sid;
END;

PROCEDURE GetAutoAccountDetails(
	in_guid					IN	autocreate_user.guid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT au.created_user_sid, cu.user_name, cu.full_name, cu.email, au.require_new_password, au.redirect_to_url
		  FROM autocreate_user au, csr_user cu
		 WHERE cu.csr_user_sid = au.created_user_sid AND cu.app_sid = au.app_sid AND
		 	   au.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND cu.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
		   	   au.guid = in_guid;
END;

PROCEDURE GetSelfRegDetails(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	OPEN out_cur FOR
		SELECT self_reg_group_sid, self_reg_needs_approval, self_reg_approver_sid
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE MarkAutoAccountActivated(
	in_guid					IN	autocreate_user.guid%TYPE
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	UPDATE autocreate_user
	   SET activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND guid = in_guid;
END;

PROCEDURE SetAutoAccountUser(
	in_guid					IN	autocreate_user.guid%TYPE,
	in_user_sid				IN	autocreate_user.created_user_sid%TYPE
)
AS
BEGIN
	-- TODO: there is no security here, moved from the web page
	UPDATE autocreate_user
	   SET created_user_sid = in_user_sid
	 WHERE guid = in_guid AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetDonationsReportsFilterId(
	out_filter_id			OUT	csr_user.donations_reports_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT NVL(donations_reports_filter_id, -1)
	  INTO out_filter_id
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetShowSaveChartWarning(
	out_show_warning			OUT	csr_user.show_save_chart_warning%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT show_save_chart_warning
	  INTO out_show_warning
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetShowSaveChartWarning(
	in_show_save_chart_warning 		IN csr_user.show_save_chart_warning%TYPE
)
AS
BEGIN
	UPDATE csr_user
	   SET show_save_chart_warning = in_show_save_chart_warning,
		   last_modified_dtm = SYSDATE
	 WHERE csr_user.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetDonationsBrowseFilterId(
	out_filter_id			OUT	csr_user.donations_browse_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	SELECT NVL(donations_browse_filter_id, -1)
	  INTO out_filter_id
	  FROM csr_user
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetDonationsBrowseFilterId(
	in_filter_id			IN	csr_user.donations_browse_filter_id%TYPE
)
AS
BEGIN
	-- Data for current user only, so no security check required
	UPDATE csr_user
	   SET donations_browse_filter_id = null,
		   last_modified_dtm = SYSDATE
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE SetLocalisationSettings(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE
)
AS
BEGIN
	-- this checks security for us
	security.user_pkg.SetLocalisationSettings(in_act_id, in_user_sid, in_language, in_culture, in_timezone);
	
	-- now update the user's batch run times in case we changed timezone
	UPDATE alert_batch_run
	   SET next_fire_time = (SELECT next_fire_time_gmt
	   						   FROM v$alert_batch_run_time abrt
	   						  WHERE abrt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   						    AND abrt.csr_user_sid = in_user_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
END;

PROCEDURE RaiseUserMessageAlert(
	in_notify_user_sid				IN	user_message_alert.notify_user_sid%TYPE,
	in_message						IN	user_message_alert.message%TYPE
)
AS
BEGIN
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_USER) THEN
		INSERT INTO user_message_alert (user_message_alert_id, raised_by_user_sid, notify_user_sid, message)
		VALUES (user_message_alert_id_seq.nextval, SYS_CONTEXT('SECURITY', 'SID'), in_notify_user_sid, in_message);
	ELSE
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ALERT_TEMPLATE_NOT_FOUND, 'Alert template not found or alert is inactive');
	END IF;
END;

PROCEDURE GetUserMessageAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ uma.user_message_alert_id, uma.notify_user_sid, cu.full_name, cu.friendly_name, cu.email, 
			   cu.user_name, uma.message, cu.csr_user_sid, uma.app_sid, uma.raised_by_user_sid
		  FROM user_message_alert uma
		  JOIN csr_user cu ON uma.notify_user_sid = cu.csr_user_sid AND uma.app_sid = cu.app_sid
		  JOIN customer c ON uma.app_sid = c.app_sid
		 WHERE c.scheduled_tasks_disabled = 0
		 ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE RecordUserMessageAlertSent(
	in_user_message_alert_id		IN	user_message_alert.user_message_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM user_message_alert
	 WHERE user_message_alert_id = in_user_message_alert_id;
END;

PROCEDURE GetUserNames(
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_full_name			OUT	VARCHAR2,
	out_friendly_name		OUT	VARCHAR2
)
AS
BEGIN
	SELECT full_name, friendly_name
	  INTO out_full_name, out_friendly_name
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetUserDirectoryType(
	in_user_directory_type_id		IN  user_directory_type.user_directory_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT user_directory_type_id, user_directory_class
		  FROM user_directory_type
		 WHERE user_directory_type_id = in_user_directory_type_id;
END;


FUNCTION GetFriendlyNameFromEmail(
	in_email_address			IN	csr.csr_user.email%TYPE
) RETURN VARCHAR2
IS
	v_friendly_name			csr.csr_user.email%TYPE;
BEGIN
  SELECT friendly_name INTO v_friendly_name FROM
    (
      SELECT COUNT(friendly_name), friendly_name
        FROM csr.csr_user WHERE UPPER(email) = UPPER(in_email_address)
        GROUP BY friendly_name
        ORDER BY COUNT(friendly_name) DESC
    )
  WHERE
    rownum = 1;
    return v_friendly_name;
	
END;

FUNCTION GetUserSidFromEmail(
	in_email_address			IN	csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
IS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(cu.csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user cu
	  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	 WHERE UPPER(cu.email) = UPPER(TRIM(in_email_address))
	   AND ut.account_enabled = 1
	   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP');
	
	RETURN v_user_sid;
END;

FUNCTION IsLastLoginSso (
  in_user_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
  v_last_login_type_id    csr_user.last_logon_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_READ) THEN
	    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT last_logon_type_id
	  INTO v_last_login_type_id
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid	
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	RETURN CASE WHEN v_last_login_type_id = security.security_pkg.LOGON_TYPE_SSO THEN 1 ELSE 0 END;
END;

PROCEDURE EnsureUserLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	v_count						NUMBER;
	v_language					security.user_table.language%TYPE;
	v_culture					security.user_table.culture%TYPE;
	v_timezone					security.user_table.timezone%TYPE;
	v_app_language				security.user_table.language%TYPE;
BEGIN
	v_app_sid := security.security_pkg.getApp;
	security.web_pkg.GetLocalisationSettings(in_act_id, v_app_sid, v_app_language, v_culture, v_timezone);
	FOR r IN (
		SELECT usr.sid_id
		  FROM security.user_table usr
		  JOIN csr.csr_user site_usr ON usr.sid_id = site_usr.csr_user_sid
		 WHERE site_usr.app_sid = v_app_sid 
		   AND IsSuperAdmin(usr.sid_id) = 0
		   AND site_usr.HIDDEN = 0)
	LOOP
		security.user_pkg.GetLocalisationSettings(in_act_id, r.sid_id, v_language, v_culture, v_timezone);
		SELECT COUNT(*)
		  INTO v_count
		  FROM aspen2.translation_set
		 WHERE application_sid = v_app_sid
		   AND hidden = 0
		   AND lang = v_language;

		IF v_count = 0 THEN
			IF v_app_language IS NOT NULL THEN
				security.user_pkg.SetLocalisationSettings(in_act_id, r.sid_id, v_app_language, v_culture, v_timezone);
			ELSE
				security.user_pkg.SetLocalisationSettings(in_act_id, r.sid_id, 'en', v_culture, v_timezone);
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE GetUserRelationshipTypes(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
				user_relationship_type_id,
				label
			FROM user_relationship_type
			WHERE app_sid = security_pkg.GETAPP;
END;

PROCEDURE SaveUserRelationshipType(
	in_user_relationship_type_id	IN csr.user_relationship_type.user_relationship_type_id%TYPE,
	in_label						IN csr.user_relationship_type.label%TYPE,
	out_user_relationship_type_id	OUT csr.user_relationship_type.user_relationship_type_id%TYPE
)
AS
BEGIN
	IF in_user_relationship_type_id > 0 THEN
		BEGIN
			UPDATE user_relationship_type SET label = in_label 
				WHERE user_relationship_type_id = in_user_relationship_type_id AND app_sid = security_pkg.GETAPP;
				
			out_user_relationship_type_id := in_user_relationship_type_id;
		END;
	ELSE
		BEGIN
			INSERT INTO user_relationship_type (app_sid, user_relationship_type_id, label) VALUES (security_pkg.GETAPP, USER_RELATIONSHIP_TYPE_ID_SEQ.NEXTVAL, in_label)
			RETURNING user_relationship_type_id INTO out_user_relationship_type_id;
		END;
	END IF;
END;

PROCEDURE DeleteUserRelationshipType(
	in_user_relationship_type_id	IN csr.user_relationship_type.user_relationship_type_id%TYPE
)
AS
BEGIN
	DELETE FROM user_relationship
		WHERE app_sid = security_pkg.GETAPP
		  AND user_relationship_type_id = in_user_relationship_type_id;
		  
	DELETE FROM user_relationship_type
		WHERE app_sid = security_pkg.GETAPP
		  AND user_relationship_type_id = in_user_relationship_type_id;
END;

PROCEDURE GetUserRelationshipsForUser(
	in_child_user_sid	IN csr.user_relationship.child_user_sid%TYPE,
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
				ur.parent_user_sid as user_sid,
				u.full_name,
				ur.user_relationship_type_id,
				urt.label
			FROM user_relationship ur
			JOIN csr_user u ON ur.parent_user_sid = u.csr_user_sid AND u.app_sid = security_pkg.GETAPP
			JOIN user_relationship_type urt ON ur.user_relationship_type_id = urt.user_relationship_type_id AND urt.app_sid = security_pkg.GETAPP
			WHERE ur.child_user_sid = in_child_user_sid
			  AND ur.app_sid = security_pkg.GETAPP;
END;

PROCEDURE ClearUserRelationshipsForUser(
	in_child_user_sid	IN csr.user_relationship.child_user_sid%TYPE
)
AS
BEGIN
	DELETE FROM user_relationship
		WHERE child_user_sid = in_child_user_sid
		  AND app_sid = security_pkg.GETAPP;
END;

PROCEDURE AddUserRelationship(
	in_child_user_sid				IN csr.user_relationship.child_user_sid%TYPE,
	in_parent_user_sid				IN csr.user_relationship.parent_user_sid%TYPE,
	in_user_relationship_type_id	IN csr.user_relationship.user_relationship_type_id%TYPE
)
AS
BEGIN
	INSERT INTO user_relationship (app_sid, child_user_sid, parent_user_sid, user_relationship_type_id) 
		VALUES (security_pkg.GETAPP, in_child_user_sid, in_parent_user_sid, in_user_relationship_type_id);
END;

PROCEDURE DeleteUserRelationship(
	in_child_user_sid				IN csr.user_relationship.child_user_sid%TYPE,
	in_parent_user_sid				IN csr.user_relationship.parent_user_sid%TYPE,
	in_user_relationship_type_id	IN csr.user_relationship.user_relationship_type_id%TYPE
)
AS
BEGIN
	DELETE FROM user_relationship
		WHERE app_sid = security_pkg.GETAPP
		  AND child_user_sid = in_child_user_sid
		  AND parent_user_sid = in_parent_user_sid
		  AND user_relationship_type_id = in_user_relationship_type_id;
END;

PROCEDURE GetJobFunctions(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT
				function_id,
				label
			FROM function
			WHERE app_sid = security_pkg.GETAPP;
END;

PROCEDURE SaveFunction(
	in_function_id	IN csr.function.function_id%TYPE,
	in_label		IN csr.function.label%TYPE,
	out_function_id	OUT csr.function.function_id%TYPE
)
AS
BEGIN
	IF in_function_id > 0 THEN
		BEGIN
			UPDATE FUNCTION SET label = in_label 
				WHERE function_id = in_function_id AND app_sid = security_pkg.GETAPP;
				
			out_function_id := in_function_id;
		END;
	ELSE
		BEGIN
			INSERT INTO FUNCTION (app_sid, function_id, label) VALUES (security_pkg.GETAPP, FUNCTION_ID_SEQ.NEXTVAL, in_label)
			RETURNING function_id INTO out_function_id;
		END;
	END IF;
END;

PROCEDURE DeleteFunction(
	in_function_id	IN csr.function.function_id%TYPE
)
AS
BEGIN
	DELETE FROM USER_FUNCTION
		WHERE app_sid = security_pkg.GETAPP
		  AND function_id = in_function_id;
		  
	DELETE FROM FUNCTION
		WHERE app_sid = security_pkg.GETAPP
		  AND function_id = in_function_id;
END;

PROCEDURE GetUserJobFunctions(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE,
	out_cur 		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 
				uf.function_id,
				f.label
			FROM user_function uf
			JOIN function f ON f.function_id = uf.function_id AND f.app_sid = security_pkg.GETAPP
			WHERE uf.csr_user_sid = in_csr_user_sid
			  AND uf.app_sid = security_pkg.GETAPP;
END;

PROCEDURE ClearFunctionsForUser(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE
)
AS
BEGIN
	DELETE FROM user_function
		WHERE csr_user_sid = in_csr_user_sid
		  AND app_sid = security_pkg.GETAPP;
END;

PROCEDURE AddUserFunction(
	in_csr_user_sid	IN csr.user_function.csr_user_sid%TYPE,
	in_function_id	IN csr.user_function.function_id%TYPE
)
AS
BEGIN
	INSERT INTO user_function (app_sid, csr_user_sid, function_id)
		VALUES (security_pkg.GETAPP, in_csr_user_sid, in_function_id);
END;

PROCEDURE RaiseUserInactiveReminderAlert(
	in_user_sid				IN	user_inactive_rem_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
	v_exists					NUMBER;
BEGIN
	IF (NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_USER_INACTIVE_REMINDER, in_app_sid)) OR IsSSOUser(in_user_sid) THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM user_inactive_rem_alert
	 WHERE app_sid = in_app_sid
	   AND sent_dtm IS NULL
	   AND notify_user_sid = in_user_sid;
	
	IF v_exists = 0 THEN
		INSERT INTO user_inactive_rem_alert (
			app_sid, user_inactive_rem_alert_id, notify_user_sid
		) VALUES (
			in_app_sid, user_inactive_rem_alert_id_seq.NEXTVAL, in_user_sid
		);
	END IF;
END;

PROCEDURE RecordUserInactiveReminderSent(
	in_alert_id				IN	user_inactive_rem_alert.user_inactive_rem_alert_id%TYPE,
	in_user_sid				IN	user_inactive_rem_alert.notify_user_sid%TYPE
)
AS
BEGIN
	UPDATE user_inactive_rem_alert
	   SET sent_dtm = SYSDATE
	 WHERE user_inactive_rem_alert_id = in_alert_id
	   AND notify_user_sid = in_user_sid;
END;

PROCEDURE RaiseUserInactiveSysAlert(
	in_user_sid				IN	user_inactive_sys_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
	v_exists					NUMBER;
BEGIN
	-- Account disabled, delete user inactive reminder alerts which have not been sent
	DELETE FROM user_inactive_rem_alert
	 WHERE app_sid = in_app_sid
	   AND sent_dtm IS NULL
	   AND notify_user_sid = in_user_sid;

	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM, in_app_sid) THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM user_inactive_sys_alert
	 WHERE app_sid = in_app_sid
	   AND sent_dtm IS NULL
	   AND notify_user_sid = in_user_sid;
	
	IF v_exists = 0 THEN
		INSERT INTO user_inactive_sys_alert (
			app_sid, user_inactive_sys_alert_id, notify_user_sid
		) VALUES (
			in_app_sid, user_inactive_sys_alert_id_seq.NEXTVAL, in_user_sid
		);
	END IF;
END;

PROCEDURE RecordUserInactiveSysAlertSent(
	in_alert_id				IN	user_inactive_sys_alert.user_inactive_sys_alert_id%TYPE,
	in_user_sid				IN	user_inactive_sys_alert.notify_user_sid%TYPE
)
AS
BEGIN
	UPDATE user_inactive_sys_alert
	   SET sent_dtm = SYSDATE
	 WHERE user_inactive_sys_alert_id = in_alert_id
	   AND notify_user_sid = in_user_sid;
END;

PROCEDURE RaiseUserInactiveManAlert(
	in_user_sid				IN	user_inactive_man_alert.notify_user_sid%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
)
AS
	v_exists					NUMBER;
BEGIN
	-- Account disabled, delete user inactive reminder alerts which have not been sent
	DELETE FROM user_inactive_rem_alert
	 WHERE app_sid = in_app_sid
	   AND sent_dtm IS NULL
	   AND notify_user_sid = in_user_sid;

   IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_USER_INACTIVE_MANUAL, in_app_sid) THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM user_inactive_man_alert
	 WHERE sent_dtm IS NULL
	   AND notify_user_sid = in_user_sid;
	
	IF v_exists = 0 THEN
		INSERT INTO user_inactive_man_alert (
			app_sid, user_inactive_man_alert_id, notify_user_sid
		) VALUES (
			in_app_sid, user_inactive_man_alert_id_seq.NEXTVAL, in_user_sid
		);
	END IF;
END;

PROCEDURE RecordUserInactiveManAlertSent(
	in_alert_id				IN	user_inactive_man_alert.user_inactive_man_alert_id%TYPE,
	in_user_sid				IN	user_inactive_man_alert.notify_user_sid%TYPE
)
AS
BEGIN
	UPDATE user_inactive_man_alert
	   SET sent_dtm = SYSDATE
	 WHERE user_inactive_man_alert_id = in_alert_id
	   AND notify_user_sid = in_user_sid;
END;

PROCEDURE GetUserInactiveReminderAlerts(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_USER_INACTIVE_REMINDER);

	-- Mark uninteresting ones as already sent
	UPDATE user_inactive_rem_alert uira
	   SET uira.sent_dtm = SYSDATE
	WHERE uira.notify_user_sid IN (
		SELECT cu.csr_user_sid
		  FROM csr_user cu
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE ut.account_enabled = 0 OR cu.send_alerts = 0
	);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/uira.user_inactive_rem_alert_id alert_id,
			   cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email, cu.user_name
		  FROM user_inactive_rem_alert uira
		  JOIN csr_user cu ON uira.app_sid = cu.app_sid AND uira.notify_user_sid = cu.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_USER_INACTIVE_REMINDER
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
		  JOIN csr.customer c on c.app_sid = uira.app_sid
		 WHERE uira.sent_dtm IS NULL
		   AND ut.account_enabled = 1
		   AND t.trash_sid IS NULL
		   AND c.scheduled_tasks_disabled = 0
		 ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE GetUserInactiveSysAlerts(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM);

	-- Mark uninteresting ones as already sent
	UPDATE user_inactive_sys_alert uisa
	   SET uisa.sent_dtm = SYSDATE
	WHERE uisa.notify_user_sid IN (
		SELECT cu.csr_user_sid
		  FROM csr_user cu
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE ut.account_enabled = 1 OR cu.send_alerts = 0
	);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/uisa.user_inactive_sys_alert_id alert_id,
			   cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email, cu.user_name
		  FROM user_inactive_sys_alert uisa
		  JOIN csr_user cu ON uisa.app_sid = cu.app_sid AND uisa.notify_user_sid = cu.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
		  JOIN customer c on c.app_sid = uisa.app_sid
		 WHERE uisa.sent_dtm IS NULL
		   AND ut.account_enabled = 0
		   AND t.trash_sid IS NULL
		   and c.scheduled_tasks_disabled = 0
		 ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE GetUserInactiveManAlerts(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/uima.user_inactive_man_alert_id alert_id,
			   cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email, cu.user_name
		  FROM user_inactive_man_alert uima
		  JOIN csr_user cu ON uima.app_sid = cu.app_sid AND uima.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
		  JOIN customer c on uima.app_sid = c.app_sid
		 WHERE uima.sent_dtm IS NULL
		   AND ut.account_enabled = 0
		   AND t.trash_sid IS NULL
		   AND c.scheduled_tasks_disabled = 0
		 ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE RaiseUserInactiveRemAlerts
AS
	v_policy_sid					security.security_pkg.T_SID_ID;
	v_expire_inactive				security.account_policy.expire_inactive%TYPE;
	v_ntfy_days_before_inactive		customer.ntfy_days_before_user_inactive%TYPE;
BEGIN
	FOR r IN (
		SELECT so.application_sid_id app_sid, ut.sid_id, ut.last_logon, soc.helper_pkg
		  FROM security.securable_object so
		  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
		  JOIN security.user_table ut ON so.sid_id = ut.sid_id
		 WHERE account_enabled = 1 
		   AND helper_pkg IS NOT NULL
		   AND ((SELECT alert_pkg.SQL_IsAlertEnabled(csr_data_pkg.ALERT_USER_INACTIVE_REMINDER, so.APPLICATION_SID_ID) FROM dual) = 1)
	)
	LOOP
		-- Get account policy from the helper object
		EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.GetAccountPolicy(:1,:2);end;'
		USING r.sid_id, OUT v_policy_sid;
		
		IF v_policy_sid IS NOT NULL THEN
			-- Get config
			SELECT expire_inactive
			  INTO v_expire_inactive
			  FROM security.account_policy
			 WHERE sid_id = v_policy_sid;
			
			SELECT ntfy_days_before_user_inactive
			  INTO v_ntfy_days_before_inactive
			  FROM customer
			 WHERE app_sid = r.app_sid;
		
			-- Check for account expiry	 	
			IF v_expire_inactive IS NOT NULL AND v_ntfy_days_before_inactive IS NOT NULL
				AND r.last_logon < SYSDATE - (v_expire_inactive - v_ntfy_days_before_inactive) THEN
				RaiseUserInactiveReminderAlert(r.sid_id, r.app_sid);
			END IF;
		END IF;
	END LOOP;
END;

FUNCTION GetUserAdminHelperPkg 
RETURN customer.user_admin_helper_pkg%TYPE
AS
	v_helper_pkg	customer.user_admin_helper_pkg%TYPE;
BEGIN
	SELECT user_admin_helper_pkg
	  INTO v_helper_pkg
	  FROM csr.customer;
	  
	RETURN v_helper_pkg;
END;

FUNCTION UNSEC_GetIndStartPointsAsTable(
	in_user_sid						IN	security.security_pkg.T_SID_ID
)
RETURN security.T_SID_TABLE
AS
	v_result							security.T_SID_TABLE;
BEGIN
	SELECT ind_sid
	  BULK COLLECT INTO v_result
	  FROM ind_start_point
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND user_sid = in_user_sid;

	RETURN v_result;
END;

FUNCTION GetIndStartPointsAsTable(
	in_user_sid						IN	security.security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
RETURN security.T_SID_TABLE
AS
BEGIN
	-- check permission....
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading information for the user with sid '||in_user_sid);
	END IF;
	RETURN UNSEC_GetIndStartPointsAsTable(in_user_sid);
END;

PROCEDURE AddUserToGroupLogged(
	in_user_sid						IN	security.security_pkg.T_SID_ID,
	in_group_sid					IN	security.security_pkg.T_SID_ID,
	in_group_name					IN	VARCHAR2
)
AS
BEGIN
	
	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'),
		csr_data_pkg.AUDIT_TYPE_USER_ACCOUNT, SYS_CONTEXT('SECURITY', 'APP'),
		in_user_sid, 'Added to group "{0}"',
		in_group_name);
	
	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, in_group_sid);
END;

PROCEDURE GetLogonTypes(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT logon_type_id, label
		  FROM logon_type;
END;

PROCEDURE GetGroupMemberGroupsForExport(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run csr_user_pkg.GetGroupMemberGroupsForExport');
	END IF;
	OPEN out_cur FOR
		SELECT gmo.sid_id member_sid, g.name group_name, gmo.name member_name
		  FROM security.securable_object g
		  JOIN security.group_members gm ON g.sid_id = gm.group_sid_id
		  JOIN security.securable_object gmo ON gm.member_sid_id = gmo.sid_id AND gmo.parent_sid_id = in_parent_sid
		 WHERE g.parent_sid_id = in_parent_sid;
END;

FUNCTION UsersWithReferenceCount
RETURN NUMBER
AS
	v_result						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_result
	  FROM csr_user u
	 WHERE u.csr_user_sid NOT IN 
		(SELECT csr_user_sid
		   FROM superadmin)
	   AND u.user_ref IS NOT NULL;

	  RETURN v_result;
END;

PROCEDURE GetGroups(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_groups_sid					security_pkg.T_SID_ID;
BEGIN
	v_groups_sid := securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'),
		SYS_CONTEXT('SECURITY', 'APP'), 'Groups');
	OPEN out_cur FOR
		SELECT sid_id, name
		  FROM TABLE(securableobject_pkg.GetDescendantsAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
				v_groups_sid))
		 WHERE class_id != security_pkg.SO_CONTAINER
		 ORDER BY LOWER(name);
END;

PROCEDURE SetCookieConsent(
	in_accept		NUMBER
)
AS
BEGIN
	INSERT INTO csr.cookie_policy_consent(cookie_policy_consent_id, csr_user_sid, accepted)
	VALUES(csr.cookie_policy_consent_id_seq.NEXTVAL, SYS_CONTEXT('SECURITY', 'SID'), in_accept);
END;

PROCEDURE GetUserBasicInfo(
	in_user_sids	IN security.security_pkg.T_SID_IDS,
	out_cur			OUT SYS_REFCURSOR
)
AS
	v_user_sids_t	security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_user_sids);
BEGIN
	CheckRegisteredUser();

	OPEN out_cur FOR
		SELECT csr_user_sid user_sid, full_name, active, cu.guid user_uuid
		  FROM v$csr_user cu
		  JOIN TABLE(v_user_sids_t) t ON t.column_value = cu.csr_user_sid;
END;

PROCEDURE GetUserBasicInfoByUuids(
	in_guids		IN security.security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT SYS_REFCURSOR
)
AS
	v_guids			security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_guids);
BEGIN
	CheckRegisteredUser();
	
	OPEN out_cur FOR
		SELECT csr_user_sid user_sid, full_name, active, cu.guid user_uuid
		  FROM v$csr_user cu
		  JOIN TABLE(v_guids) g ON cu.guid = g.value;
END;

PROCEDURE GetUserExtendedInfo(
	in_guids		IN security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT SYS_REFCURSOR
)
AS
v_current_user_sid 	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
v_guids				security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_guids);
v_user_sids			security_pkg.T_SID_IDS;
v_allowed_user_sids	security.T_SO_TABLE;
v_table				T_USER_FILTER_TABLE;
v_superadmin		NUMBER;
BEGIN
	CheckRegisteredUser();

	--extra chain security checking as well as other filters
	FilterUsersToTable('', 1, v_table);

	--GUIDS to sids	
	SELECT u.csr_user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM v$csr_user u
	  JOIN TABLE(v_guids) g ON u.guid = g.value
	  JOIN TABLE(v_table) t ON u.csr_user_sid = t.csr_user_sid;
		
	v_allowed_user_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security_pkg.SidArrayToTable(v_user_sids), 
		security_pkg.PERMISSION_READ
	);	
	
	OPEN out_cur FOR
		SELECT csr_user_sid user_sid, user_name, full_name, email, user_ref, active account_enabled, guid
		  FROM v$csr_user u
		  JOIN TABLE(v_allowed_user_sids) a ON u.csr_user_sid = a.sid_id;
END;

PROCEDURE GetIdentityDetails(
	in_user_sid		IN security_pkg.T_SID_ID DEFAULT security.security_pkg.GetSid,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT full_name, email, guid, t.tenant_id
		  FROM csr_user cu
		  JOIN security.tenant t on cu.app_sid = t.application_sid_id
		 WHERE csr_user_sid = in_user_sid;

END;

PROCEDURE GetIdentityDetailsWithGroups(
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetIdentityDetailsWithGroups(
		in_act_id			=>	SYS_CONTEXT('SECURITY','ACT'),
		out_user_cur		=>	out_user_cur,
		out_groups_cur		=>	out_groups_cur
	);
END;

PROCEDURE GetIdentityGroups(
	in_act_id			IN	security_pkg.T_ACT_ID,
	out_groups_cur		OUT	SYS_REFCURSOR
)
AS
	v_groups_sid						security.security_pkg.T_SID_ID;
	v_superadmins_sid					security.security_pkg.T_SID_ID;
	v_builtinadmins_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_groups_sid := securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), 'Groups');
	v_superadmins_sid := securableobject_pkg.GetSIDFromPath(in_act_id, 0, '//csr/SuperAdmins');
	v_builtinadmins_sid := securableobject_pkg.GetSIDFromPath(in_act_id, 0, '//builtin/Administrators');
	
	OPEN out_groups_cur FOR
		-- Not the nicest in the world, but the builtin administrator group 
		-- is called "Administrators", same as the group within each app. We 
		-- want to be able to differentiate.
		SELECT CASE WHEN so.sid_id = v_builtinadmins_sid then 'Builtin/Administrators' else so.name END name 
		  FROM security.securable_object so
		  JOIN security.act a ON a.sid_id = so.sid_id
		 WHERE (parent_sid_id = v_groups_sid 
				OR so.sid_id = v_superadmins_sid
				OR so.sid_id = v_builtinadmins_sid)
		   AND act_id = in_act_id;
END;

PROCEDURE GetIdentityDetailsWithGroups(
	in_act_id			IN	security_pkg.T_ACT_ID,
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetIdentityDetails(
		out_cur => out_user_cur
	);
	
	GetIdentityGroups(
		in_act_id			=> in_act_id,
		out_groups_cur		=> out_groups_cur
	);
END;

PROCEDURE DoImpersonationForJwt(
	in_jwt_id			IN	security.act_timeout.jwt_id%TYPE,
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	in_tenant_id		IN	security.tenant.tenant_id%TYPE,
	out_user_cur		OUT	SYS_REFCURSOR,
	out_groups_cur		OUT	SYS_REFCURSOR
)
AS
	v_act				Security_Pkg.T_ACT_ID;
	v_app_sid			security.tenant.application_sid_id%TYPE;
	v_host				csr.customer.host%TYPE;
BEGIN

	ExchangeJwtForAct(
		in_jwt_id			=> in_jwt_id,
		in_user_guid		=> in_user_guid,
		in_tenant_id		=> in_tenant_id,
		out_act				=> v_act,
		out_app_sid			=> v_app_sid,
		out_host			=> v_host
	);

	GetIdentityDetailsWithGroups(
		in_act_id			=>	v_act,
		out_user_cur		=>	out_user_cur,
		out_groups_cur		=>	out_groups_cur
	);

END;

PROCEDURE IssueServiceLevelIdentity(
	in_jwt_id					IN	security.act_timeout.jwt_id%TYPE,
	in_service_identifier		IN	service_user_map.service_identifier%TYPE,
	in_tenant_id				IN	security.tenant.tenant_id%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_groups_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.tenant.application_sid_id%TYPE;
	v_user_guid					csr_user.guid%TYPE;
	v_act						Security_Pkg.T_ACT_ID;
	v_host						csr.customer.host%TYPE;
BEGIN

	SELECT cu.guid
	  INTO v_user_guid
	  FROM service_user_map sum
	  JOIN csr_user cu on sum.user_sid = cu.csr_user_sid
	  JOIN security.tenant t on t.application_sid_id = cu.app_sid
	 WHERE LOWER(sum.service_identifier) = LOWER(in_service_identifier)
	 and t.tenant_id = in_tenant_id;

	OPEN out_user_cur FOR
		SELECT sum.full_name, cu.email, cu.guid, t.tenant_id, sum.can_impersonate
		  FROM service_user_map sum
		  JOIN csr_user cu on sum.user_sid = cu.csr_user_sid
		  JOIN security.tenant t on t.application_sid_id = cu.app_sid
		 WHERE LOWER(sum.service_identifier) = LOWER(in_service_identifier)
		   AND t.tenant_id = in_tenant_id;

	ExchangeJwtForAct(
		in_jwt_id			=> in_jwt_id,
		in_user_guid		=> v_user_guid,
		in_tenant_id		=> in_tenant_id,
		out_act				=> v_act,
		out_app_sid			=> v_app_sid,
		out_host			=> v_host
	);

	GetIdentityGroups(
		in_act_id			=> v_act,
		out_groups_cur		=> out_groups_cur
	);

END;

PROCEDURE ExchangeJwtForAct(
	in_jwt_id			IN	security.act_timeout.jwt_id%TYPE,
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	in_tenant_id		IN	security.tenant.tenant_id%TYPE,
	out_act				OUT	Security_Pkg.T_ACT_ID,
	out_app_sid			OUT	security.tenant.application_sid_id%TYPE,
	out_host			OUT	csr.customer.host%TYPE
)
AS
	v_user_sid			csr.csr_user.csr_user_sid%TYPE;
	v_act_id 			Security_Pkg.T_ACT_ID;
BEGIN

	out_app_sid := security.security_pkg.GetAppSidFromTenantId(
		in_tenant_id		=> in_tenant_id
	);

	SELECT c.host
	  INTO out_host
	  FROM customer c
	 WHERE app_sid = out_app_sid;

	v_act_id := security.security_pkg.GetActFromJwt(in_jwt_id	=> in_jwt_id);

	IF v_act_id IS NULL THEN
		-- Means we don't have an ACT registered against the JWT id. This can 
		-- happen... ACT expired, logged out, or perhaps never existed (eg JWT came 
		-- from an external source, etc).
		-- So, we want to log in to the user and issue a new act and store against
		-- the JWT.
		SELECT unique csr_user_sid
		  INTO v_user_sid
		  FROM csr_user
		 WHERE guid = in_user_guid
		   AND app_sid = out_app_sid;
		
		security.user_pkg.LogonAuthenticated(
			in_sid_id			=> v_user_sid,
			in_act_timeout		=> 60 * 60, -- 1 hour
			in_app_sid			=> out_app_sid,
			out_act_id			=> v_act_id
		);
		
		security.security_pkg.SetJwtAgainstAct(
			in_act_id			=> v_act_id,
			in_jwt_id			=> in_jwt_id
		);
	END IF;
	
	out_act := TRIM(v_act_id);
END;

/* Insecure. Only called by APIs where the auth has already been handled*/
PROCEDURE GetUserByGuid(
	in_user_guid		IN	csr.csr_user.guid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT full_name, email
		  FROM csr_user
		 WHERE guid = in_user_guid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION GetUserSidFromGuid(
	in_user_guid		IN	csr.csr_user.guid%TYPE
)
RETURN NUMBER
AS
	v_user_sid			csr.csr_user.csr_user_sid%TYPE;
BEGIN
	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr_user
	 WHERE guid = in_user_guid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	RETURN v_user_sid;
END;

PROCEDURE GetUserSidFromGuidBatch(
	in_user_guids					IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_user_guids					security.T_VARCHAR2_TABLE;
BEGIN
	v_user_guids := security.security_pkg.Varchar2ArrayToTable(in_user_guids);

	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.guid
		  FROM csr_user cu
		  JOIN TABLE(v_user_guids) g ON cu.guid = g.value
		 WHERE cu.app_sid = security.security_pkg.GetApp();
END;

-- Returns a list of users that cannot be structure imported against.
-- Essentially superadmins and special users
PROCEDURE GetBlockedStructureImportUsers(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT csr_user_sid 
		  FROM csr_user cu
		  JOIN security.securable_object so ON so.sid_id = cu.csr_user_sid
		 WHERE so.class_id = security_pkg.SO_USER
			OR so.sid_id IN (
			  SELECT csr_user_sid
				FROM superadmin
			);

END;

PROCEDURE GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_csr_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading information for the user with sid '||in_csr_user_sid);
	END IF;

	UNSEC_GetUserRecordBySid(
		in_csr_user_sid			=> in_csr_user_sid,
		out_user				=> out_user
	);

END;

PROCEDURE GetUserRecordByUserName(
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	out_user				OUT CSR.T_USER
)
AS
	v_csr_user_sid			csr.csr_user.csr_user_sid%TYPE;
BEGIN

	SELECT csr_user_sid
	 INTO v_csr_user_sid
	 FROM csr_user
	WHERE LOWER(user_name) = LOWER(in_user_name)
	  AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetUserRecordBySid(
		in_csr_user_sid => v_csr_user_sid,
		out_user => out_user
	);

END;

PROCEDURE UNSEC_GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
BEGIN

	SELECT T_USER(
		cu.csr_user_sid,
		cu.email,
		cu.full_name,
		cu.user_name,
		cu.friendly_name,
		cu.job_title,
		cu.active,
		cu.user_ref,
		cu.line_manager_sid
	)
	  INTO out_user
	  FROM csr.v$csr_user cu
	 WHERE cu.csr_user_sid = in_csr_user_sid
	   AND cu.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
	v_csr_user_sid			csr.csr_user.csr_user_sid%TYPE;
BEGIN

	SELECT csr_user_sid
	  INTO v_csr_user_sid
	  FROM csr_user 
	 WHERE LOWER(user_ref) = LOWER(in_user_ref)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetUserRecordBySid(
		in_csr_user_sid			=> v_csr_user_sid,
		out_user				=> out_user
	);

END;

PROCEDURE UNSEC_GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
	v_csr_user_sid			csr.csr_user.csr_user_sid%TYPE;
BEGIN

	SELECT csr_user_sid
	  INTO v_csr_user_sid
	  FROM csr_user 
	 WHERE LOWER(user_ref) = LOWER(in_user_ref)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UNSEC_GetUserRecordBySid(
		in_csr_user_sid			=> v_csr_user_sid,
		out_user				=> out_user
	);

END;

PROCEDURE AnonymiseUsersBatchJob(
	in_user_sids					IN	security_pkg.T_SID_IDS,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_job_id						batch_job.batch_job_id%TYPE;
BEGIN
	--create the batch job
	batch_job_pkg.enqueue(
		in_batch_job_type_id => batch_job_pkg.jt_anonymise_users,
		in_description => 'anonymise users',
		out_batch_job_id => out_batch_job_id
	);
	-- Fill in the job user
	FOR i IN in_user_sids.FIRST .. in_user_sids.LAST
	LOOP
		IF in_user_sids.EXISTS(i) THEN
			BEGIN
				INSERT INTO user_anonymisation_batch_job (batch_job_id, user_sid)
				VALUES(out_batch_job_id, in_user_sids(i));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore
			END;
		END IF;
	END LOOP;

END;

PROCEDURE ProcessAnonymiseUsersBatchJob (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result_desc					OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_count							NUMBER;
	v_i								NUMBER := 0;
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM user_anonymisation_batch_job
	 WHERE app_sid = v_app_sid
	   AND batch_job_id = in_batch_job_id;

	-- Anonymise each user
	FOR r IN (
		SELECT user_sid
		  FROM user_anonymisation_batch_job
		 WHERE app_sid = v_app_sid
		   AND batch_job_id = in_batch_job_id
	) LOOP
		-- Progress
		batch_job_pkg.SetProgress(in_batch_job_id, v_i, v_count);

		anonymiseUser(
			in_act			=> v_act, 
			in_user_sid		=> r.user_sid
		);
		v_i := v_i + 1;
	END LOOP;

	-- Clean up
	DELETE FROM user_anonymisation_batch_job
	 WHERE app_sid = v_app_sid
	   AND batch_job_id = in_batch_job_id;

	-- Complete
	batch_job_pkg.SetProgress(in_batch_job_id, v_count, v_count);
	out_result_desc := 'Users anonymised successfully';
	out_result_url := NULL;
END;

PROCEDURE UNSEC_SitesEnabledForAnonymisation(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM customer
		 WHERE auto_anonymisation_enabled = 1
		   AND scheduled_tasks_disabled = 0;
END;

PROCEDURE UsersEligibleForAnonymisation(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_anonymise_after_days			NUMBER;
BEGIN

	SELECT inactive_days_before_anonymisation
	  INTO v_anonymise_after_days
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

		-- If you are changing this SELECT, also modify the one in CountOfUsersEligibleForAnonymisation
		-- to maintain accuracy in count/data consistency
	OPEN out_cur FOR
		SELECT u.csr_user_sid
		  FROM csr.customer c
		  JOIN csr.csr_user u ON u.app_sid = c.app_sid
		  JOIN security.user_table s ON u.csr_user_sid = s.sid_id
		  LEFT JOIN csr.superadmin sa ON sa.csr_user_sid = u.csr_user_sid
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND sa.csr_user_sid IS NULL
		   AND c.auto_anonymisation_enabled = 1
		   AND s.account_enabled = 0
		   AND u.anonymised = 0
		   AND TRUNC(s.account_disabled_dtm) + v_anonymise_after_days <= TRUNC(SYSDATE);
END;

PROCEDURE CountOfUsersEligibleForAnonymisation(
	in_number_of_days			IN	NUMBER,
	out_number_of_users			OUT NUMBER
)
AS
	v_number_of_users			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_number_of_users
	  FROM csr.csr_user u
	  JOIN security.user_table s ON u.csr_user_sid = s.sid_id
	  LEFT JOIN csr.superadmin sa ON sa.csr_user_sid = u.csr_user_sid
	 WHERE u.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND sa.csr_user_sid IS NULL
	   AND s.account_enabled = 0
	   AND u.anonymised = 0
	   AND TRUNC(s.account_disabled_dtm) + in_number_of_days <= TRUNC(SYSDATE);

	out_number_of_users := v_number_of_users;
END;

END;
/
