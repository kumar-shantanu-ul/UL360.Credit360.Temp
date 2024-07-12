CREATE OR REPLACE PACKAGE BODY csr.Delegation_Pkg AS

/* known issues:
	- findoverlaps doesn't check *UP* the tree, i.e. if we choose singapore it doesn't barf at a delegation already set up for Asia/Pacific
	- alter to change delegation SO to a group, and added delegation_users as group members so that we can more reliably use security for permissions
	- needs a decent alerting mechanism where code can write to a table with messages etc that get bunched up and sent to users as requested. (like itruffle)
*/
-- Securable object callbacks.
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	-- delegations don't get trashed ATM but just for future!
	IF in_new_name IS NOT NULL THEN
		UPDATE DELEGATION SET name=in_new_name WHERE delegation_sid = in_sid_id;
	END IF;
END;

-- TODO: discourage deletion of delegations (move them into a trash can?)
-- This is provided for completeness though
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
	v_parent_sid	security_pkg.T_SID_ID;
	v_app_sid	security_pkg.T_SID_ID;
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.getSid(in_act_id, v_user_sid);

	-- if we have a parent then get the details
	SELECT parent_sid, app_sid
	  INTO v_parent_sid, v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_sid_Id;

	-- update parent's fully-delegated status (if not TLD)
	IF v_parent_sid != v_app_sid THEN
		UPDATE delegation
		   SET fully_delegated = csr_data_pkg.NOT_FULLY_DELEGATED
		 WHERE delegation_sid = v_parent_sid;
	END IF;

	-- for sending out alerts we need to keep some info about the delegation
	INSERT INTO deleted_delegation
		(delegation_sid, name, deleted_dtm, deleted_by_user_sid)
		SELECT delegation_sid, name, SYSDATE, v_user_sid
		  FROM delegation
		 WHERE delegation_sid = in_sid_id;
		 
	INSERT INTO deleted_delegation_description
		(delegation_sid, lang, description)
		SELECT delegation_sid, lang, description
		  FROM delegation_description
		 WHERE delegation_sid = in_sid_id;

 	-- clean up the sheet
	FOR r_s IN (
		SELECT sheet_id FROM sheet WHERE delegation_sid = in_sid_id
	)
	LOOP
		sheet_pkg.deleteSheet(r_s.sheet_id);
	END LOOP;

	-- erm - this isn't quite right but what should the history relate to?
	UPDATE sheet
	   SET last_sheet_history_id = NULL
	 WHERE last_sheet_history_id IN (
	     SELECT sheet_history_id
	 	   FROM sheet_history
	 	  WHERE to_delegation_sid = in_sid_id
	 );

	DELETE FROM sheet_history
	 WHERE to_delegation_sid = in_sid_id;

	-- <audit>
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_sid_id, 'Deleted');
	-- we need to set our audit log object_sid to null due to FK constraint
	UPDATE audit_log SET object_sid = null WHERE object_sid = in_sid_id;

	-- unhook anything referencing this as the master_delegation_sid
	UPDATE delegation
	   SET master_delegation_sid = NULL
	 WHERE master_delegation_sid = in_sid_id;

	-- unhook anything referencing this in a plan
	DELETE FROM deleg_plan_deleg_region_deleg
	 WHERE maps_to_root_deleg_sid = in_sid_id;

	-- also clears up delegation_comment (via cascade delete)
	DELETE FROM postit
	  WHERE postit_id IN (
		SELECT postit_id FROM delegation_comment WHERE delegation_sid = in_sid_id
	);

	DELETE FROM delegation_policy
	 WHERE delegation_sid = in_sid_id;

	-- clean up supply-chain delegations
	DELETE FROM supplier_delegation
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM supplier_delegation
	 WHERE tpl_delegation_sid = in_sid_id; -- XXX: do we need to tidy up more if it's the template, e.g. CHAIN.QUESTIONNAIRE_TYPE?

	DELETE FROM chain_tpl_delegation
	 WHERE tpl_delegation_sid = in_sid_id;

	-- clean up delegation_ind including conditions
    DELETE FROM deleg_ind_form_expr
     WHERE delegation_sid = in_sid_id;

	DELETE FROM form_expr
	 WHERE delegation_sid = in_sid_id;

    DELETE FROM deleg_ind_group_member WHERE delegation_sid = in_sid_id;
    DELETE FROM deleg_ind_group WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind_cond
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind_tag
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind_tag_list
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind_description
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_ind
	 WHERE delegation_sid = in_sid_id;

	-- clean up delegation management plan
	--DELETE FROM deleg_plan_deleg_region
	-- WHERE maps_to_deleg_sid = in_sid_id OR delegation_sid = in_sid_id;
	--DELETE FROM deleg_plan_deleg
	-- WHERE delegation_sid = in_sid_id;

	-- clean up rest of delegation;
	DELETE FROM delegation_tag
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_region_description
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_region
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_user_cover
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM delegation_user
	 WHERE delegation_sid = in_sid_id
	    OR inherited_from_sid = in_sid_id;

	DELETE FROM delegation_role
	 WHERE delegation_sid = in_sid_id 
	    OR inherited_from_sid = in_sid_id;	
	
	DELETE FROM deleg_meta_role_ind_selection
	 WHERE delegation_sid = in_sid_id;

	DELETE FROM deleg_plan_job
	 WHERE delegation_sid = in_sid_id;

	-- delete date schedules
	FOR r IN (
		SELECT delegation_date_schedule_id
		  FROM delegation
		 WHERE delegation_sid = in_sid_id
	) LOOP
		DELETE FROM sheet_date_schedule
		 WHERE delegation_date_schedule_id = r.delegation_date_schedule_id;

		UPDATE delegation
		   SET delegation_date_schedule_id = NULL
		 WHERE delegation_sid = in_sid_id;

		DELETE FROM delegation_date_schedule
		 WHERE delegation_date_schedule_id = r.delegation_date_schedule_id;
	END LOOP;

	--2: Error Description: ORA-02292: integrity constraint (REFDELEGATION2046) violated - child record found
	-- Constraint is from master_deleg and can occur if a user marks a delegation created by the delegation planner
	-- as a template (now called RefDELEGATION2059 in create_schema.sql)
	-- the following query can be used to find the problematic delegation:
	-- select * from deleg_plan_deleg_region_deleg
	-- where maps_to_root_deleg_sid in (select delegation_sid from master_deleg);
	DELETE FROM delegation 
	 WHERE delegation_sid = in_sid_id;	
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE delegation
	   SET parent_sid = in_new_parent_sid_id
	 WHERE delegation_sid = in_sid_id;
END;

-- called by val_pkg.setValue to allow us to unhook anything
-- e.g. if we keep a pointer to a val_id
PROCEDURE OnValChange(
	in_val_id		imp_val.set_val_id%TYPE,
	in_imp_val_id	imp_val.imp_val_id%TYPE
)
AS
BEGIN
	NULL;
END;

PROCEDURE INT_UNSEC_UpsertDelegationUser (
	in_delegation_sid				security_pkg.T_SID_ID,
	in_user_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_user.deleg_permission_set%TYPE,
	in_inherited_from_sid			delegation_user.inherited_from_sid%TYPE DEFAULT NULL
)
AS
BEGIN
	BEGIN
		INSERT INTO delegation_user
			(delegation_sid, user_sid, deleg_permission_set, inherited_from_sid)
		VALUES
			(in_delegation_sid, in_user_sid, in_permission_set, NVL(in_inherited_from_sid, in_delegation_sid));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE delegation_user
			   SET deleg_permission_set = in_permission_set
			 WHERE delegation_sid = in_delegation_sid
			   AND user_sid = in_user_sid
			   AND inherited_from_sid = in_inherited_from_sid;
	END;
END;

PROCEDURE UNSEC_AddUser(
	in_act_id						security_pkg.T_ACT_ID,
	in_delegation_sid				security_pkg.T_SID_ID,
	in_user_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_user.deleg_permission_set%TYPE DEFAULT DELEG_PERMISSION_DELEGEE
)
AS
	v_full_name	csr_user.full_name%TYPE;
BEGIN
	SELECT full_name
	  INTO v_full_name
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY','APP'), in_delegation_sid,
		'Assigned delegation user "{0}" ({1})', v_full_name, in_user_sid);

	INT_UNSEC_UpsertDelegationUser(in_delegation_sid, in_user_sid, in_permission_set);
	
	-- Add delegator permission to children
	FOR R IN (
		SELECT delegation_sid
		  FROM delegation
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 START WITH parent_sid = in_delegation_sid        
	) LOOP
		INT_UNSEC_UpsertDelegationUser(r.delegation_sid, in_user_sid, DELEG_PERMISSION_DELEGATOR, in_delegation_sid);
	END LOOP;
END;

PROCEDURE INT_UNSEC_UpsertDelegationRole (
	in_delegation_sid				security_pkg.T_SID_ID,
	in_role_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_role.deleg_permission_set%TYPE,
	in_inherited_from_sid			delegation_role.inherited_from_sid%TYPE DEFAULT NULL
)
AS
BEGIN
	BEGIN
		INSERT INTO delegation_role
			(delegation_sid, role_sid, deleg_permission_set, inherited_from_sid)
		VALUES
			(in_delegation_sid, in_role_sid, in_permission_set, NVL(in_inherited_from_sid, in_delegation_sid));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE delegation_role
			   SET deleg_permission_set = in_permission_set
			 WHERE delegation_sid = in_delegation_sid
			   AND role_sid = in_role_sid
			   AND inherited_from_sid = in_inherited_from_sid;
	END;
END;

PROCEDURE UNSEC_AddRole(
	in_act_id						security_pkg.T_ACT_ID,
	in_delegation_sid				security_pkg.T_SID_ID,
	in_role_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_role.deleg_permission_set%TYPE DEFAULT DELEG_PERMISSION_DELEGEE
)
AS
	v_name	role.name%TYPE;
BEGIN
	SELECT name
	  INTO v_name
	  FROM role
	 WHERE role_sid = in_role_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY','APP'), in_delegation_sid,
		'Assigned delegation role "{0}" ({1})', v_name, in_role_sid);
	
	INT_UNSEC_UpsertDelegationRole(in_delegation_sid, in_role_sid, in_permission_set);
	
	-- Add delegator permission to children
	FOR R IN (
		SELECT delegation_sid
		  FROM delegation
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 START WITH parent_sid = in_delegation_sid 
	) LOOP
		INT_UNSEC_UpsertDelegationRole(r.delegation_sid, in_role_sid, DELEG_PERMISSION_DELEGATOR, in_delegation_sid);
	END LOOP;
END;

FUNCTION INTERNAL_CheckSOPermission(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_delegation_sid				IN security_pkg.T_SID_ID,
	in_permission_set				IN delegation_user.deleg_permission_set%TYPE
) RETURN BOOLEAN
AS
	v_so_permission_set				security.acl.permission_set%TYPE := 0;
BEGIN
	--Convert permission set
	IF bitand(in_permission_set, DELEG_PERMISSION_READ) = DELEG_PERMISSION_READ THEN
		v_so_permission_set := v_so_permission_set + security.security_pkg.PERMISSION_READ;
	END IF;
	IF bitand(in_permission_set, DELEG_PERMISSION_WRITE) = DELEG_PERMISSION_WRITE THEN
		v_so_permission_set := v_so_permission_set + security.security_pkg.PERMISSION_WRITE;
	END IF;
	IF bitand(in_permission_set, DELEG_PERMISSION_DELETE) = DELEG_PERMISSION_DELETE THEN
		v_so_permission_set := v_so_permission_set + security.security_pkg.PERMISSION_DELETE;
	END IF;
	IF bitand(in_permission_set, DELEG_PERMISSION_ALTER) = DELEG_PERMISSION_ALTER THEN
		v_so_permission_set := v_so_permission_set + csr_data_pkg.PERMISSION_ALTER_SCHEMA;
	END IF;
	IF bitand(in_permission_set, DELEG_PERMISSION_OVERRIDE) = DELEG_PERMISSION_OVERRIDE THEN
		v_so_permission_set := v_so_permission_set + csr_data_pkg.PERMISSION_OVERRIDE_DELEGATOR;
	END IF;

	RETURN security.security_pkg.IsAccessAllowedSID(in_act_id, in_delegation_sid, v_so_permission_set);
END;

FUNCTION CheckDelegationPermission( 
	in_act_id						IN security_pkg.T_ACT_ID,
	in_delegation_sid				IN security_pkg.T_SID_ID,
	in_permission_set				IN delegation_user.deleg_permission_set%TYPE
) RETURN BOOLEAN
AS
	v_user_sid						security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- Allow if SuperAdmin or BuiltinAdmin.
	IF csr_user_pkg.IsSuperAdmin(v_user_sid) = 1 THEN
		RETURN TRUE;
	END IF;

	FOR r IN (
		SELECT deleg_permission_set
		  FROM (
			SELECT MAX(deleg_permission_set) deleg_permission_set
			  FROM delegation_user
			 WHERE user_sid = v_user_sid
			   AND delegation_sid = in_delegation_sid
			 UNION
			-- User has potentially different permissions on multiple regions do we take the most access or least? 
			SELECT MIN(deleg_permission_set) deleg_permission_set
			  FROM (
				-- If user has multiple roles take one with most permissions
				-- (currently not possible for delegation to have multiple roles via product 12-JUN-2018)				
				SELECT dr2.region_sid, MAX(deleg_permission_set) deleg_permission_set
				  FROM delegation_role dr
				  JOIN delegation_region dr2 ON dr.delegation_sid = dr2.delegation_sid 
				  JOIN region_role_member rrm
					ON rrm.app_sid = dr.app_sid
				   AND rrm.role_sid = dr.role_sid
				   AND rrm.user_sid = v_user_sid
				   AND rrm.region_sid = dr2.region_sid
				 WHERE dr.delegation_sid = in_delegation_sid 
				 GROUP BY dr2.region_sid
				)
			) t
		 WHERE bitand(deleg_permission_set, in_permission_set) = in_permission_set   
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	-- Check access to SO.
	RETURN INTERNAL_CheckSOPermission(in_act_id, in_delegation_sid, in_permission_set);		
	
END;

FUNCTION SQL_CheckDelegationPermission( 
	in_act_id						IN security_pkg.T_ACT_ID,
	in_delegation_sid				IN security_pkg.T_SID_ID,
	in_permission_set				IN delegation_user.deleg_permission_set%TYPE
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckDelegationPermission(in_act_id, in_delegation_sid, in_permission_set) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

PROCEDURE INT_UNSEC_PropogateDelegPerm(
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_child_sid					IN security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 START WITH delegation_sid = in_child_sid
	   CONNECT BY PRIOR delegation_sid = parent_sid)
	LOOP
		MERGE /*+ALL_ROWS*/ INTO delegation_user du
		USING (
			SELECT app_sid, r.delegation_sid delegation_sid, user_sid, deleg_permission_set, inherited_from_sid
			  FROM delegation_user du
			 WHERE delegation_sid = in_parent_sid) i
		   ON (du.app_sid = i.app_sid AND du.delegation_sid = i.delegation_sid AND du.user_sid = i.user_sid AND du.inherited_from_sid = i.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET du.deleg_permission_set = GREATEST(du.deleg_permission_set, i.deleg_permission_set)
		 WHEN NOT MATCHED THEN
			INSERT (du.app_sid, du.delegation_sid, du.user_sid, du.deleg_permission_set, du.inherited_from_sid)
			VALUES (i.app_sid, i.delegation_sid, i.user_sid, i.deleg_permission_set, i.inherited_from_sid);
			
		MERGE /*+ALL_ROWS*/ INTO delegation_role dr
		USING (
			SELECT app_sid, r.delegation_sid delegation_sid, role_sid, deleg_permission_set, inherited_from_sid
			  FROM delegation_role
			 WHERE delegation_sid = in_parent_sid) i
		   ON (dr.app_sid = i.app_sid AND dr.delegation_sid = i.delegation_sid AND dr.role_sid = i.role_sid AND dr.inherited_from_sid = i.inherited_from_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET dr.deleg_permission_set = GREATEST(dr.deleg_permission_set, i.deleg_permission_set)
		 WHEN NOT MATCHED THEN
			INSERT (dr.app_sid, dr.delegation_sid, dr.role_sid, dr.deleg_permission_set, dr.inherited_from_sid)
			VALUES (i.app_sid, i.delegation_sid, i.role_sid, i.deleg_permission_set, i.inherited_from_sid);
	END LOOP;
END;

PROCEDURE INT_UNSEC_AddDelegatorPerm(
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_child_sid					IN security_pkg.T_SID_ID
)
AS
BEGIN
	MERGE /*+ALL_ROWS*/ INTO delegation_user du
	USING (
		SELECT app_sid, in_child_sid delegation_sid, user_sid, DELEG_PERMISSION_DELEGATOR deleg_permission_set, in_parent_sid inherited_from_sid
		  FROM delegation_user
		 WHERE delegation_sid = in_parent_sid
		   AND inherited_from_sid = delegation_sid) i
	   ON (du.app_sid = i.app_sid AND du.delegation_sid = i.delegation_sid AND du.user_sid = i.user_sid AND du.inherited_from_sid = i.inherited_from_sid)
	 WHEN MATCHED THEN
		UPDATE
		   SET du.deleg_permission_set = GREATEST(du.deleg_permission_set, DELEG_PERMISSION_DELEGATOR)
	 WHEN NOT MATCHED THEN
		INSERT (du.app_sid, du.delegation_sid, du.user_sid, du.deleg_permission_set, du.inherited_from_sid)
		VALUES (i.app_sid, i.delegation_sid, i.user_sid, i.deleg_permission_set, i.inherited_from_sid);
		
	MERGE /*+ALL_ROWS*/ INTO delegation_role dr
	USING (
		SELECT app_sid, in_child_sid delegation_sid, role_sid, DELEG_PERMISSION_DELEGATOR deleg_permission_set, in_parent_sid inherited_from_sid
		  FROM delegation_role
		 WHERE delegation_sid = in_parent_sid
		   AND inherited_from_sid = in_parent_sid) i
	   ON (dr.app_sid = i.app_sid AND dr.delegation_sid = i.delegation_sid AND dr.role_sid = i.role_sid AND dr.inherited_from_sid = i.inherited_from_sid)
	 WHEN MATCHED THEN
		UPDATE
		   SET dr.deleg_permission_set = GREATEST(dr.deleg_permission_set, DELEG_PERMISSION_DELEGATOR)
	 WHEN NOT MATCHED THEN
		INSERT (dr.app_sid, dr.delegation_sid, dr.role_sid, dr.deleg_permission_set, dr.inherited_from_sid)
		VALUES (i.app_sid, i.delegation_sid, i.role_sid, i.deleg_permission_set, i.inherited_from_sid);
END;

FUNCTION GetRootDelegationSid(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM (
		SELECT delegation_sid, level, ROW_NUMBER() OVER (ORDER BY level DESC) rn
		  FROM delegation
		 START WITH delegation_sid = in_delegation_sid
		CONNECT BY PRIOR parent_sid = delegation_sid
	 )
	 WHERE rn = 1;

	 RETURN v_delegation_sid;
END;

-- ============================
-- create and amend delegations
-- ============================
PROCEDURE CreateTopLevelDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_name							IN	delegation.name%TYPE,
	in_date_from					IN	delegation.start_dtm%TYPE,
	in_date_to						IN	delegation.end_dtm%TYPE,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_allocate_users_to			IN	delegation.allocate_users_to%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_note							IN	form.note%TYPE,
	in_group_by						IN	delegation.group_by%TYPE,
	in_schedule_xml					IN	delegation.schedule_xml%TYPE,			--this is submission_schedule.
	in_submission_offset			IN	delegation.submission_offset%TYPE,
	in_reminder_offset				IN	delegation.reminder_offset%TYPE,
	in_note_mandatory				IN	delegation.is_note_mandatory%TYPE,
	in_flag_mandatory				IN	delegation.is_flag_mandatory%TYPE,
	in_policy						IN	delegation_policy.submit_confirmation_text%TYPE DEFAULT NULL,
	in_vis_matrix_tag_group			IN 	DELEGATION.tag_visibility_matrix_group_id%TYPE DEFAULT NULL,
	in_allow_multi_period			IN	delegation.allow_multi_period%TYPE DEFAULT 0,
	out_delegation_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_user_sid						security_pkg.T_SID_ID;					-- FOR USING IF USER_CREATOR_SID IS INCLUDED.
	v_csr_delegation_sid			security_pkg.T_SID_ID;
	v_editing_url					delegation.editing_url%TYPE;
BEGIN
	user_pkg.getsid(in_act_id, v_user_sid);
	v_csr_delegation_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Delegations');

	securableobject_pkg.CreateSO(in_act_id, v_csr_delegation_sid, class_pkg.getClassID('CSRDelegation'), NULL, out_delegation_sid);

	SELECT editing_url
	  INTO v_editing_url
	  FROM customer
	 WHERE app_sid = in_app_sid;

	INSERT INTO delegation
		(delegation_sid, parent_sid, name, created_by_sid, schedule_xml, start_dtm, end_dtm,
		 note, period_set_id, period_interval_id, group_by, allocate_users_to, app_sid,
		 submission_offset, reminder_offset, is_note_mandatory, is_flag_mandatory, editing_url, tag_visibility_matrix_group_id, allow_multi_period)
	VALUES
		(out_delegation_sid, in_app_sid, trim(in_name), v_user_sid, in_schedule_xml,
		 in_date_from, in_date_to, in_note, in_period_set_id, in_period_interval_id,
		 in_group_by, in_allocate_users_to, in_app_sid, NVL(in_submission_offset, 0),
		 NVL(in_reminder_offset, 0), in_note_mandatory, in_flag_mandatory, v_editing_url, in_vis_matrix_tag_group, in_allow_multi_period);
	
	INT_UNSEC_UpsertDelegationUser(out_delegation_sid, v_user_sid, DELEG_PERMISSION_DELEGATOR);
	-- COS TopLevelDelegations ARE DELEGATED TO CREATOR ITSELF!!!.

	IF LENGTH(in_policy) > 0 THEN
		INSERT INTO delegation_policy (delegation_sid, submit_confirmation_text)
			VALUES (out_delegation_sid, in_policy);
	END IF;

	-- <audit>
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, in_app_sid, out_delegation_sid,
		'Created');
END;

PROCEDURE AddDescriptionToDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_lang							IN	delegation_description.lang%TYPE,
	in_description					IN	delegation_description.description%TYPE
) AS
BEGIN
	IF LENGTH(TRIM(in_description)) > 0 THEN
		INSERT INTO delegation_description (delegation_sid, lang, description, last_changed_dtm)
			VALUES (in_delegation_sid, in_lang, TRIM(in_description), SYSDATE);
	END IF;
END;

PROCEDURE AddIndicatorToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_description					IN	delegation_ind_description.description%TYPE,
	in_pos							IN	delegation_ind.pos%TYPE
)
AS
	v_langs							security_pkg.T_VARCHAR2_ARRAY;
	v_translations					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	v_langs(1) := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
	v_translations(1) := in_description;
	AddIndicatorToTLD(in_act_id, in_delegation_sid, in_sid_id, v_langs, v_translations, in_pos);
END;

PROCEDURE AddIndicatorToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_ind.pos%TYPE
)
AS
	v_ind_sid						security_pkg.T_SID_IDS;
BEGIN
	v_ind_sid(1) := in_sid_id;
	AddIndicatorsToTLD(in_delegation_sid, v_ind_sid, v_ind_sid, in_langs, in_translations, in_pos);
END;

PROCEDURE AddIndicatorsToTLD(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_tr_ind_sids					IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_ind.pos%TYPE DEFAULT 0
)
AS
	v_act_id						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_description					ind_description.description%TYPE;
	v_lang_pointer					NUMBER;
BEGIN	
	IF (in_ind_sids.COUNT = 0 OR (in_ind_sids.COUNT = 1 AND in_ind_sids(1) IS NULL)) THEN
		RETURN;
	END IF;
	
	-- set indicators
	FOR i IN 1 .. in_ind_sids.COUNT LOOP
		BEGIN
			INSERT INTO delegation_ind (
				delegation_sid, ind_sid, pos, mandatory
			) VALUES (
				in_delegation_sid, in_ind_sids(i), in_pos + i - 1, 0
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- ignore indicators that are already part of the delegation
				GOTO cont;
		END;
	
		-- Add any indicators that are needed for aggregation or ind selection groups, but hide them
		INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility)
			SELECT in_delegation_sid, dgai.aggregate_to_ind_sid, 0, 'HIDE'
			  FROM delegation_grid_aggregate_ind dgai
			 WHERE dgai.ind_sid = in_ind_sids(i)
			   AND dgai.aggregate_to_ind_sid NOT IN (SELECT ind_sid
													   FROM delegation_ind
													  WHERE delegation_sid = in_delegation_sid);

		INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility)
			SELECT in_delegation_sid, isgm.ind_sid, 0, 'HIDE'
			  FROM ind_selection_group_member isgm
			 WHERE isgm.master_ind_sid IN (SELECT master_ind_sid
											 FROM v$ind_selection_group_dep
											WHERE ind_sid = in_ind_sids(i))
			   AND isgm.ind_sid NOT IN (SELECT ind_sid
										  FROM delegation_ind
										 WHERE delegation_sid = in_delegation_sid);
		-- <audit>
		SELECT description
		  INTO v_description
		  FROM ind_description
		 WHERE ind_sid = in_ind_sids(i)
		   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANG'), 'en');

		csr_data_pkg.WriteAuditLogEntry(v_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_delegation_sid,
			'Added indicator "{0}" ("{1}")', v_description, in_ind_sids(i));
		<<CONT>>
		NULL; -- END cannot be immediately preceeded by a <<marker>>
	END LOOP;

	-- set translations
	IF NOT (in_tr_ind_sids.COUNT = 0 OR (in_tr_ind_sids.COUNT = 1 AND in_tr_ind_sids(1) IS NULL)) THEN
		FOR i IN 1 .. in_tr_ind_sids.COUNT LOOP
			FOR j IN 1 .. in_langs.COUNT LOOP
				v_lang_pointer := (i - 1) * in_langs.COUNT + j;
	
				INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
					SELECT in_delegation_sid, in_tr_ind_sids(i), in_langs(j), in_translations( v_lang_pointer )
					  FROM dual
					 MINUS
					SELECT in_delegation_sid, ind_sid, lang, description
					  FROM ind_description
					 WHERE ind_sid = in_tr_ind_sids(i)
					   AND lang = in_langs(j);
			END LOOP;
		END LOOP;
	END IF;
		
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
				 FROM delegation_ind di, delegation d
				WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
				  AND di.delegation_sid = in_delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;
	
	-- no longer fully delegated
	UPDATE delegation
	   SET fully_delegated = csr_data_pkg.NOT_FULLY_DELEGATED
	 WHERE delegation_sid = in_delegation_sid;	
END;

PROCEDURE AddRegionToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_description					IN	delegation_region_description.description%TYPE,
	in_pos							IN	delegation_region.pos%TYPE
)
AS
	v_langs							security_pkg.T_VARCHAR2_ARRAY;
	v_translations					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	v_langs(1) := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
	v_translations(1) := in_description;
	AddRegionToTLD(in_act_id, in_delegation_sid, in_sid_id, v_langs, v_translations, in_pos);
END;

PROCEDURE AddRegionToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_region.pos%TYPE
)
AS
	v_region_sid					security_pkg.T_SID_IDS;
BEGIN
	v_region_sid(1) := in_sid_id;
	AddRegionsToTLD(in_delegation_sid, v_region_sid, v_region_sid, in_langs, in_translations, in_pos);
END;

PROCEDURE AddRegionsToTLD(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_tr_region_sids				IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_region.pos%TYPE DEFAULT 0
)
AS
	v_description					region_description.description%TYPE;
	v_lang_pointer					NUMBER;
BEGIN
	IF (in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL)) THEN
		RETURN;
	END IF;
	
	FOR i IN 1 .. in_region_sids.COUNT LOOP
		INSERT INTO delegation_region
			(delegation_sid, region_sid, pos, mandatory, aggregate_to_region_sid, visibility)
		VALUES
			(in_delegation_sid, in_region_sids(i), in_pos + i - 1, 0, in_region_sids(i), 'SHOW');
			
		SELECT description
		  INTO v_description
		  FROM region_description
		 WHERE region_sid = in_region_sids(i)
		   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANG'), 'en');

		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_delegation_sid,
			'Added region "{0}" ("{1}")', v_description, in_region_sids(i));
	END LOOP;
	
	-- set translations
	IF NOT (in_tr_region_sids.COUNT = 0 OR (in_tr_region_sids.COUNT = 1 AND in_tr_region_sids(1) IS NULL)) THEN
		FOR i IN 1 .. in_tr_region_sids.COUNT LOOP
			FOR j IN 1 .. in_langs.COUNT LOOP
				v_lang_pointer := (i - 1) * in_langs.COUNT + j;
	
				INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
					SELECT in_delegation_sid, in_tr_region_sids(i), in_langs(j), in_translations( v_lang_pointer )
					  FROM dual
					 MINUS
					SELECT in_delegation_sid, region_sid, lang, description
					  FROM region_description
					 WHERE region_sid = in_tr_region_sids(i)
					   AND lang = in_langs(j);
			END LOOP;
		END LOOP;
	END IF;
	-- no longer fully delegated
	UPDATE delegation
	   SET fully_delegated = csr_data_pkg.NOT_FULLY_DELEGATED
	 WHERE delegation_sid = in_delegation_sid;

	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
				 FROM delegation_ind di, delegation d
				WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
				  AND di.delegation_sid = in_delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;
END;

PROCEDURE CreateNonTopLevelDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_app_sid 						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN	delegation.name%TYPE,
	in_indicators_list				IN	VARCHAR2 DEFAULT NULL,
	in_regions_list					IN	VARCHAR2 DEFAULT NULL,
	in_mandatory_list				IN	VARCHAR2 DEFAULT NULL,
	in_user_sid_list				IN	VARCHAR2 DEFAULT NULL,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_schedule_xml					IN	delegation.schedule_xml%TYPE,
	in_note							IN	delegation.note%TYPE,
	in_submission_offset			IN	delegation.submission_offset%TYPE DEFAULT NULL,
	in_part_of_deleg_plan			IN	NUMBER DEFAULT 0,
	in_show_aggregate				IN	delegation.show_aggregate%TYPE DEFAULT 0,
	out_delegation_sid				OUT security_pkg.T_SID_ID
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_group_by						delegation.group_by%TYPE;				-- TO KEEP COMPATIBILITY WITH PARENT DELEGATION.
	v_allocate_users_to				delegation.allocate_users_to%TYPE;
	v_start_dtm						delegation.start_dtm%TYPE;
	v_end_dtm						delegation.end_dtm%TYPE;
	v_note_mandatory				delegation.is_note_mandatory%TYPE;
	v_flag_mandatory				delegation.is_flag_mandatory%TYPE;
	v_grid_xml						delegation.grid_xml%TYPE;
	v_section_xml					delegation.section_xml%TYPE;
	v_editing_url					delegation.editing_url%TYPE;
	v_submission_offset       		delegation.submission_offset%TYPE;
	v_reminder_offset       		delegation.reminder_offset%TYPE;
	v_layout_id				  		delegation.layout_id%TYPE;
	v_master_delegation_sid			security_pkg.T_SID_ID;
	v_hide_sheet_period				DELEGATION.hide_sheet_period%TYPE;
	v_tag_visibility_matrix_group	delegation.tag_visibility_matrix_group_id%TYPE;
	v_allow_multi_period			delegation.allow_multi_period%TYPE;
	t_indicators					T_SPLIT_TABLE;
	t_regions						T_SPLIT_TABLE;
	t_users							T_SPLIT_TABLE;
	t_mandatories					T_SPLIT_TABLE;
	v_is_fully_delegated			NUMBER;
BEGIN
	user_pkg.getsid(in_act_id, v_user_sid);
	
	IF NOT CheckDelegationPermission(in_act_id, in_parent_sid, DELEG_PERMISSION_WRITE) OR 
		NOT csr_data_pkg.CheckCapability(in_act_id, 'Subdelegation') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating child delegation');
	END IF;
	
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, Security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(in_parent_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_sid, security_pkg.PERMISSION_LIST_CONTENTS+security_pkg.PERMISSION_ADD_CONTENTS);
	END IF;
	-- create child delegation object with null SO name - we might have several with the same name
	securableobject_pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.getClassID('CSRDelegation'), NULL, out_delegation_sid);

	SELECT allocate_users_to, start_dtm, end_dtm, group_by, is_note_mandatory, is_flag_mandatory,
		   editing_url, grid_xml, section_xml, reminder_offset, submission_offset, master_delegation_sid,
		   hide_sheet_period, tag_visibility_matrix_group_id, allow_multi_period, layout_id
	  INTO v_allocate_users_to, v_start_dtm, v_end_dtm, v_group_by, v_note_mandatory, v_flag_mandatory,
	  	   v_editing_url, v_grid_xml, v_section_xml, v_reminder_offset, v_submission_offset,
	  	   v_master_delegation_sid, v_hide_sheet_period, v_tag_visibility_matrix_group, v_allow_multi_period, v_layout_id
	  FROM delegation
	 WHERE delegation_sid = in_parent_sid;

	t_indicators 	:= Utils_Pkg.splitString(in_indicators_list,',');
	t_regions	 	:= Utils_Pkg.splitstring(in_regions_list, ',');
	t_users		 	:= Utils_Pkg.SplitString(in_user_sid_list, ',');
	t_mandatories	:= Utils_Pkg.splitstring(in_mandatory_list, ',');

	INSERT INTO delegation
		(delegation_sid, parent_sid, name, created_by_sid, start_dtm, end_dtm, editing_url,
		 note, period_set_id, period_interval_id, group_by, allocate_users_to, app_sid,
		 is_note_mandatory, is_flag_mandatory, schedule_xml, section_xml, grid_xml,
		 reminder_offset, submission_offset, master_delegation_sid, show_aggregate,
		 hide_sheet_period, tag_visibility_matrix_group_id, allow_multi_period, layout_id)
	VALUES
		(out_delegation_sid, in_parent_sid, trim(in_name), v_user_sid, v_start_dtm, v_end_dtm,
		 v_editing_url, in_note, in_period_set_id, in_period_interval_id, v_group_by,
		 v_allocate_users_to, in_app_sid, v_note_mandatory, v_flag_mandatory, in_schedule_xml,
		 v_section_xml, v_grid_xml, v_reminder_offset, NVL(in_submission_offset, v_submission_offset),
		 v_master_delegation_sid, in_show_aggregate, v_hide_sheet_period, v_tag_visibility_matrix_group, v_allow_multi_period, v_layout_id);

	 -- XXX: bit nasty but if you're changing this then you also have to fix up deleg_plan_body which does it's own variant on this.	
	INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na)
		SELECT out_delegation_sid, t.item, mandatory, di.pos, section_Key, visibility, css_class, var_expl_group_id, meta_role, di.allowed_na
		  FROM TABLE (t_indicators) t, delegation_ind di
		 WHERE t.item = di.ind_sid and di.delegation_sid = in_parent_sid;

	INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT out_delegation_sid, did.ind_sid, did.lang, did.description
		  FROM TABLE (t_indicators) t, delegation_ind_description did
		 WHERE t.item = did.ind_sid and did.delegation_sid = in_parent_sid;

	-- Add hidden indicators for aggregating into from grids
	INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility, allowed_na)
		SELECT out_delegation_sid, di.ind_sid, 0, 'HIDE', di.allowed_na
		  FROM delegation_ind di, delegation_grid_aggregate_ind dgai
		 WHERE di.delegation_sid = out_delegation_sid
		   AND di.ind_sid = dgai.ind_sid
		   AND dgai.aggregate_to_ind_sid NOT IN (SELECT ind_sid
		   										   FROM delegation_ind
		   										  WHERE delegation_sid = out_delegation_sid);

	-- Add hidden indicators for ind selection groups
	INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility)
		SELECT out_delegation_sid, isgm.ind_sid, 0, 'HIDE'
		  FROM ind_selection_group_member isgm
		 WHERE isgm.master_ind_sid IN (SELECT isgd.master_ind_sid
		 								 FROM v$ind_selection_group_dep isgd, delegation_ind di
		 								WHERE di.app_sid = isgd.app_sid AND di.ind_sid = isgd.ind_sid
		 								  AND di.delegation_sid = out_delegation_sid)
		   AND isgm.ind_sid NOT IN (SELECT ind_sid
		   							  FROM delegation_ind
		   							 WHERE delegation_sid = out_delegation_sid);

	-- TODO: this should surely inherit from parent?
	UPDATE delegation_ind
	   SET mandatory = 1
	 WHERE delegation_sid = out_delegation_sid
	   AND ind_sid IN (SELECT item FROM TABLE (t_mandatories));

	INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility, allowed_na, hide_after_dtm, hide_inclusive)
		SELECT out_delegation_sid, item, NVL(dr.pos, t.pos), item, NVL(dr.visibility, 'SHOW'), NVL(dr.allowed_na, 0),
		       dr.hide_after_dtm, NVL(dr.hide_inclusive, 0)
		  FROM TABLE (t_regions) t, delegation_region dr, region r
		 WHERE r.region_sid = t.item AND t.item = dr.region_sid(+) and dr.delegation_sid(+) = in_parent_sid;

	INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
		SELECT out_delegation_sid, drd.region_sid, drd.lang, drd.description
		  FROM TABLE (t_regions) t, delegation_region_description drd
		 WHERE t.item = drd.region_sid and drd.delegation_sid = in_parent_sid;
		 
	INSERT INTO delegation_description (delegation_sid, lang, description, last_changed_dtm)
		SELECT out_delegation_sid, dd.lang, dd.description, SYSDATE
		  FROM delegation_description dd
		 WHERE dd.delegation_sid = in_parent_sid;

	INSERT INTO delegation_tag (delegation_sid, tag_id)
		SELECT out_delegation_sid, tag_id
		  FROM delegation_tag
		 WHERE delegation_sid = in_parent_sid;

	UPDATE delegation_region
	   SET mandatory = 1
	 WHERE delegation_sid = out_delegation_sid
	   AND region_sid IN (SELECT item FROM TABLE (t_mandatories));

	-- Group (GA) -> EMEA (CR) -> France (A)
	--												 -> Germany (B)
	--												 -> Spain (C)

	-- Group (GA) -> EMEA (CR) -> France (A)
	--												 -> Germany (B)
	--												 -> Spain (C)


	FOR r IN (
		SELECT DISTINCT item FROM TABLE (t_users)
	)
	LOOP
		UNSEC_AddUser(in_act_id, out_delegation_sid, r.item);
	END LOOP;
	
	INT_UNSEC_AddDelegatorPerm(in_parent_sid, out_delegation_sid);
	INT_UNSEC_PropogateDelegPerm(in_parent_sid, out_delegation_sid);

	-- is parent fully delegated?
	v_is_fully_delegated := delegation_pkg.isFullyDelegated(in_parent_sid);
	UPDATE delegation
	   SET fully_delegated = v_is_fully_delegated
	 WHERE delegation_sid = in_parent_sid;

	-- <audit>
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, in_app_sid, out_delegation_sid,
		'Delegated from parent delegation "{0}"', in_parent_sid);

	-- <audit>
	FOR r IN (
		SELECT description, region_sid
		  FROM v$delegation_region
		 WHERE delegation_sid = out_delegation_sid
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, in_app_sid, out_delegation_sid,
			'Added region "{0}" ("{1}")', r.description, r.region_sid);
	END LOOP;

	-- <audit>
	FOR r IN (
		SELECT description, ind_sid
		  FROM v$delegation_ind
		 WHERE delegation_sid = out_delegation_sid
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, in_app_sid, out_delegation_sid,
			'Added indicator "{0}" ("{1}")', r.description, r.ind_sid);
	END LOOP;

	-- flag this chain as changed if it's come from a delegation plan (and this call isn't part of a deleg plan applying)
	IF in_part_of_deleg_plan != 1 THEN
		UPDATE deleg_plan_deleg_region_deleg
		   SET has_manual_amends = 1
		 WHERE maps_to_root_deleg_sid = delegation_pkg.GetRootDelegationSid(out_delegation_sid);
	END IF;

	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid = out_delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;
END;

PROCEDURE INTERNAL_CopyRootDelegBits(
	in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_delegation_sid		IN security_pkg.T_SID_ID
)
AS
	v_delegation_ind_cond_id	delegation_ind_cond.delegation_ind_cond_id%TYPE;
BEGIN
	-- clean up existing data
	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_sid = in_new_delegation_sid;
	DELETE FROM delegation_ind_cond
	 WHERE delegation_sid = in_new_delegation_sid;
	DELETE FROM delegation_ind_tag
	 WHERE delegation_sid = in_new_delegation_sid;
	DELETE FROM delegation_ind_tag_list
	 WHERE delegation_sid = in_new_delegation_sid;
	DELETE FROM delegation_tag
	 WHERE delegation_sid = in_new_delegation_sid;
    DELETE FROM form_expr
     WHERE delegation_sid = in_new_delegation_sid;
    DELETE FROM deleg_ind_form_expr
     WHERE delegation_sid = in_new_delegation_sid;
    DELETE FROM deleg_ind_group_member
     WHERE delegation_sid = in_new_delegation_sid;
    DELETE FROM deleg_ind_group
     WHERE delegation_sid = in_new_delegation_sid;

	-- insert new stuff
	INSERT INTO delegation_tag (delegation_sid, tag_id)
		SELECT in_new_delegation_sid, tag_id
		  FROM delegation_tag
		 WHERE delegation_sid = in_copy_delegation_sid;

	-- copy over conditional stuff to point to us instead as we're a new root
	INSERT INTO delegation_ind_tag_list (delegation_sid, tag)
		SELECT in_new_delegation_sid, tag
		  FROM delegation_ind_tag_list
		 WHERE delegation_sid = in_copy_delegation_sid;

	INSERT INTO delegation_ind_tag (delegation_sid, ind_sid, tag)
		SELECT in_new_delegation_sid, ind_sid, tag
		  FROM delegation_ind_tag
		 WHERE delegation_sid = in_copy_delegation_sid
		   AND ind_sid IN (
			SELECT ind_sid -- filter out any inds that have been skipped for any reason
			  FROM delegation_ind
			 WHERE delegation_sid = in_new_delegation_sid
		   );

	DELETE FROM map_id;
	INSERT INTO map_id (old_id, new_id)
        SELECT deleg_ind_group_id, deleg_ind_group_id_seq.nextval
		  FROM deleg_ind_group
		 WHERE delegation_sid = in_copy_delegation_sid;

	INSERT INTO deleg_ind_group (deleg_ind_group_id, delegation_sid, title, start_collapsed)
        SELECT mid.new_id, in_new_delegation_sid, dig.title, dig.start_collapsed
		  FROM deleg_ind_group dig, map_id mid
		 WHERE mid.old_id = dig.deleg_ind_group_id
		   AND dig.delegation_sid = in_copy_delegation_sid;

	INSERT INTO deleg_ind_group_member (deleg_ind_group_id, delegation_sid, ind_sid)
		SELECT mid.new_id, in_new_delegation_sid, digm.ind_sid
		  FROM deleg_ind_group_member digm, map_id mid, delegation_ind di
		 WHERE mid.old_id = digm.deleg_ind_group_id
		   AND digm.delegation_sid = in_copy_delegation_sid
		   AND digm.app_sid = di.app_sid AND digm.ind_sid = di.ind_sid
		   AND di.delegation_sid = in_new_delegation_sid;

    -- copy over form expressions
	DELETE FROM map_id;
	INSERT INTO map_id (old_id, new_id)
		SELECT form_expr_id, form_expr_id_seq.nextval next_id
		  FROM form_expr
         WHERE delegation_sid = in_copy_delegation_sid;

	INSERT INTO form_expr (form_expr_id, delegation_sid, description, expr)
		SELECT mid.new_id, in_new_delegation_sid, fe.description, fe.expr
		  FROM form_expr fe, map_id mid
		 WHERE mid.old_id = fe.form_expr_id;

    INSERT INTO deleg_ind_form_expr (delegation_sid, ind_sid, form_expr_id)
		SELECT in_new_delegation_sid, dife.ind_sid, mid.new_id
		  FROM deleg_ind_form_expr dife, map_id mid, delegation_ind di
		 WHERE mid.old_id = dife.form_expr_id
		   AND dife.app_sid = di.app_sid AND dife.ind_sid = di.ind_sid
		   AND di.delegation_sid = in_new_delegation_sid;

	DELETE FROM map_id;
	INSERT INTO map_id (old_id, new_id)
		SELECT delegation_ind_cond_id, delegation_ind_cond_id_seq.nextval
		  FROM delegation_ind_cond
		 WHERE delegation_sid = in_copy_delegation_sid
		   AND ind_sid IN (
			SELECT ind_sid -- filter out any inds that have been skipped for any reason
			  FROM delegation_ind
			 WHERE delegation_sid = in_new_delegation_sid
		   );

	INSERT INTO delegation_ind_cond (delegation_sid, ind_sid, delegation_ind_cond_id, expr)
		SELECT in_new_delegation_sid, dic.ind_sid, mid.new_id, dic.expr
		  FROM delegation_ind_cond dic, map_id mid
		 WHERE mid.old_id = dic.delegation_ind_cond_id;

	INSERT INTO delegation_ind_cond_action (delegation_sid, ind_sid, delegation_ind_cond_id, action, tag)
		SELECT in_new_delegation_sid, dica.ind_sid, mid.new_id, dica.action, dica.tag
		  FROM delegation_ind_cond_action dica, map_id mid
		 WHERE dica.delegation_ind_cond_id = mid.old_id;
END;

PROCEDURE CopyDelegation(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_parent_sid				IN  security_pkg.T_SID_ID,
 	in_new_name					IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    out_new_delegation_sid		OUT security_pkg.T_SID_ID
)
AS
    v_require_active_regions	NUMBER := 0;
    v_sheet_id					csr_data_pkg.T_SHEET_ID;
    v_end_dtm					DATE;
	v_not_found					BOOLEAN;
	CURSOR c IS
		 SELECT delegation_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
		 		allocate_users_to, app_sid, note, group_by, schedule_xml, editing_url, 
		 		reminder_offset, is_note_mandatory, is_flag_mandatory, created_by_sid, 1 lv, 
		 		section_xml, grid_xml, show_aggregate, master_delegation_sid, 
		 		submit_confirmation_text, submission_offset, layout_id, tag_visibility_matrix_group_id, allow_multi_period
	       FROM v$delegation_hierarchical
		  WHERE delegation_sid = in_copy_delegation_sid;
	r	c%ROWTYPE;
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_copy_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the delegation with sid '||in_copy_delegation_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing data for the delegation with sid '||in_copy_delegation_sid);
	END IF;

	IF in_parent_sid IS NULL THEN
		-- create top level delegation
		delegation_pkg.CreateTopLevelDelegation(
			in_act_id				=> in_act_id,
			in_name					=> NVL(in_new_name, r.name),
			in_date_from			=> r.start_dtm,
			in_date_to				=> r.end_dtm,
			in_period_set_id		=> r.period_set_id,
			in_period_interval_id	=> r.period_interval_id,
			in_allocate_users_to	=> r.allocate_users_to,
			in_app_sid				=> r.app_sid,
			in_note					=> r.note,
			in_group_by				=> r.group_by,
			in_schedule_xml			=> r.schedule_xml,
			in_reminder_offset		=> r.reminder_offset,
			in_submission_offset	=> r.submission_offset,
			in_note_mandatory		=> r.is_note_mandatory,
			in_flag_mandatory		=> r.is_flag_mandatory,
			in_policy				=> r.submit_confirmation_text,
			in_vis_matrix_tag_group	=> r.tag_visibility_matrix_group_id,
			in_allow_multi_period	=> r.allow_multi_period,
			out_delegation_sid		=> out_new_delegation_sid);
	ELSE
		-- create non top level delegation
		delegation_pkg.CreateNonTopLevelDelegation(
			in_act_id				=> in_act_id,
			in_parent_sid			=> in_parent_sid,
			in_app_sid 				=> r.app_sid,
			in_name					=> NVL(in_new_name, r.name),
			in_period_set_id		=> r.period_set_id,
			in_period_interval_id	=> r.period_interval_id,
			in_schedule_xml			=> r.schedule_xml,
			in_note					=> r.note,
			out_delegation_sid		=> out_new_delegation_sid
		);

		-- flag this chain as changed if it's come from a delegation plan
		UPDATE deleg_plan_deleg_region_deleg
		   SET has_manual_amends = 1
		 WHERE maps_to_root_deleg_sid = delegation_pkg.GetRootDelegationSid(in_parent_sid);
	END IF;

	-- manually update some fields
	UPDATE delegation
	   SET editing_url = r.editing_url, section_xml = r.section_xml,
		   grid_xml = r.grid_xml, show_aggregate = r.show_aggregate,
		   master_delegation_sid = NVL(r.master_delegation_sid, in_copy_delegation_sid), -- retain master delegation sid where possible
		   layout_id = r.layout_id, tag_visibility_matrix_group_id = r.tag_visibility_matrix_group_id, allow_multi_period = r.allow_multi_period
	 WHERE delegation_sid = out_new_delegation_sid;

	DELETE FROM delegation_user
	 WHERE delegation_sid = out_new_delegation_sid;

	-- insert copied users
	FOR u IN (
		SELECT delegation_sid, user_sid, deleg_permission_set
		  FROM delegation_user
		 WHERE delegation_sid = r.delegation_sid
		   AND inherited_from_sid = r.delegation_sid
		   AND user_sid NOT IN (
				SELECT user_giving_cover_sid FROM delegation_user_cover WHERE delegation_sid = r.delegation_sid -- don't copy users who are just here providing cover - these will get slotted in by the user cover scheduled task later
		   )
	)
	LOOP
		UNSEC_AddUser(in_act_id, out_new_delegation_sid, u.user_sid, u.deleg_permission_set);
	END LOOP;

	-- insert copied roles
	FOR u IN (
		SELECT delegation_sid, role_sid, deleg_permission_set
		  FROM delegation_role
		 WHERE delegation_sid = r.delegation_sid
		   AND inherited_from_sid = r.delegation_sid
	)
	LOOP
		UNSEC_AddRole(in_act_id, out_new_delegation_sid, u.role_sid, u.deleg_permission_set);
	END LOOP;

	-- insert copied descriptions
	INSERT INTO delegation_description (delegation_sid, lang, description, last_changed_dtm)
		SELECT out_new_delegation_sid, lang, NVL(in_new_name, description), SYSDATE
		  FROM delegation_description
		 WHERE delegation_sid = r.delegation_sid; 

	-- check overlap...
	--

	-- insert indicators
	INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na)
		SELECT out_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na
		  FROM delegation_ind
		 WHERE delegation_sid = r.delegation_sid;

	-- Copy over User Perf Accuracy info (if any).
	INSERT INTO deleg_meta_role_ind_selection(delegation_sid, ind_sid, lang, description)
		SELECT out_new_delegation_sid, ind_sid, lang, description
		  FROM deleg_meta_role_ind_selection
		 WHERE delegation_sid = r.delegation_sid;

	INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT out_new_delegation_sid, ind_sid, lang, description
		  FROM delegation_ind_description
		 WHERE delegation_sid = r.delegation_sid;

	IF in_parent_sid IS NULL THEN
		-- can only do this ones inds are inserted.
		-- we need to copy these bits over as we're at the top (in_parent_sid is null)
		INTERNAL_CopyRootDelegBits(delegation_pkg.GetRootDelegationSid(in_copy_delegation_sid), out_new_delegation_sid);
	END IF;

	-- insert some sheets
	FOR s IN (
		 SELECT sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm
		   FROM sheet
		  WHERE delegation_sid = r.delegation_sid
	)
	LOOP
		sheet_pkg.CreateSheet(in_act_id, out_new_delegation_sid, s.start_dtm, s.submission_dtm, v_require_active_regions, v_sheet_id, v_end_dtm);
		
		-- ensure submission and reminder dates are in the future so we don't spam alerts		 
		IF v_end_dtm < SYSDATE THEN
			UPDATE sheet 
			   SET submission_dtm = ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE, 12), 'YY') + EXTRACT( DAY FROM submission_dtm) - 1, EXTRACT( MONTH FROM submission_dtm) - 1),
			       reminder_dtm = ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE, 12), 'YY') + EXTRACT( DAY FROM reminder_dtm) - 1, EXTRACT( MONTH FROM reminder_dtm) - 1)
			 WHERE sheet_id = v_sheet_id;
		END IF;		
	END LOOP;

	-- add some recalc jobs
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid = out_new_delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;
END;

PROCEDURE CopyDelegation(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_name					IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    out_new_delegation_sid		OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CopyDelegation(in_act_id, in_copy_delegation_sid, NULL, in_new_name, out_new_delegation_sid);
END;

PROCEDURE CopyDelegationTemplate(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_delegation_sid		IN  security_pkg.T_SID_ID
)
AS
	v_is_template				NUMBER;
BEGIN
	-- Copy Template setting
	v_is_template := deleg_plan_pkg.IsTemplate(in_copy_delegation_sid);
	IF v_is_template = 1 THEN
	    deleg_plan_pkg.SetAsTemplate(in_new_delegation_sid, v_is_template);
	END IF;
END;

PROCEDURE CopyNonTopDelegation(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_parent_sid				IN  security_pkg.T_SID_ID,
    in_new_name					IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    out_new_delegation_sid		OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CopyDelegation(in_act_id, in_copy_delegation_sid, in_parent_sid, in_new_name, out_new_delegation_sid);
END;

PROCEDURE CopyDelegationChangePeriod(
	in_act_id						IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid			IN  security_pkg.T_SID_ID,
    in_new_name						IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    in_start_dtm					IN	delegation.start_dtm%TYPE,
    in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
    out_cur							OUT SYS_REFCURSOR
)
AS
	v_table 					T_FROM_TO_TABLE := T_FROM_TO_TABLE();
    v_new_delegation_sid		security_pkg.T_SID_ID;
    v_parent_sid		    	Integer := null;
    v_previous_level	    	Integer := null;
    v_is_root               	NUMBER(1);
    v_period_interval_id		delegation.period_interval_id%TYPE;
    v_period_set_id				delegation.period_set_id%TYPE;
    parentStack			    	Stack := Stack(null,null,null);
    v_recurrence				RECURRENCE_PATTERN;
    v_has_unmerged_scenario		BOOLEAN;
    v_locked_app				BOOLEAN;
	v_root_of_copy_deleg_sid	security_pkg.T_SID_ID;
	v_is_fully_delegated		NUMBER;
BEGIN
	v_has_unmerged_scenario := csr_data_pkg.HasUnmergedScenario;
	v_locked_app := FALSE;
	v_root_of_copy_deleg_sid := delegation_pkg.GetRootDelegationSid(in_copy_delegation_sid);

    parentStack.initialize;
    FOR r IN (
        -- select this delegation and children (working out how to rename)
        SELECT x.*,
				CASE
					WHEN in_new_name is null THEN name
					WHEN root_name != name THEN REPLACE(name, root_name , in_new_name) -- top is "water", next is "water uk", renaming to "energy", will spit out "energy uk"
					ELSE in_new_name
				END new_name
		  FROM (
			  SELECT delegation_sid, connect_by_root name root_name, name, start_dtm, end_dtm, period_set_id, period_interval_id, allocate_users_to, app_sid, note,
					 group_by, schedule_xml, section_xml, grid_xml, editing_url, reminder_offset, is_note_mandatory, is_flag_mandatory, created_by_sid, level lv,
					 master_delegation_sid, submit_confirmation_text, layout_id, submission_offset, tag_visibility_matrix_group_id, allow_multi_period
				FROM v$delegation_hierarchical
			    START WITH delegation_sid = in_copy_delegation_sid
		      CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		)x
    )
    LOOP
        IF r.lv < v_previous_level THEN
            -- we've gone up, but how far? (or on same level, so just pops one off)
            FOR i IN r.lv..v_previous_level-1
            LOOP
                parentStack.pop(v_parent_sid);
            END LOOP;
        ELSIF r.lv > v_previous_level THEN
            -- we've gone deeper np...
            parentStack.push(v_parent_sid);
            v_parent_sid := v_new_delegation_sid;
        END IF;

		-- Calendar period, fix up schedule_xml if it is not null and interval is not same as delegation being copied
		IF in_period_set_id = 1 AND r.schedule_xml IS NOT NULL THEN
			v_recurrence := RECURRENCE_PATTERN(XMLType(r.schedule_xml));
			IF in_period_interval_id <> r.period_interval_id THEN
				CASE
					WHEN in_period_interval_id = 1 THEN
						v_recurrence.SetRepeatPeriod('monthly', 1);
					WHEN in_period_interval_id = 2 THEN
						v_recurrence.SetRepeatPeriod('monthly', 3);
					WHEN in_period_interval_id = 3 THEN
						v_recurrence.SetRepeatPeriod('monthly', 6);
					WHEN in_period_interval_id = 4 THEN
						v_recurrence.SetRepeatPeriod('yearly');
						v_recurrence.SetMonth(to_char(in_start_dtm, 'mon'));
					ELSE
						RAISE_APPLICATION_ERROR(-20001, 'Unrecognised interval');
				END CASE;
			ELSE
				v_recurrence := RECURRENCE_PATTERN(XMLType(r.schedule_xml));
			END IF;
		END IF;

        -- is it the top level
        IF r.lv = 1 THEN
            -- create top level delegation as this user
			delegation_pkg.CreateTopLevelDelegation(
				in_act_id				=> in_act_id,
				in_name					=> r.new_name,
				in_date_from			=> in_start_dtm,
				in_date_to				=> in_end_dtm,
				in_period_set_id		=> in_period_set_id,
				in_period_interval_id	=> in_period_interval_id,
				in_allocate_users_to	=> r.allocate_users_to,
				in_app_sid				=> r.app_sid,
				in_note					=> r.note,
				in_group_by				=> r.group_by,
				in_schedule_xml			=> CASE WHEN v_recurrence IS NULL THEN NULL ELSE v_recurrence.getClob END,
				in_reminder_offset		=> r.reminder_offset,
				in_submission_offset	=> r.submission_offset,
				in_note_mandatory		=> r.is_note_mandatory,
				in_flag_mandatory		=> r.is_flag_mandatory,
				in_policy				=> r.submit_confirmation_text,
				in_vis_matrix_tag_group => r.tag_visibility_matrix_group_id,
				in_allow_multi_period	=> r.allow_multi_period,
				out_delegation_sid		=> v_new_delegation_sid);
				
			-- only do this for top level delegations. descriptions already added otherwise.
			INSERT INTO delegation_description (delegation_sid, lang, last_changed_dtm, description)
				SELECT v_new_delegation_sid, lang, SYSDATE,
					   CASE 
						WHEN r.name = r.new_name THEN description 
						ELSE r.new_name
					   END descrption
				  FROM delegation_description
				 WHERE delegation_sid = r.delegation_sid;
        ELSE
            -- create non top level delegation
			delegation_pkg.CreateNonTopLevelDelegation(
				in_act_id				=> in_act_id,
				in_parent_sid			=> v_parent_sid,
				in_app_sid 				=> r.app_sid,
				in_name					=> r.new_name,
				in_period_set_id		=> in_period_set_id,
				in_period_interval_id	=> in_period_interval_id,
				in_schedule_xml			=> CASE WHEN v_recurrence IS NULL THEN NULL ELSE v_recurrence.getClob END,
				in_note					=> r.note,
				out_delegation_sid		=> v_new_delegation_sid
			);

        END IF;
        -- copy stuff that create delegation doesn't create for us
        UPDATE delegation
           SET grid_xml = r.grid_xml, section_xml = r.section_xml,
			editing_url = r.editing_url,
			master_delegation_sid = NVL(r.master_delegation_sid, r.delegation_sid), -- retain master delegation sid where possible
			layout_id = r.layout_id
         WHERE delegation_sid = v_new_delegation_sid;
        -- insert users
        -- clear out our user (createTopLevelDelegation always inserts a user)

        DELETE FROM delegation_user
         WHERE delegation_sid = v_new_delegation_sid;

        -- insert copied users
        FOR u IN (
            SELECT delegation_sid, user_sid, deleg_permission_set, inherited_from_sid
              FROM delegation_user
             WHERE delegation_sid = r.delegation_sid
			   AND inherited_from_sid = r.delegation_sid
               -- don't copy users who are just here providing cover - these will get slotted 
               -- in by the user cover scheduled task later
			   AND user_sid NOT IN (
					SELECT user_giving_cover_sid
					  FROM delegation_user_cover
					 WHERE delegation_sid = r.delegation_sid
			)
        )
        LOOP
            UNSEC_AddUser(in_act_id, v_new_delegation_sid, u.user_sid, u.deleg_permission_set);
        END LOOP;
		
		DELETE FROM delegation_role
         WHERE delegation_sid = v_new_delegation_sid;
		
        -- insert copied roles
        FOR u IN (
            SELECT delegation_sid, role_sid, deleg_permission_set
              FROM delegation_role
             WHERE delegation_sid = r.delegation_sid
			   AND inherited_from_sid = r.delegation_sid
        )
        LOOP
            UNSEC_AddRole(in_act_id, v_new_delegation_sid, u.role_sid, u.deleg_permission_set);
        END LOOP;
        
		INT_UNSEC_PropogateDelegPerm(v_parent_sid, v_new_delegation_sid);
		
        -- insert indicators 
		INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na)
			SELECT v_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na
			  FROM delegation_ind
			 WHERE delegation_sid = r.delegation_sid;

		-- Copy over User Perf Accuracy info (if any).
		INSERT INTO deleg_meta_role_ind_selection(delegation_sid, ind_sid, lang, description)
			SELECT v_new_delegation_sid, ind_sid, lang, description
			  FROM deleg_meta_role_ind_selection
			 WHERE delegation_sid = r.delegation_sid;

        INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
            SELECT v_new_delegation_sid, ind_sid, lang, description
              FROM delegation_ind_description
             WHERE delegation_sid = r.delegation_sid;

        IF r.lv = 1 THEN
			-- we have to do this after we copy the indicators
			-- Only do it where r.lv = 1 (i.e. for the top)
			INTERNAL_CopyRootDelegBits(v_root_of_copy_deleg_sid, v_new_delegation_sid);
        END IF;

        -- insert regions
        INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
            SELECT v_new_delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na
              FROM delegation_region
             WHERE delegation_sid = r.delegation_sid;

        INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
            SELECT v_new_delegation_sid, region_sid, lang, description
              FROM delegation_region_description
             WHERE delegation_sid = r.delegation_sid;

		IF v_parent_sid IS NOT NULL THEN
			-- is parent fully delegated?
			v_is_fully_delegated := delegation_pkg.IsFullyDelegated(v_parent_sid);
			UPDATE delegation
			   SET fully_delegated = v_is_fully_delegated
			 WHERE delegation_sid = v_parent_sid;
		END IF;

		-- add calc jobs
		IF v_has_unmerged_scenario THEN
			IF NOT v_locked_app THEN
				csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
				v_locked_app := TRUE;
			END IF;
			MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
			USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
			  		 FROM delegation_ind di, delegation d
			  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
			  		  AND di.delegation_sid = v_new_delegation_sid
					GROUP BY di.ind_sid) d
			   ON (svcl.ind_sid = d.ind_sid)
			 WHEN MATCHED THEN
				UPDATE
				   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
					   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
			 WHEN NOT MATCHED THEN
				INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
				VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
		END IF;

        v_previous_level := r.lv;
        -- keep track of delegations we've copied (from/ to)
		v_table.extend;
		v_table ( v_table.COUNT ) := T_FROM_TO_ROW (r.delegation_sid, v_new_delegation_sid);
    END LOOP;
	-- return a cursor showing what we copied
    OPEN out_cur FOR
		SELECT from_sid, to_sid
		  FROM TABLE(v_table);
END;

PROCEDURE SplitDelegation(
    in_act_id			    IN  security_pkg.T_ACT_ID,
    in_root_delegation_sid  IN  security_pkg.T_SID_ID,
    in_new_start_dtm        IN  delegation.start_dtm%TYPE,
    out_new_root_sid        OUT security_pkg.T_SID_ID
)
AS
    v_new_delegation_sid	security_pkg.T_SID_ID;
    v_parent_sid		    Integer := null;
    v_previous_level	    Integer := null;
    v_is_root               NUMBER(1);
    parentStack			    Stack := Stack(null,null,null);
    v_has_unmerged_scenario	BOOLEAN;
    v_locked_app			BOOLEAN;
BEGIN
	v_has_unmerged_scenario := csr_data_pkg.HasUnmergedScenario;
	v_locked_app := FALSE;

    SELECT COUNT(*)
      INTO v_is_root
      FROM delegation
     WHERE app_sid = parent_sid
       AND delegation_sid = in_root_delegation_sid;
    IF v_is_root = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'You can only call SplitDelegation on top level delegations');
    END IF;
    parentStack.initialize;
    FOR r IN (
        -- select this delegation and children
        SELECT delegation_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
        	   allocate_users_to, app_sid, note, group_by, schedule_xml, grid_xml, editing_url,
        	   reminder_offset, is_note_mandatory, is_flag_mandatory, created_by_sid, level lv,
               master_delegation_sid, submit_confirmation_text, submission_offset, tag_visibility_matrix_group_id, allow_multi_period
          FROM v$delegation_hierarchical
          START WITH delegation_sid = in_root_delegation_sid
        CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
    )
    LOOP
        IF r.lv < v_previous_level THEN
            -- we've gone up, but how far? (or on same level, so just pops one off)
            FOR i IN r.lv..v_previous_level-1
            LOOP
                parentStack.pop(v_parent_sid);
            END LOOP;
        ELSIF r.lv > v_previous_level THEN
            -- we've gone deeper np...
            parentStack.push(v_parent_sid);
            v_parent_sid := v_new_delegation_sid;
        END IF;
        -- is it the top level
        IF r.lv = 1 THEN
            -- create top level delegation as group approver
            delegation_pkg.CreateTopLevelDelegation(
				in_act_id				=> in_act_id,
				in_name					=> r.name,
				in_date_from			=> in_new_start_dtm,
				in_date_to				=> r.end_dtm,
				in_period_set_id		=> r.period_set_id,
				in_period_interval_id	=> r.period_interval_id,
				in_allocate_users_to	=> r.allocate_users_to,
				in_app_sid				=> r.app_sid,
				in_note					=> r.note,
				in_group_by				=> r.group_by,
				in_schedule_xml			=> r.schedule_xml,
				in_reminder_offset		=> r.reminder_offset,
				in_submission_offset	=> r.submission_offset,
				in_note_mandatory		=> r.is_note_mandatory,
				in_flag_mandatory		=> r.is_flag_mandatory,
				in_policy				=> r.submit_confirmation_text,
				in_vis_matrix_tag_group => r.tag_visibility_matrix_group_id,
				in_allow_multi_period	=> r.allow_multi_period,
				out_delegation_sid		=> v_new_delegation_sid
			);
            -- DBMS_OUTPUT.PUT_LINE('Copied top level delegation from '||r.delegation_sid||' as '||v_new_delegation_sid);
            out_new_root_sid := v_new_delegation_sid;
        ELSE
            -- create non top level delegation
            delegation_pkg.CreateNonTopLevelDelegation(
				in_act_id				=> in_act_id,
				in_parent_sid			=> v_parent_sid,
				in_app_sid 				=> r.app_sid,
				in_name					=> r.name,
				in_period_set_id		=> r.period_set_id,
				in_period_interval_id	=> r.period_interval_id,
				in_schedule_xml			=> r.schedule_xml,
				in_note					=> r.note,
				out_delegation_sid		=> v_new_delegation_sid
			);
            -- DBMS_OUTPUT.PUT_LINE('Copied delegation from '||r.delegation_sid||' as '||v_new_delegation_sid||' (level '||r.lv||' under '||v_parent_sid);
        END IF;
        -- copy stuff that create delegation doesn't create for us
        UPDATE delegation
           SET grid_xml = r.grid_xml, editing_url = r.editing_url,
			   master_delegation_sid = r.master_delegation_sid -- retain the same master as before
         WHERE delegation_sid = v_new_delegation_sid;
        -- insert users
        -- clear out our user (create TopLevelDelegation)
        DELETE FROM DELEGATION_USER
         WHERE delegation_sid = v_new_delegation_sid;

        -- insert copied users
        FOR u IN (
            SELECT delegation_sid, user_sid, deleg_permission_set
              FROM delegation_user
             WHERE delegation_sid = r.delegation_sid
			   AND inherited_from_sid = r.delegation_sid
        )
        LOOP
			UNSEC_AddUser(in_act_id, v_new_delegation_sid, u.user_sid, u.deleg_permission_set);
        END LOOP;
		
		DELETE FROM delegation_role
         WHERE delegation_sid = v_new_delegation_sid;
		
        -- insert copied roles
        FOR u IN (
            SELECT delegation_sid, role_sid, deleg_permission_set
              FROM delegation_role
             WHERE delegation_sid = r.delegation_sid
			   AND inherited_from_sid = r.delegation_sid
        )
        LOOP
            UNSEC_AddRole(in_act_id, v_new_delegation_sid, u.role_sid, u.deleg_permission_set);
        END LOOP;
		
		INT_UNSEC_PropogateDelegPerm(v_parent_sid, v_new_delegation_sid);
		
        -- insert indicators
        INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_Key, visibility, css_class, var_expl_group_id, allowed_na)
            SELECT v_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na
              FROM delegation_ind
             WHERE delegation_sid = r.delegation_sid;

        INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
            SELECT v_new_delegation_sid, ind_sid, lang, description
              FROM delegation_ind_description
             WHERE delegation_sid = r.delegation_sid;

		-- Must be done after inserting indicators for FK constraints
		-- only do where r.lv = 1 as we're the top
		IF r.lv = 1 THEN
			INTERNAL_CopyRootDelegBits(in_root_delegation_sid, v_new_delegation_sid);
		END IF;

        -- insert regions
        INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
            SELECT v_new_delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na
              FROM delegation_region
             WHERE delegation_sid = r.delegation_sid;

        INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
            SELECT v_new_delegation_sid, region_sid, lang, description
              FROM delegation_region_description
             WHERE delegation_sid = r.delegation_sid;

        v_previous_level := r.lv;

        -- close off old deleg
        UPDATE delegation
           SET end_dtm = in_new_start_dtm
         WHERE delegation_sid = r.delegation_sid;

        -- move over any existing sheets
        UPDATE sheet
           SET delegation_sid = v_new_delegation_sid
         WHERE delegation_sid = r.delegation_sid
           AND Start_dtm >= in_new_start_dtm;

		IF v_has_unmerged_scenario THEN
			IF NOT v_locked_app THEN
				csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
				v_locked_app := TRUE;
			END IF;
			MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
			USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
			  		 FROM delegation_ind di, delegation d
			  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
			  		  AND di.delegation_sid IN (r.delegation_sid, v_new_delegation_sid)
					GROUP BY di.ind_sid) d
			   ON (svcl.ind_sid = d.ind_sid)
			 WHEN MATCHED THEN
				UPDATE
				   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
					   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
			 WHEN NOT MATCHED THEN
				INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
				VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
		END IF;
    END LOOP;
END;

PROCEDURE InsertBefore(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_user_sid_list		IN	VARCHAR2,
	out_new_delegation_sid	OUT	security_pkg.T_SID_ID
)
AS
    CURSOR cd(v_delegation_sid security_pkg.T_SID_ID) IS
    	SELECT delegation_sid, parent_sid, name, note, period_set_id, period_interval_id,
    		   group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset, app_sid,
    		   is_note_mandatory, is_flag_mandatory, section_xml, editing_url, fully_delegated,
    		   schedule_xml, grid_xml, master_delegation_sid, submission_offset, tag_visibility_matrix_group_id, allow_multi_period
		  FROM delegation
		 WHERE delegation_sid = v_delegation_sid;
	r_child						cd%ROWTYPE;
    v_new_delegation_sid		security_pkg.T_SID_ID;
    v_users						VARCHAR2(255);
    v_sheet_id					sheet.sheet_id%TYPE;
    v_user_sid					security_pkg.T_SID_ID;
    v_real_parent_sid			security_pkg.T_SID_ID;
	v_is_fully_delegated    	delegation.fully_delegated%TYPE;
BEGIN
    user_pkg.GetSid(in_act_id, v_user_sid);
    -- get delegation details
    OPEN cd(in_delegation_sid);
    FETCH cd INTO r_child;
    CLOSE cd;
    --v_users := delegation_pkg.ConcatDelegationUserSids(in_delegation_sid);
    IF r_child.parent_sid = r_child.app_sid THEN
    	--DBMS_OUTPUT.PUT_LINE('inserting at top');
    	-- inserting at top...
        delegation_pkg.CreateTopLevelDelegation(
			in_act_id				=> in_act_id,
			in_name					=> r_child.name,
			in_date_from			=> r_child.start_dtm,
			in_date_to				=> r_child.end_dtm,
			in_period_set_id		=> r_child.period_set_id,
			in_period_interval_id	=> r_child.period_interval_id,
			in_allocate_users_to	=> r_child.allocate_users_to,
			in_app_sid				=> r_child.app_sid,
			in_note					=> r_child.note,
			in_group_by				=> r_child.group_by,
			in_schedule_xml			=> r_child.schedule_xml,
			in_reminder_offset		=> r_child.reminder_offset,
			in_submission_offset	=> r_child.submission_offset,
			in_note_mandatory		=> r_child.is_note_mandatory,
			in_flag_mandatory		=> r_child.is_flag_mandatory,
			in_policy				=> '', -- TODO: presumably not correct?
			in_vis_matrix_tag_group => r_child.tag_visibility_matrix_group_id,
			in_allow_multi_period	=> r_child.allow_multi_period,
			out_delegation_sid		=> v_new_delegation_sid
		);

        -- allocate users
		delegation_pkg.SetUsers(in_act_id, v_new_delegation_sid, in_user_sid_list);
		-- set section xml
		UPDATE delegation
		   SET section_xml = r_child.section_xml,
			grid_xml = r_child.grid_xml,
			editing_url = r_child.editing_url,
			master_delegation_sid = r_child.master_delegation_sid
		 WHERE delegation_sid = v_new_delegation_Sid;
	ELSE
    	--DBMS_OUTPUT.PUT_LINE('inserting in between '||r_child.parent_sid||' and '||r_child.delegation_sid);
	    -- insert before this delegation, so find out a bit about the parent
        delegation_pkg.CreateNonTopLevelDelegation(
			in_act_id				=> in_act_id,
			in_parent_sid			=> r_child.parent_sid,
			in_app_sid 				=> r_child.app_sid,
			in_name					=> r_child.name,
			in_user_sid_list		=> in_user_sid_list,
			in_period_set_id		=> r_child.period_set_id,
			in_period_interval_id	=> r_child.period_interval_id,
			in_schedule_xml			=> r_child.schedule_xml,
			in_note					=> r_child.note,
			out_delegation_sid		=> v_new_delegation_sid
		);
    	--DBMS_OUTPUT.PUT_LINE('created '||v_new_delegation_sid||' below '||r_child.parent_sid);
    	--DBMS_OUTPUT.PUT_LINE('moved '||r_child.delegation_sid||' below '||v_new_delegation_sid);
    END IF;
	-- move this one underneath (updates the parent_sid)
	securableobject_pkg.MoveSO(in_act_id, r_child.delegation_sid, v_new_delegation_sid);
	INT_UNSEC_AddDelegatorPerm(v_new_delegation_sid, r_child.delegation_sid);
	INT_UNSEC_PropogateDelegPerm(v_new_delegation_sid, r_child.delegation_sid);
	
	-- now add inds and regions
	INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
		SELECT v_new_delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na
		  FROM delegation_region
		 WHERE delegation_sid = r_child.delegation_sid;

	INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
		SELECT v_new_delegation_sid, region_sid, lang, description
		  FROM delegation_region_description
		 WHERE delegation_sid = r_child.delegation_sid;

	-- regions are special if things are split - i.e. this new delegation is the split one,
	-- so make any children who point to this
	UPDATE delegation_region
	   SET aggregate_to_region_sid = region_sid
	 WHERE delegation_sid = r_child.delegation_sid;

	INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na)
		SELECT v_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na
		  FROM delegation_ind
		 WHERE delegation_sid = r_child.delegation_sid;

	INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT v_new_delegation_sid, ind_sid, lang, description
		  FROM delegation_ind_description
		 WHERE delegation_sid = r_child.delegation_sid;

	IF r_child.parent_sid = r_child.app_sid THEN
		-- we have to do this after we've copied the ind_sids over
		-- switch over conditional stuff to point to us instead as we're the new root
		INSERT INTO delegation_ind_cond (delegation_ind_cond_id, delegation_sid, ind_sid, expr)
		SELECT delegation_ind_cond_id, v_new_delegation_sid, ind_sid, expr
		  FROM delegation_ind_cond
		 WHERE delegation_sid = in_delegation_sid;
		 
		INSERT INTO delegation_ind_cond_action (delegation_ind_cond_id, delegation_sid, ind_sid, action, tag)
		SELECT delegation_ind_cond_id, v_new_delegation_sid, ind_sid, action, tag
		  FROM delegation_ind_cond_action
		 WHERE delegation_sid = in_delegation_sid;

		DELETE FROM delegation_ind_cond_action
		 WHERE delegation_sid = in_delegation_sid;

		DELETE FROM delegation_ind_cond
		 WHERE delegation_sid = in_delegation_sid;

		INSERT INTO delegation_ind_tag_list (delegation_sid, tag)
		SELECT v_new_delegation_sid, tag
		  FROM delegation_ind_tag_list
		 WHERE delegation_sid = in_delegation_sid;

		INSERT INTO delegation_ind_tag (delegation_sid, tag, ind_sid)
		SELECT v_new_delegation_sid, tag, ind_sid
		  FROM delegation_ind_tag
		 WHERE delegation_sid = in_delegation_sid;

		DELETE FROM delegation_ind_tag
		 WHERE delegation_sid = in_delegation_sid;

		DELETE FROM delegation_ind_tag_list
		 WHERE delegation_sid = in_delegation_sid;

		FOR r IN (
		  SELECT deleg_ind_group_id, title, start_collapsed, deleg_ind_group_id_seq.nextval nextid
			FROM deleg_ind_group 
		   WHERE delegation_sid = in_delegation_sid
		)
		LOOP
			INSERT INTO deleg_ind_group (deleg_ind_group_id, delegation_sid, title, start_collapsed)
				VALUES (r.nextid, v_new_delegation_sid, r.title, r.start_collapsed);
			
			UPDATE deleg_ind_group_member
			   SET deleg_ind_group_id = r.nextid, delegation_sid = v_new_delegation_Sid
			 WHERE deleg_ind_group_id = r.deleg_ind_group_id
			   AND delegation_sid = in_delegation_sid;
			
			DELETE FROM deleg_ind_group
			 WHERE deleg_ind_group_id = r.deleg_ind_group_id
			   AND delegation_sid = in_delegation_sid;
		END LOOP;
		
		UPDATE form_expr
		   SET delegation_sid = v_new_delegation_Sid
		 WHERE delegation_sid = in_delegation_sid;

		UPDATE deleg_ind_form_expr
		   SET delegation_sid = v_new_delegation_Sid
		 WHERE delegation_sid = in_delegation_sid;
	ELSE
		INT_UNSEC_PropogateDelegPerm(r_child.parent_sid, v_new_delegation_sid);
	END IF;

    -- propagate permissions down from parent
    v_real_parent_sid := r_child.parent_sid;
	IF v_real_parent_sid = r_child.app_sid THEN
		-- ...unless it's the app_sid, so find the delegations node instead
		v_real_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, r_child.app_sid, 'delegations');
	END IF;
	acl_pkg.PropogateACEs(in_act_id, v_real_parent_sid);

    -- create sheets (take copies of what's there)
    FOR r IN (
		SELECT sheet_id_seq.NEXTVAL, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible, is_read_only
		  FROM sheet
		 WHERE delegation_sid = r_child.delegation_sid
    )
    LOOP
	    INSERT INTO sheet (sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible, is_read_only)
          VALUES (sheet_id_seq.NEXTVAL, v_new_delegation_sid, r.start_dtm, r.end_dtm, r.submission_dtm, r.reminder_dtm, r.is_visible, r.is_read_only)
          RETURNING sheet_id INTO v_sheet_id;
		-- add some history
	   	sheet_pkg.CreateHistory(v_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_new_delegation_sid, 'Created', 1);
    	--DBMS_OUTPUT.PUT_LINE('created sheet '||v_sheet_id||' for '||val_pkg.FormatPeriod(r.start_dtm, r.end_dtm, NULL));
	END LOOP;

	-- we need to work out the delegation status of the new deleg
	v_is_fully_delegated := delegation_pkg.isFullyDelegated(v_new_delegation_sid);

	UPDATE delegation
	   SET fully_delegated = v_is_fully_delegated
	 WHERE delegation_sid = v_new_delegation_sid;

	-- add some recalc jobs
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, r_child.start_dtm start_dtm, r_child.end_dtm end_dtm
		  		 FROM delegation_ind di
		  		WHERE di.delegation_sid = r_child.delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	out_new_delegation_sid := v_new_delegation_sid;
END;

-- InsertAfter parent is different from InsertBefore child in cases where
-- 	*The child is being filled in for subsidiaries and the parent is not
--	*The parent is not fully delegated.
PROCEDURE InsertAfter(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_new_delegation_sid	OUT	security_pkg.T_SID_ID
)
AS
    CURSOR cd(v_delegation_sid security_pkg.T_SID_ID) IS
    	SELECT delegation_sid, parent_sid, name, note, period_set_id, period_interval_id, group_by,
    		   allocate_users_to, start_dtm, end_dtm, reminder_offset, app_sid, is_note_mandatory,
    		   is_flag_mandatory, section_xml, editing_url, fully_delegated, schedule_xml, grid_xml
		  FROM delegation
		 WHERE delegation_sid = v_delegation_sid;
	r_parent					cd%ROWTYPE;
    v_new_delegation_sid		security_pkg.T_SID_ID;
    v_users						VARCHAR2(255);
    v_sheet_id					sheet.sheet_id%TYPE;
    v_user_sid					security_pkg.T_SID_ID;
	v_is_fully_delegated    	delegation.fully_delegated%TYPE;
BEGIN
    user_pkg.GetSid(in_act_id, v_user_sid);
    -- get delegation details
    OPEN cd(in_delegation_sid);
    FETCH cd INTO r_parent;
    CLOSE cd;
    v_users := delegation_pkg.ConcatDelegationUserSids(in_delegation_sid);

    -- Never need to insert a top level deleg when inserting after

    -- insert after parent delegation
	delegation_pkg.CreateNonTopLevelDelegation(
		in_act_id				=> in_act_id,
		in_parent_sid			=> r_parent.delegation_sid,
		in_app_sid 				=> r_parent.app_sid,
		in_name					=> r_parent.name,
		in_user_sid_list		=> v_users,
		in_period_set_id		=> r_parent.period_set_id,
		in_period_interval_id	=> r_parent.period_interval_id,
		in_schedule_xml			=> r_parent.schedule_xml,
		in_note					=> r_parent.note,
		out_delegation_sid		=> v_new_delegation_sid
	);
	-- Get the child delegations for the parent as we need to move them (not new one of course)
	FOR rc IN (
		SELECT delegation_sid FROM delegation WHERE parent_sid = r_parent.delegation_sid
	)
	LOOP
		IF rc.delegation_sid != v_new_delegation_sid THEN
			securableobject_pkg.MoveSO(in_act_id, rc.delegation_sid, v_new_delegation_sid);
		END IF;
	END LOOP;

	acl_pkg.PropogateACEs(in_act_id, v_new_delegation_sid);
	
	INT_UNSEC_PropogateDelegPerm(r_parent.delegation_sid, v_new_delegation_sid);
	
	-- now add inds and regions
	INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
		SELECT v_new_delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na
		  FROM delegation_region
		 WHERE delegation_sid = r_parent.delegation_sid;

	INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
		SELECT v_new_delegation_sid, region_sid, lang, description
		  FROM delegation_region_description
		 WHERE delegation_sid = r_parent.delegation_sid;

	INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na)
		SELECT v_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na
		  FROM delegation_ind
		 WHERE delegation_sid = r_parent.delegation_sid;

	INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT v_new_delegation_sid, ind_sid, lang, description
		  FROM delegation_ind_description
		 WHERE delegation_sid = r_parent.delegation_sid;

    -- create sheets (take copies of what's there)
    FOR rp IN (
		SELECT sheet_id_seq.NEXTVAL, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible, is_read_only
		  FROM sheet
		 WHERE delegation_sid = r_parent.delegation_sid
    )
    LOOP
	    INSERT INTO sheet (sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible, is_read_only)
          VALUES (sheet_id_seq.NEXTVAL, v_new_delegation_sid, rp.start_dtm, rp.end_dtm, rp.submission_dtm, rp.reminder_dtm, rp.is_visible, rp.is_read_only)
          RETURNING sheet_id INTO v_sheet_id;
		-- add some history
	   	sheet_pkg.CreateHistory(v_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_new_delegation_sid, 'Created', 1);
	END LOOP;

	-- we need to work out the delegation status of the new deleg
	v_is_fully_delegated := delegation_pkg.IsFullyDelegated(v_new_delegation_sid);
	UPDATE delegation
	   SET fully_delegated = v_is_fully_delegated
	 WHERE delegation_sid = v_new_delegation_sid;

	-- add some recalc jobs
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, r_parent.start_dtm start_dtm, r_parent.end_dtm end_dtm
		  		 FROM delegation_ind di
		  		WHERE di.delegation_sid = r_parent.delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	out_new_delegation_sid := v_new_delegation_sid;
END;

PROCEDURE RemoveDelegationStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_select_after_sid	OUT	security_pkg.T_SID_ID -- typically we'll need to select something other than this one in the UI
)
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_move_under_sid			security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
    v_is_fully_delegated   		delegation.fully_delegated%TYPE;
	v_terminated				NUMBER;
	v_delegation_ind_cond_id	delegation_ind_cond.delegation_ind_cond_id%TYPE;
BEGIN
	-- get parent_sid
    SELECT parent_sid, app_sid
      INTO v_parent_sid, v_app_sid
      FROM delegation
     WHERE delegation_sid = in_delegation_sid;

	-- move under parent...
	v_move_under_sid := v_parent_sid;
	-- ...unless it's the app_sid, so find the delegations node instead
	IF v_parent_sid = v_app_sid THEN
		v_move_under_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'delegations');
		-- select first child as the thing to select once this has been deleted
		BEGIN
			SELECT delegation_sid
			  INTO out_select_after_sid
			  FROM delegation
			 WHERE parent_sid = in_delegation_sid
			  AND ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				out_select_after_sid := -1; -- can't return null to c# easily
		END;
		-- fix up sheet history (otherwise the row gets deleted when we call DeleteSO - FB8414)
		FOR r IN (
			SELECT sheet_history_id, delegation_sid
			  FROM sheet_history sh
				JOIN sheet s ON sh.sheet_id = s.sheet_id
		     WHERE TO_DELEGATION_SID = in_delegation_sid
		)
		LOOP
			UPDATE SHEET_HISTORY
			   SET TO_DELEGATION_SID = r.delegation_sid
			 WHERE sheet_history_id = r.sheet_history_id;
		END LOOP;
	ELSE
		out_select_after_Sid := v_parent_sid; -- select the parent
		-- alter submissions to make them relate to parent delegation
		UPDATE SHEET_HISTORY
		   SET TO_DELEGATION_SID = v_parent_sid
		 WHERE TO_DELEGATION_SID = in_delegation_sid;
	END IF;

	-- we want the child step to adopt the status of the step we're deleting, i.e.
	-- A. o       (effectively waiting for child to be approved)
	--     \
	-- B.   o     SUBMITTED  << deleting this
	--       \
	-- C.      o  APPROVED
	--
	-- should become:
	--
	-- A. o       (effectively waiting for child to be approved)
	--     \
	-- C.   o     SUBMITTED

	-- If moved to top then ensure regions aggregate to themselves (in case it was split)
	IF v_parent_sid = v_app_sid THEN
		UPDATE delegation_region
		    SET aggregate_to_region_Sid = region_sid
		  WHERE delegation_sid IN (
			SELECT delegation_sid FROM delegation WHERE parent_sid = in_delegation_sid
		);

		-- copy over conditional stuff to point to us instead as we're the new root
		-- There could now be multiple roots though. Joy...
		FOR r IN (
			SELECT delegation_sid
			  FROM delegation
			 WHERE parent_sid = in_delegation_sid
		)
		LOOP
			-- in_delegation_sid is the root (v_parent_sid = v_app_sid)
			INTERNAL_CopyRootDelegBits(in_delegation_sid, r.delegation_sid);
		END LOOP;
	ELSE
		-- what about if a delegation has been split and it's a lower level? we need to locate
		-- the region sid, or its parent in the new parent delegation.
		FOR r IN (
			SELECT DISTINCT x.child_region_sid, dr.region_sid
			  FROM delegation d, delegation_region dr, (
				SELECT region_sid, CONNECT_BY_ROOT region_sid child_region_sid,
					   CONNECT_BY_ROOT description child_region_description
				  FROM v$region
				 START WITH region_Sid IN (
					SELECT dr.region_sid
					  FROM delegation d, delegation_region dr
					 WHERE parent_sid = in_delegation_sid
					   AND d.delegation_sid = dr.delegation_sid
				)
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid
			 )x
			 WHERE d.delegation_sid = in_delegation_sid
			   AND d.parent_sid = dr.delegation_sid
			   AND x.region_sid = dr.region_sid
		)
		LOOP
			UPDATE delegation_region
			   SET aggregate_to_region_Sid = r.region_sid
			 WHERE region_sid = r.child_region_sid
			   AND delegation_sid IN (
				SELECT delegation_sid FROM delegation WHERE parent_sid = in_delegation_sid
			);
		END LOOP;
	END IF;

	-- move child objects up a level
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 WHERE parent_sid = in_delegation_sid
	)
	LOOP
		-- what about if the objects have the same name?
		-- hmm... lower level objects have a null name anyway
		securableobject_pkg.MoveSO(in_act_id, r.delegation_sid, v_move_under_sid);
		-- the MoveSO thing literally writes the parent SO back, i.e. /delegations at top
		-- whereas for the grand delegation parent_sid hack we need it to be the app_sid
		UPDATE delegation SET parent_sid = v_parent_sid WHERE delegation_sid = r.delegation_sid;
	END LOOP;

	-- raise alerts to let people know that there's nothing more to do
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_DELEG_TERMINATED) THEN
		INSERT INTO delegation_terminated_alert (deleg_terminated_alert_id, raised_by_user_sid, notify_user_sid, delegation_sid)
			SELECT deleg_terminated_alert_id_seq.nextval, SYS_CONTEXT('SECURITY', 'SID'), user_sid, delegation_sid
			  FROM (
				SELECT du.user_sid, du.delegation_sid
				  FROM delegation_user du
				 WHERE du.delegation_sid = in_delegation_sid
				   AND du.inherited_from_sid = in_delegation_sid
				 UNION
				SELECT rrm.user_sid, dlr.delegation_sid
				  FROM delegation d
				  JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
				  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
				  JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
				 WHERE d.delegation_sid = in_delegation_sid
			);
	END IF;

	-- TODO: relink SHEET_INHERITED_VALUE

	-- delete delegation
	securableobject_pkg.DeleteSO(in_act_id, in_delegation_sid);
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid, 'Remove step (Terminated)');

	-- update fully_delegated flag for the parent
	IF v_parent_sid != v_app_sid THEN
		v_is_fully_delegated := delegation_pkg.isFullyDelegated(v_parent_sid);
	    UPDATE delegation
	       SET Fully_Delegated = v_is_fully_delegated
	     WHERE delegation_sid = v_parent_sid;
	END IF;
END;

PROCEDURE RaiseTerminatedAlerts(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID
)
AS
	v_terminated	NUMBER;
	CURSOR cur_source IS
		WITH deleg AS (
				SELECT app_sid, delegation_sid
				  FROM delegation
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
				  START WITH delegation_sid = in_delegation_sid
			)
			SELECT user_sid notify_user_sid, delegation_sid
			  FROM (
				SELECT du.user_sid, d.delegation_sid
				  FROM deleg d
				  JOIN delegation_user du ON d.delegation_sid = du.delegation_sid AND d.app_sid = du.app_sid AND du.inherited_from_sid = d.delegation_sid
				 UNION -- implicit DISTINCT
				SELECT rrm.user_sid, d.delegation_sid
				  FROM deleg d
				  JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid and d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
				  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid and d.app_sid = dr.app_sid
				  JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid and dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
			   );
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_DELEG_TERMINATED) THEN
		RETURN;
	END IF;
	-- fb20957 - Workaround for nasty oracle bug. Oracle gives incorrect error ORA-28115 when using the union in the insert, as per previous
	-- version of this procedure. Modified to use cursor as an intermediary. Probably a bit slower and definately nastier but at least it works.
	FOR r in cur_source LOOP
		INSERT INTO delegation_terminated_alert (app_sid, deleg_terminated_alert_id, notify_user_sid, raised_by_user_sid, delegation_sid)
		VALUES (in_app_sid,
			deleg_terminated_alert_id_seq.nextval,
			r.notify_user_sid,
			SYS_CONTEXT('SECURITY', 'SID'),
			r.delegation_sid);
	END LOOP;
END;

PROCEDURE INTERNAL_PrepareTerminate(
	in_delegation_sid	IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the delegation with sid '||in_delegation_sid);
	END IF;
	
	-- we don't want templates to be deleted so double check here
	-- on delegation itself
	IF deleg_plan_pkg.IsTemplate(in_delegation_sid) = 1 THEN
		RAISE csr_data_pkg.DELEGATION_USED_AS_TPL;
	END IF;
	-- on its children
	IF deleg_plan_pkg.HasChildTemplates(in_delegation_sid) = 1 THEN
		RAISE csr_data_pkg.DELEG_HAS_CHILD_TPL;
	END IF;

	-- update parent delegation (to set the fully delegated flag to 0)
	UPDATE delegation SET fully_delegated = csr_data_pkg.NOT_FULLY_DELEGATED
	 WHERE delegation_sid IN (
		SELECT delegation_sid
		  FROM delegation
		CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		  START WITH delegation_sid = in_delegation_sid
	);
	
	-- raise alerts to let people know that there's nothing more to do
	RaiseTerminatedAlerts(SYS_CONTEXT('SECURITY','APP'), in_delegation_sid);
END;	

PROCEDURE Terminate(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID
)
AS
	v_max_end_dtm	DATE;
	v_parent_sid	security_pkg.T_SID_ID;
	v_app_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP');
	v_merge_val_cnt NUMBER;
BEGIN
	INTERNAL_PrepareTerminate(in_delegation_sid);
	
	-- delete sheets of data
	-- find any sheets that end after today and zap them
	GetMergedValueCount(in_delegation_sid, v_merge_val_cnt);

	FOR r IN (
		SELECT sheet_id
		  FROM sheet_with_last_action s
		 WHERE (s.last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD) OR (v_merge_val_cnt = 0)
			   )
		   AND s.delegation_sid IN (
				SELECT delegation_sid
		 		  FROM delegation
			    CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			      START WITH delegation_sid = in_delegation_sid
		)
	)
	LOOP
		sheet_pkg.deleteSheet(r.sheet_id);
	END LOOP;

	-- now curtail delegation (either last sheet, or start_dtm of delegation)
	SELECT MAX(s.end_dtm)
	  INTO v_max_end_dtm
	  FROM delegation d, sheet s
	 WHERE s.delegation_sid = d.delegation_sid
    CONNECT BY PRIOR d.app_sid = d.app_sid AND PRIOR d.delegation_sid = parent_sid
      START WITH d.delegation_sid = in_delegation_sid;

	IF v_max_end_dtm IS NULL THEN
		securableObject_pkg.deleteSO(in_act_id, in_delegation_sid);
	ELSE
	 	UPDATE delegation
		   SET end_dtm = v_max_end_dtm
		 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
		    CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			  START WITH delegation_sid = in_delegation_sid
		);

		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid, 'Terminated');
	END IF;
END;

PROCEDURE TerminateAndDelete(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
)
AS
	v_terminated 	NUMBER;
	v_app_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP');
BEGIN
	INTERNAL_PrepareTerminate(in_delegation_sid);

	FOR r IN (
		SELECT val_id
		  FROM val
		 WHERE source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
		   AND source_id IN (
			SELECT sv.sheet_value_id
			  FROM delegation d
			  JOIN sheet s on d.delegation_sid = s.delegation_sid
			  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
			 WHERE d.delegation_sid IN (
				SELECT delegation_sid
				  FROM delegation
				 START WITH delegation_sid = in_delegation_sid
			   CONNECT BY PRIOR delegation_sid = parent_sid
			 )
		)
	)
	LOOP
		indicator_pkg.DeleteVal(security_pkg.getact, r.val_id, 'Deleting merged delegation');
	END LOOP;

	securableObject_pkg.deleteSO(security_pkg.getAct, in_delegation_sid);
END;

PROCEDURE TerminateForRegion(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	in_disposal_dtm		IN	DATE,
	in_inclusive		IN	number
)
AS
	v_other_regions		number;
	v_max_end_dtm		DATE;
	v_region_desc		REGION_DESCRIPTION.DESCRIPTION%TYPE;
	v_delegation_name 	DELEGATION.NAME%TYPE;
	v_sheet_deleted		NUMBER;
BEGIN
	-- grab region and delegation names for audit entries
	SELECT name
	  INTO v_region_desc
	  FROM region
	 WHERE region_sid = in_region_sid;

	FOR r IN ( SELECT delegation_sid
	             FROM delegation
	            START WITH delegation_sid = in_delegation_sid
	          CONNECT BY PRIOR delegation_sid = parent_sid
	) LOOP
		UPDATE sheet
		   SET is_read_only = 0
		 WHERE delegation_sid = r.delegation_sid;
	END LOOP;
	
	SELECT name
	  INTO v_delegation_name
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- inactive region may be the only region on child delegation.
	-- delete delegation from bottom to top
	FOR deleg IN (
		SELECT delegation_sid
		  FROM delegation
		CONNECT BY PRIOR delegation_sid = parent_sid
		  START WITH delegation_sid = in_delegation_sid
		  ORDER BY LEVEL DESC
	)
	LOOP
		-- set hide_after_dtm for the affected delegation_region and delete the values after the disposal_dtm
		-- even though we are deleting the sheets if there are is no other regions 
		-- hide_after_dtm will help if the delegation is extended
		-- may be we shouldn't generate the sheet for delegation which has only inactive region ???
		UPDATE delegation_region
		   SET hide_after_dtm = in_disposal_dtm,
			   hide_inclusive = in_inclusive
		 WHERE delegation_sid = deleg.delegation_sid
		   AND region_sid IN (
				SELECT r.region_sid
				  FROM region r
				 START WITH r.region_sid = in_region_sid
			   CONNECT BY PRIOR r.region_sid = r.parent_sid
		   );

		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getapp, deleg.delegation_sid, 'Hidden region "{0}" ({1})', v_region_desc, in_region_sid);
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getapp, in_region_sid, 'Region hidden in delegation "{0}" ({1}). Inclusive ({2})', v_delegation_name, deleg.delegation_sid, in_inclusive);

		-- delete merged values from disposal_dtm (inclusively/exclusively)
		FOR r IN (
			SELECT val_id
			  FROM val
			 WHERE source_type_id = csr_data_pkg.SOURCE_TYPE_DELEGATION
			   AND source_id IN (
				SELECT sv.sheet_value_id
				  FROM delegation d
				  JOIN sheet s on d.delegation_sid = s.delegation_sid
				  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
				 WHERE d.delegation_sid = deleg.delegation_sid
				   AND (
						(in_inclusive = 1 AND in_disposal_dtm < s.end_dtm) OR (in_inclusive = 0 AND s.start_dtm > in_disposal_dtm)
					 )				 
				   AND sv.region_sid IN (
						SELECT r.region_sid
						  FROM region r
						 START WITH r.region_sid = in_region_sid
					   CONNECT BY PRIOR r.region_sid = r.parent_sid
					 )
			)
		)
		LOOP
			indicator_pkg.DeleteVal(security_pkg.getact, r.val_id, 'Deleting merged delegation region');
		END LOOP;

		-- delete sheet values
		v_sheet_deleted := 0;
		FOR r IN (
			SELECT sheet_id, start_dtm, end_dtm
			  FROM sheet
			 WHERE delegation_sid = deleg.delegation_sid
			   AND ((in_inclusive = 1 AND in_disposal_dtm < end_dtm) OR (in_inclusive = 0 AND start_dtm > in_disposal_dtm))
		)
		LOOP
			-- Check if we have an active region for the sheet period, delete sheet value else delete sheet
			SELECT COUNT(*)
			  INTO v_other_regions
			  FROM delegation_region dr
			 WHERE dr.delegation_sid = deleg.delegation_sid
			   AND (dr.hide_after_dtm IS NULL OR (dr.hide_inclusive = 1 AND r.end_dtm < dr.hide_after_dtm) OR (dr.hide_inclusive = 0 AND dr.hide_after_dtm > r.start_dtm))
			   AND dr.region_sid NOT IN (
					SELECT r.region_sid
					  FROM region r
					 START WITH r.region_sid = in_region_sid
				   CONNECT BY PRIOR r.region_sid = r.parent_sid
			);

			IF v_other_regions = 0 THEN
				-- delete sheet (including sheet values)
				sheet_pkg.deleteSheet(r.sheet_id);
				v_sheet_deleted := 1;
			ELSE
				-- delete sheet values from disposal_dtm (inclusively/exclusively)
				FOR t IN (
					SELECT sv.sheet_value_id
					  FROM sheet s
					  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
					 WHERE s.sheet_id = r.sheet_id
					   AND sv.region_sid IN (
							SELECT r.region_sid
							  FROM region r
							 START WITH r.region_sid = in_region_sid
						   CONNECT BY PRIOR r.region_sid = r.parent_sid
						 )	
				)
				LOOP
					sheet_pkg.INTERNAL_DeleteSheetValue(t.sheet_value_id);
				END LOOP;
			END IF;
		END LOOP;
		
		IF v_sheet_deleted = 1 THEN
			-- raise alerts to let people know that there's nothing more to do
			RaiseTerminatedAlerts(security_pkg.getapp, deleg.delegation_sid);
			
			-- now curtail delegation (either last sheet, or start_dtm of delegation)
			SELECT MAX(s.end_dtm)
			  INTO v_max_end_dtm
			  FROM sheet s
			 WHERE s.delegation_sid = deleg.delegation_sid;	 
			
			IF v_max_end_dtm IS NULL THEN
				securableObject_pkg.deleteSO(security_pkg.getact, deleg.delegation_sid);
				csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getapp, in_region_sid, 'Deleted delegation "{0}" ({1}). Inclusive "{2}"', v_delegation_name, deleg.delegation_sid, in_inclusive);
			ELSE
				UPDATE delegation
				   SET end_dtm = v_max_end_dtm
				 WHERE delegation_sid = deleg.delegation_sid;
						
				-- <audit>
				csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getapp, deleg.delegation_sid, 'Terminated');			 
				csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getapp, in_region_sid, 'Terminated delegation "{0}" ({1}). Inclusive "{2}"', v_delegation_name, deleg.delegation_sid, in_inclusive);
			END IF;
		END IF;
	END LOOP;
END;

FUNCTION SplitStringToSids(
	in_string						IN VARCHAR2,
	in_delimiter					IN VARCHAR2 DEFAULT ','
) RETURN security_pkg.T_SID_IDS DETERMINISTIC
AS
	v_table		security_pkg.T_SID_IDS;
	v_start 	NUMBER :=1;
	v_pos	 	NUMBER :=0;
BEGIN
	-- determine first chunk of string
	v_pos := INSTR(in_string, in_delimiter, v_start);
	IF in_string IS NOT NULL THEN
		-- while there are chunks left, loop
		WHILE v_pos != 0 LOOP
			-- create array
			v_table(v_table.COUNT + 1) := TO_NUMBER(SUBSTR(in_string, v_start, v_pos - v_start));
			v_start := v_pos + LENGTH(in_delimiter);
			v_pos := INSTR(in_string, in_delimiter, v_start);
		END LOOP;
		-- add in last item
		v_table(v_table.COUNT + 1) := TO_NUMBER(SUBSTR(in_string, v_start));
	END IF;
	RETURN v_table;
END;

-- LEGACY -- 4 users left - use ExFindOverlaps
PROCEDURE FindOverlaps(
	in_act_id		 				IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DELEGATION.start_dtm%TYPE,
	in_end_dtm						IN	DELEGATION.end_dtm%TYPE,
	in_indicators_list				IN	VARCHAR2,
	in_regions_list					IN	VARCHAR2,
	out_cur							OUT	T_OVERLAP_DELEG_CUR
)
AS
	v_indicators_list				security_pkg.T_SID_IDS;
	v_regions_list					security_pkg.T_SID_IDS;
	v_deleg_inds_cur				T_OVERLAP_DELEG_INDS_CUR;
	v_deleg_regions_cur				T_OVERLAP_DELEG_REGIONS_CUR;
BEGIN
	IF in_indicators_list IS NOT NULL THEN
		v_indicators_list := SplitStringToSids(in_indicators_list, ',');
	END IF;
	IF in_regions_list IS NOT NULL THEN
		v_regions_list := SplitStringToSids(in_regions_list, ',');
	END IF;
	ExFindOverlaps(in_act_id, in_delegation_sid,
		1, -- ignore self
		in_parent_sid, in_start_dtm, in_end_dtm,
		v_indicators_list, v_regions_list, out_cur,
		v_deleg_inds_cur, v_deleg_regions_cur);
END;

-- we pass the parent_sid. Seems odd, but I think it's because the big thing to validate is
-- creating new top level delegs (i.e. you can't add regions + indicators + change time
-- periods to lower level delegs).
--
-- If you change the number or types of columns returned in the out_deleg_inds_cur cursor,
-- you will also need to update the synchChildWithParent procedure which calls this.
PROCEDURE ExFindOverlaps(
	in_act_id		 				IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ignore_Self					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	delegation.start_dtm%TYPE,
	in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_indicators_list				IN	security_pkg.T_SID_IDS,
	in_regions_list					IN	security_pkg.T_SID_IDS,
	out_deleg_cur					OUT	T_OVERLAP_DELEG_CUR,
	out_deleg_inds_cur				OUT	T_OVERLAP_DELEG_INDS_CUR,
	out_deleg_regions_cur			OUT	T_OVERLAP_DELEG_REGIONS_CUR
)
AS
	v_indicators_list				security_pkg.T_SID_IDS := in_indicators_list;
	v_regions_list					security_pkg.T_SID_IDS := in_regions_list;
	v_delegation_sid				security_pkg.T_SID_ID := -1;
	v_regions_table					security.T_SID_TABLE;
	v_indicators_table				security.T_SID_TABLE;
	v_delegations_table				security.T_SID_TABLE;
	v_root_delegation_sid			security_pkg.T_SID_ID;
BEGIN
	-- ODP.NET hackery
	IF v_indicators_list.COUNT = 1 AND v_indicators_list(1) IS NULL THEN
		v_indicators_list.DELETE;
	END IF;
	IF v_regions_list.COUNT = 1 AND v_regions_list(1) IS NULL THEN
		v_regions_list.DELETE;
	END IF;

	-- default indicators if no list provided
	IF v_indicators_list.COUNT = 0 AND in_delegation_sid IS NOT NULL THEN
		SELECT ind_sid
		  BULK COLLECT INTO v_indicators_list
		  FROM delegation_ind
		 WHERE delegation_sid = in_delegation_sid;
	END IF;
	v_indicators_table := security_pkg.SidArrayToTable(v_indicators_list);

	-- default regions if no list provided
	IF v_regions_list.COUNT = 0 AND in_delegation_sid IS NOT NULL THEN
		SELECT region_sid
		  BULK COLLECT INTO v_regions_list
		  FROM delegation_region
		 WHERE delegation_sid = in_delegation_sid;
	END IF;
	v_regions_table	:= security_pkg.SidArrayToTable(v_regions_list);

	IF in_ignore_self = 1 THEN
		v_delegation_sid := in_delegation_sid;
		IF v_delegation_sid IS NOT NULL AND v_delegation_sid != -1 THEN
			v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(v_delegation_sid);
		ELSIF in_parent_sid != security.security_pkg.getApp THEN
			v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_parent_sid);
		ELSE
			v_root_delegation_sid := -1;
		END IF;
	END IF;

	-- this checks _UP_ and _DOWN_ the tree, i.e. if we choose singapore
	-- it barfs at a delegation already set up for Asia/Pacific
	SELECT delegation_sid
		BULK COLLECT INTO v_delegations_table
		FROM (
		SELECT DISTINCT d.delegation_sid
		  FROM delegation d, delegation_region dr, delegation_ind di, (
				SELECT region_sid, MIN(lvl) lvl
				  FROM (
					SELECT region_sid, level lvl
					  FROM region
						   START WITH region_sid IN (SELECT column_value FROM TABLE (v_regions_table))
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
					 UNION
					SELECT region_sid, level lvl
					  FROM region
						   START WITH region_sid IN (SELECT column_value FROM TABLE (v_regions_table))
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid
					)
				 GROUP BY region_sid
				) tnr,
			TABLE (v_indicators_table) tni, csr_user cu, ind i, region r
		 WHERE d.delegation_sid = dr.delegation_sid
		   AND d.delegation_sid = di.delegation_sid
		   AND d.end_dtm > in_start_dtm-- check for date overlap
		   AND d.start_dtm < in_end_dtm
		   AND dr.region_sid = tnr.region_sid
		   AND di.ind_sid = tni.column_value
		   AND cu.CSR_USER_SID = d.created_by_sid
		   AND i.IND_SID = di.IND_SID
		   AND r.REGION_SID = dr.REGION_SID
		   AND (
				d.parent_sid = in_parent_sid 
				OR (d.delegation_sid != v_root_delegation_sid AND d.parent_sid = d.app_sid) -- always check other root delegation.
			)
		   AND i.measure_sid IS NOT NULL -- don't complain about category overlaps
		   AND (i.aggregate != 'NONE' OR lvl = 1)-- don't complain about non aggregate overlaps
		   AND d.delegation_sid != NVL(v_delegation_sid, -1) -- exclude this delegation if passed
		   AND d.delegation_sid NOT IN (
				-- exclude templates
				SELECT delegation_sid FROM master_deleg
		   )
		)
	;

	OPEN out_deleg_cur FOR
		SELECT d.delegation_sid, d.parent_sid, d.name, d.description, d.allocate_users_to, d.group_by,
			   d.reminder_offset, d.is_note_mandatory, d.is_flag_mandatory, d.fully_delegated,
			   d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id, d.schedule_xml,
			   d.show_aggregate, d.delegation_policy, d.submission_offset, d.tag_visibility_matrix_group_id,
			   d.allow_multi_period
		  FROM v$delegation d
		  JOIN TABLE(v_delegations_table) tds ON tds.column_value = d.delegation_sid
		 ORDER BY d.parent_sid, d.delegation_sid;

	OPEN out_deleg_inds_cur FOR
		SELECT di.delegation_sid, di.ind_sid, di.description, di.mandatory, di.pos, di.section_key,
			   di.var_expl_group_id, di.visibility, di.css_class
		  FROM v$delegation_ind di
		  JOIN TABLE(v_delegations_table) tds ON tds.column_value = di.delegation_sid
		 ORDER BY di.delegation_sid, di.pos;

	OPEN out_deleg_regions_cur FOR
		SELECT dr.delegation_sid, dr.region_sid, dr.description, dr.mandatory, dr.pos,
		 	   dr.aggregate_to_region_sid, dr.visibility
		  FROM v$delegation_region dr
		  JOIN TABLE(v_delegations_table) tds ON tds.column_value = dr.delegation_sid
		 ORDER BY dr.delegation_sid, dr.pos;
END;

PROCEDURE SetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_mandatory_list		IN	VARCHAR2,
	in_propagate_down		IN	NUMBER DEFAULT 1
)
AS
	t_indicators			T_SPLIT_NUMERIC_TABLE;
	t_mandatories			T_SPLIT_NUMERIC_TABLE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_is_fully_delegated	NUMBER;
    v_stored_level          NUMBER(10) := NULL;
    v_max_depth 			NUMBER(10);
    v_top_level_deleg_sid   security_pkg.T_SID_ID;
	v_new_ind_sids 			security.T_SID_TABLE;
	v_has_unmerged_scenario	BOOLEAN;
	v_locked_app			BOOLEAN;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	v_has_unmerged_scenario := csr_data_pkg.HasUnmergedScenario;
	v_locked_app := FALSE;

	t_indicators 	:= Utils_Pkg.SplitNumericString(in_indicators_list,',');

	-- get parent sid and app_sid
	SELECT parent_sid, app_sid
	  INTO v_parent_sid, v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- add jobs for deleted indicators
	IF v_has_unmerged_scenario THEN
		IF NOT v_locked_app THEN
			csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
			v_locked_app := TRUE;
		END IF;
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
				 FROM delegation_ind di, delegation d
				WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
				  AND di.ind_sid IN (
						-- Indicators already in the delegation
						SELECT ind_sid
						  FROM delegation_ind
						 WHERE delegation_sid = in_delegation_sid
						 MINUS
						-- New set of indicators for the delegation
						SELECT item
						  FROM TABLE(t_indicators)
						 MINUS
						-- Indicators that get added to the delegation automatically as they are aggregated to
						SELECT aggregate_to_ind_sid
						  FROM delegation_grid_aggregate_ind
						 WHERE ind_sid IN (SELECT item
						 					 FROM TABLE(t_indicators))
						 MINUS
						-- Indicators that get added to the delegation automatically as they are part of a selection group
					    SELECT ind_sid
					      FROM ind_selection_group_member
					     WHERE master_ind_sid IN (SELECT isgd.master_ind_sid
					     							FROM v$ind_selection_group_dep isgd, TABLE(t_indicators) i
					     						   WHERE isgd.ind_sid = i.item)
				  )
				  AND di.delegation_sid IN (
						SELECT delegation_sid
						  FROM delegation
						  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
							   START WITH delegation_sid = in_delegation_sid)
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- <audit>
	-- loop through deleg and child delegs and record deleting inds (can't have an ind on a child delegation not on parent)
	-- delete stuff from us and all descendants (leaves sheet_values etc for safety)
	FOR r IN (
		SELECT delegation_sid, ind_sid, description
		  FROM v$delegation_ind
		 WHERE ind_sid IN (
		 	-- Indicators already in the delegation that are not user performance indicators
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
			   AND meta_role IS NULL
			 MINUS
			-- New set of indicators for the delegation
			SELECT item
			  FROM TABLE(t_indicators)
			 MINUS
			-- Indicators that get added to the delegation automatically as they are aggregated to are kept
			SELECT aggregate_to_ind_sid
			  FROM delegation_grid_aggregate_ind
			 WHERE ind_sid IN (SELECT item
			 					 FROM TABLE(t_indicators))
			 MINUS
			-- Indicators that get added to the delegation automatically as they are part of a selection group
		    SELECT ind_sid
		      FROM ind_selection_group_member
		     WHERE master_ind_sid IN (SELECT isgd.master_ind_sid
		     					 	    FROM v$ind_selection_group_dep isgd, TABLE(t_indicators) i
		     					 	   WHERE isgd.ind_sid = i.item)
		   )
		   AND delegation_sid IN (
			   SELECT delegation_sid
				 FROM delegation
			   	      CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
				 	  START WITH delegation_sid = in_delegation_sid
		   )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
			'Removed indicator "{0}" ({1})', r.description, r.ind_sid);

		DELETE FROM delegation_ind_cond_action
		 WHERE ind_sid = r.ind_sid;

		DELETE FROM delegation_ind_cond_action
		 WHERE delegation_ind_cond_id IN (
			SELECT delegation_ind_cond_id
			  FROM delegation_ind_cond
			 WHERE delegation_sid = r.delegation_sid
			   AND ind_sid = r.ind_sid
		 );

		DELETE FROM delegation_ind_cond
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM delegation_ind_tag
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM delegation_ind_tag_list
		 WHERE (delegation_sid, tag) NOT IN (
			SELECT DISTINCT delegation_sid, tag
			  FROM delegation_ind_tag
			UNION
			SELECT DISTINCT delegation_sid, tag
			  FROM delegation_ind_cond_action
		 );

		DELETE FROM deleg_ind_form_expr
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM deleg_ind_group_member
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM delegation_ind_description
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;

		DELETE FROM delegation_ind
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_Sid;
	END LOOP;

	-- figure out the top-level delegation sid (this will have all indicators in it, and their correct positions)
    SELECT delegation_sid
      INTO v_top_level_deleg_sid
      FROM (
        SELECT delegation_sid, NAME, ROW_NUMBER() OVER (ORDER BY level DESC) rn
          FROM delegation
         	   START WITH delegation_sid = in_delegation_sid
        	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = delegation_sid
     )
     WHERE rn = 1;

	-- get mandatories
	t_mandatories	:= Utils_Pkg.SplitNumericString(in_mandatory_list, ',');

	SELECT ind_sid
	  BULK COLLECT INTO v_new_ind_sids
	  FROM (SELECT item ind_sid
	  		  FROM TABLE(t_indicators)
	  		 UNION
	  		SELECT aggregate_to_ind_sid
	  		  FROM delegation_grid_aggregate_ind
	  		 WHERE ind_sid IN (SELECT item
	  		 					 FROM TABLE(t_indicators))
			 UNION
			SELECT ind_sid						-- if an ind is a master ind in a selection group, add members of that group too
			  FROM v$ind_selection_group_dep	-- if an ind is a member of a selection group, add other members and the master ind
			 WHERE master_ind_sid IN (SELECT isgd.master_ind_sid
			 							FROM v$ind_selection_group_dep isgd, TABLE(t_indicators) i
			 						   WHERE isgd.ind_sid = i.item)
		  	 MINUS
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
	);

	-- if it's the top level, insert new rows
	-- The reason we do this separately is that we have to pull the names from the IND table
	-- which we only do at the top level (otherwise we copy the description from the top level deleg_ind)
	IF v_app_sid = v_parent_sid THEN
		-- get descriptions from ind table (in the web code we go through updating the names later -- ick)
		FOR r IN (
			SELECT i.ind_sid, i.description, tp.pos
			  FROM v$ind i, TABLE(v_new_ind_sids) t, TABLE(t_indicators) tp
			 WHERE t.column_value = i.ind_sid
			   AND t.column_value = tp.item(+)
		)
		LOOP
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
				'Added indicator "{0}" ({1})', r.description, r.ind_sid);
			INSERT INTO delegation_ind (
				delegation_sid, ind_sid, pos, visibility
			) VALUES (
				in_delegation_sid, r.ind_sid, NVL(r.pos, 0),
				-- if pos is null, then the indicator was either added only for grid aggregation or was added as a member of a selection group so don't show it
				CASE
					WHEN r.pos IS NULL AND r.ind_sid NOT IN (SELECT master_ind_sid
															   FROM ind_selection_group)
						THEN 'HIDE'
					ELSE 'SHOW'
				END
			);
		END LOOP;
	END IF;

	-- if a hidden indicator is explicitly added to the delegation then unhide it,
	-- unless it has a User Performance Score meta_role or is a member of a slection group
	UPDATE delegation_ind
	   SET visibility = 'SHOW'
	 WHERE delegation_sid = in_delegation_sid
	   AND visibility = 'HIDE'
	   AND ind_sid IN (
			SELECT item
			  FROM TABLE(t_indicators)
			 WHERE meta_role IS NULL
			   AND ind_sid NOT IN (
					SELECT ind_sid
					  FROM ind_selection_group_member
				)
		);

	-- and if an indicator is removed from the delegation, but we've kept it because
	-- it's needed for aggregation then hide it
	UPDATE delegation_ind
	   SET visibility = 'HIDE'
	 WHERE delegation_sid = in_delegation_sid
	   AND visibility = 'SHOW'
	   AND ind_sid NOT IN (SELECT item
	   						 FROM TABLE(t_indicators))
	   AND ind_sid NOT IN (SELECT master_ind_sid
							 FROM ind_selection_group);

	IF in_propagate_down = 1 THEN
		v_max_depth := 9999;
	ELSE
		v_max_depth := 1;
	END IF;

	-- Make sure any Ind selection flag and User Performance Score indicators are hidden.
	-- User Perf Indicators:
	UPDATE delegation_ind
	   SET visibility = 'HIDE'
	 WHERE delegation_sid = in_delegation_sid
	   AND visibility = 'SHOW'
	   AND meta_role IS NOT NULL;

	-- Ind selection flag indicators:
	UPDATE delegation_ind
	   SET visibility = 'HIDE'
	 WHERE delegation_sid = in_delegation_sid
	   AND visibility = 'SHOW'
	   AND meta_role IS NULL
	   AND ind_sid IN (
			SELECT ind_sid
			  FROM ind_selection_group_member
		);

	-- add jobs for new indicators
	IF v_has_unmerged_scenario THEN
		IF NOT v_locked_app THEN
			csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
			v_locked_app := TRUE;
		END IF;

		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
				 FROM delegation_ind di, delegation d, TABLE(v_new_ind_sids) t
				WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
				  AND di.ind_sid = t.column_value
				  AND di.delegation_sid IN (
						SELECT delegation_sid
						  FROM delegation
						  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
							   START WITH delegation_sid = in_delegation_sid)
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- now run down the delegation tree inserting where needed
	FOR r IN (
        SELECT DISTINCT d.delegation_sid, d.lvl, d.rn,
            COUNT(*) OVER (PARTITION BY d.PARENT_SID, dr.REGION_SID) cnt
          FROM delegation_region dr, (
            SELECT delegation_sid, parent_sid, level lvl, rownum rn
              FROM delegation
             	   START WITH delegation_sid = in_delegation_sid
            	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
          )d
        WHERE d.delegation_sid = dr.delegation_sid
          AND lvl <= v_max_depth
        ORDER BY d.rn
    )
    LOOP
        -- if lvl > stored level then loop;
        IF r.lvl <= NVL(v_stored_level,9999) THEN
            IF r.cnt > 1 THEN
                -- if cnt > 1 then store level, loop;
                v_stored_level := r.lvl;
            ELSE
                v_stored_level := NULL;
                -- we have to use a loop so we can audit the changes
                FOR rr IN (
                    -- for the indicators we're inserting, get the right descriptions and positions
                    SELECT di.ind_sid, di.description, di.pos, di.section_key, visibility, css_class
                      FROM v$delegation_ind di, TABLE(v_new_ind_sids) si
                     WHERE di.delegation_sid = v_top_level_deleg_sid
                       AND di.ind_sid = si.COLUMN_VALUE
                     MINUS -- exclude anything in there (we might have inserted this earlier)
                    SELECT di.ind_sid, di.description, di.pos, di.section_key, visibility, css_class
                      FROM v$delegation_ind di
                     WHERE delegation_sid = r.delegation_sid
                )
                LOOP
                    INSERT INTO delegation_ind
                    	(delegation_sid, ind_sid, pos, section_key, visibility, css_class)
                    VALUES
                    	(r.delegation_sid, rr.ind_sid, rr.pos, rr.section_key, rr.visibility, rr.css_class);
                    csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
                        'Added indicator "{0}" ({1})', rr.description, rr.ind_sid);
                END LOOP;

				-- clear
				UPDATE delegation_ind
				   SET mandatory = 0
				 WHERE delegation_sid = in_delegation_sid
				   AND mandatory != 0;
				-- set
				UPDATE delegation_ind
				   SET mandatory = 1
				 WHERE delegation_sid = in_delegation_sid
				   AND ind_sid IN (
						SELECT ITEM from TABLE (t_mandatories)
					)
				   AND mandatory != 1;

				v_is_fully_delegated := delegation_pkg.isFullyDelegated(in_delegation_sid);
				UPDATE delegation
				   SET fully_delegated = v_is_fully_delegated
				 WHERE delegation_sid = in_delegation_sid;
            END IF;
        END IF;
    END LOOP;

	-- Clean up any delegations left empty (the UI should have checked for this and asked about it)
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation d
         WHERE NOT EXISTS (
			SELECT NULL
			  FROM delegation_ind di
			 WHERE d.delegation_sid = di.delegation_sid
		)
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 START WITH delegation_sid = in_delegation_sid
		ORDER BY LEVEL DESC
	)
	LOOP
		SecurableObject_pkg.DeleteSO(in_act_id, r.delegation_sid);
	END LOOP;
END;

PROCEDURE SetMandatory(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_mandatory_list		IN	VARCHAR2
)
AS
	t_mandatories			T_SPLIT_TABLE;
BEGIN
	t_mandatories	:= Utils_Pkg.splitstring(in_mandatory_list, ',');

	UPDATE delegation_ind
	   SET mandatory = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND mandatory != 0; -- saves unnecessary writes

	UPDATE delegation_region
	   SET mandatory = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND mandatory != 0; -- saves unnecessary writes;

	UPDATE delegation_ind
	   SET mandatory = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid IN (SELECT item FROM TABLE (t_mandatories))
	   AND mandatory != 1;

	UPDATE delegation_region
	   SET mandatory = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND region_sid IN (SELECT item FROM TABLE (t_mandatories))
	   AND mandatory != 1;
END;

PROCEDURE CheckSetIndicationsAndRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicators_list	IN	VARCHAR2,
	in_regions_list		IN	VARCHAR2,
	out_empty_delegs	OUT	SYS_REFCURSOR,
	out_split_delegs	OUT	SYS_REFCURSOR
)
AS
	t_regions			T_SPLIT_TABLE;
	t_indicators		T_SPLIT_TABLE;
BEGIN
	t_regions := Utils_Pkg.splitString(in_regions_list, ',');
	t_indicators := Utils_Pkg.splitString(in_indicators_list, ',');

	/*
		This does:

		- get a list of regions to remove
		- per child delegations get a list of regions in the child (or a null region if no regions already)
		- left join child delegation regions to regions to remove
		- count number of regions that will be removed from the child, total child regions
		- empty delegations have euql acounts

		(and then repeat the same procedure for indicators)
	*/
	OPEN out_empty_delegs FOR
		SELECT /*+ALL_ROWS*/ d.delegation_sid, d.name
		  FROM (SELECT cdr.delegation_sid,COUNT(rr.region_sid) c2, COUNT(cdr.region_sid) c1
				  FROM (SELECT region_sid
						  FROM delegation_region
						 WHERE delegation_sid = in_delegation_sid
						MINUS
						SELECT TO_NUMBER(item)
						  FROM TABLE(t_regions)) rr, -- regions to remove
						(SELECT cd.app_sid, cd.delegation_sid, cdr.region_sid
						   FROM (SELECT app_sid, delegation_sid
						   	 	   FROM delegation
						   	 	   		START WITH parent_sid = in_delegation_sid
						   	 	   		CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
						   	 	) cd, delegation_region cdr
						  WHERE cd.app_sid = cdr.app_sid(+) AND cd.delegation_sid = cdr.delegation_sid(+)) cdr -- child regions
		  		 WHERE cdr.region_sid = rr.region_sid(+)
		     	 GROUP BY cdr.delegation_sid
		     	HAVING COUNT(cdr.region_sid) = COUNT(rr.region_sid)
			    UNION
		  		SELECT cdi.delegation_sid, COUNT(ri.ind_sid) c2, COUNT(cdi.ind_sid) c1
				  FROM (SELECT ind_sid
						  FROM delegation_ind
						 WHERE delegation_sid = in_delegation_sid
						MINUS
						SELECT TO_NUMBER(item)
						  FROM TABLE(t_indicators)) ri, -- inds to remove
						(SELECT cd.app_sid, cd.delegation_sid, cdi.ind_sid
						   FROM (SELECT app_sid, delegation_sid
						   		   FROM delegation
						   				START WITH parent_sid = in_delegation_sid
						   				CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
						   		) cd, delegation_ind cdi
						  WHERE cd.app_sid = cdi.app_sid(+) AND cd.delegation_sid = cdi.delegation_sid(+)) cdi -- child inds
		  		 WHERE cdi.ind_sid = ri.ind_sid(+)
		     	 GROUP BY cdi.delegation_sid
		        HAVING COUNT(cdi.ind_sid) = COUNT(ri.ind_sid)) ed, delegation d
		 WHERE ed.delegation_sid = d.delegation_sid;

	-- Walk a hierarchy of delegations + regions starting with child regions that aggregate to a removed parent region
	-- Any region under that hierarchy needs to be removed
	OPEN out_split_delegs FOR
        SELECT /*+ALL_ROWS*/ d.delegation_sid, d.name, d.parent_sid, dr.region_sid, dr.aggregate_to_region_sid, dr.description, LEVEL lvl
          FROM delegation d, v$delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
		   AND dr.aggregate_to_region_sid != dr.region_sid
         	   START WITH d.parent_sid = in_delegation_sid
         	   		  AND dr.aggregate_to_region_sid != region_sid
         	   		  AND dr.aggregate_to_region_sid IN
			            	(SELECT region_sid
						       FROM delegation_region
						      WHERE delegation_sid = in_delegation_sid
						     MINUS
						 	 SELECT TO_NUMBER(item)
						   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid
		 ORDER BY d.delegation_sid;
END;

PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2
)
AS
	t_regions				T_SPLIT_TABLE;
	t_mandatories			T_SPLIT_TABLE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_is_fully_delegated	NUMBER;
	v_split_regions			NUMBER;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	t_regions := Utils_Pkg.splitString(in_regions_list, ',');

	-- get parent sid
	SELECT parent_sid, app_sid
	  INTO v_parent_sid, v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- add jobs for all indicators in the delegations we are changing
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid IN (
		  		  		SELECT delegation_sid
		  		  		  FROM delegation
		  		  		   	   START WITH delegation_sid = in_delegation_sid
		  		  		   	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- <audit>
	-- loop through deleg and child delegs and record deleting regions (can't have a region on a child delegation not on parent)
	FOR r IN (
        SELECT d.delegation_sid, dr.region_sid, dr.description
          FROM delegation d, v$delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
			'Removed region "{0}" ({1})', r.description, r.region_sid);
	END LOOP;

	-- delete stuff from us and all descendants (leaves sheet_values etc for safety)
	DELETE FROM delegation_region_description
	 WHERE (delegation_sid, region_sid) IN (
        SELECT dr.delegation_sid, dr.region_sid
          FROM delegation d, delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid);

	DELETE FROM delegation_region
	 WHERE ROWID IN (
        SELECT dr.ROWID
          FROM delegation d, delegation_region dr
         WHERE d.delegation_sid = dr.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid AND dr.region_sid IN
            	(SELECT region_sid
			       FROM delegation_region
			      WHERE delegation_sid = in_delegation_sid
			     MINUS
			 	 SELECT TO_NUMBER(item)
			   	   FROM TABLE(t_regions)) -- regions to remove
       		   CONNECT BY PRIOR d.app_sid = d.app_sid
       		   		  AND PRIOR d.delegation_sid = d.parent_sid
           	   		  AND PRIOR dr.region_sid = dr.aggregate_to_region_sid
           	   		  AND PRIOR dr.delegation_sid = d.parent_sid);

	SELECT COUNT(*)
	  INTO v_split_regions
	  FROM delegation_region
	 WHERE delegation_sid = in_delegation_sid
	   AND aggregate_to_region_sid != region_sid;

	IF v_app_sid = v_parent_sid OR v_split_regions > 0 THEN
		-- <audit>
		-- record adding region to this delegation - get descriptions from region table
		FOR r IN (
		 	SELECT r.region_sid, r.description
			  FROM v$region r,
			 	   (SELECT TO_NUMBER(item) region_sid
			 	      FROM TABLE(t_regions)
					 MINUS
			 		SELECT region_sid
			 		  FROM delegation_region
			 		 WHERE delegation_sid = in_delegation_sid)t
			 WHERE t.region_sid = r.region_sid
		)
		LOOP
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
				'Added region "{0}" ({1})', r.description, r.region_sid);
		END LOOP;
	ELSE
		-- record adding region to this delegation - get descriptions from delegation_region table
		FOR r IN (
		 	SELECT dr.region_sid, dr.description
			  FROM v$delegation_region dr,
			 		(SELECT TO_NUMBER(item) region_sid
			 		   FROM TABLE(t_regions)
					 MINUS
			 		 SELECT region_sid
			 		   FROM delegation_region
			 		  WHERE delegation_sid = in_delegation_sid) t
			 WHERE t.region_sid = dr.region_sid
			   AND dr.delegation_sid = v_parent_sid
		)
		LOOP
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
				'Added region "{0}" ({1})', r.description, r.region_sid);
		END LOOP;
	END IF;

	-- what's new? (take pos + description from parent_sid)
	IF v_app_sid = v_parent_sid THEN
		-- top level
		INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
			SELECT in_delegation_sid, r.region_sid, r.pos, r.region_sid, 'SHOW'
			  FROM region r,
				 	(SELECT TO_NUMBER(item) region_sid
				 	   FROM TABLE(t_regions)
					 MINUS
				 	 SELECT region_sid
				 	   FROM delegation_region
				 	  WHERE delegation_sid = in_delegation_sid) t
					  WHERE t.region_sid = r.region_sid;
	ELSE
		-- it's slightly different if our regions are children
		IF v_split_regions > 0 THEN
			INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
			 	SELECT in_delegation_sid, r.region_sid, r.pos, r.parent_sid, 'SHOW' -- TODO: assumes that this goes to parent - be careful
				  FROM region r,
					 	(SELECT TO_NUMBER(item) region_sid
					 	   FROM TABLE(t_regions)
						 MINUS
					 	 SELECT region_sid
					 	   FROM delegation_region
					 	  WHERE delegation_sid = in_delegation_sid) t
				 WHERE t.region_sid = r.region_sid;
		ELSE
			INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility)
				SELECT in_delegation_sid, dr.region_sid, dr.pos, dr.region_sid, dr.visibility
				  FROM delegation_region dr,
					   (SELECT TO_NUMBER(item) region_sid
					      FROM TABLE(t_regions)
						MINUS
					    SELECT region_sid
					      FROM delegation_region
					     WHERE delegation_sid = in_delegation_sid)t
				 WHERE t.region_sid = dr.region_sid
				   AND dr.delegation_sid = v_parent_sid;

			INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
				SELECT in_delegation_sid, drd.region_sid, drd.lang, drd.description
				  FROM delegation_region_description drd,
					   (SELECT TO_NUMBER(item) region_sid
					      FROM TABLE(t_regions)
						MINUS
					    SELECT region_sid
					      FROM delegation_region
					     WHERE delegation_sid = in_delegation_sid) t
				 WHERE t.region_sid = drd.region_sid
				   AND drd.delegation_sid = v_parent_sid;
		END IF;
	END IF;

	t_mandatories := Utils_Pkg.splitstring(in_mandatory_list, ',');
	UPDATE delegation_region
	   SET mandatory = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND mandatory != 0;

	UPDATE delegation_region
	   SET mandatory = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND region_sid IN (SELECT item FROM TABLE (t_mandatories))
	   AND mandatory != 1;

	-- Clean up any delegations left empty (the UI should have checked for this and asked about it)
	FOR r IN (SELECT delegation_sid
			    FROM delegation d
               WHERE NOT EXISTS (
               			SELECT NULL
               			  FROM delegation_region dr
               			 WHERE d.delegation_sid = dr.delegation_sid)
					  CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
					  START WITH delegation_sid = in_delegation_sid
			   ORDER BY LEVEL DESC
	) LOOP
		SecurableObject_pkg.DeleteSO(in_act_id, r.delegation_sid);
	END LOOP;

	v_is_fully_delegated := delegation_pkg.isFullyDelegated(in_delegation_sid);
	UPDATE delegation
	   SET fully_delegated = v_is_fully_delegated
	 WHERE delegation_sid = in_delegation_sid;

	-- After a region is added to sub delegation, update parent's fully-delegated status
	IF v_app_sid != v_parent_sid THEN
		v_is_fully_delegated := delegation_pkg.isFullyDelegated(v_parent_sid);
		UPDATE delegation
		   SET fully_delegated = v_is_fully_delegated
		 WHERE delegation_sid = v_parent_sid;
	END IF;
END;

-- TODO: insert delegation_ind_conditions???
PROCEDURE SynchChildWithParent(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_child_sid				IN	security_pkg.T_SID_ID, 
	out_delegation_changed		OUT	NUMBER,
	out_has_overlaps			OUT NUMBER,
	out_overlap_reg_cur			OUT	T_OVERLAP_DELEG_REGIONS_CUR
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_start_dtm			delegation.start_dtm%TYPE;
	v_end_dtm			delegation.end_dtm%TYPE;
	v_regs				security_pkg.T_SID_IDS;
	v_inds				security_pkg.T_SID_IDS;
	v_ind_sid_table		security.T_SID_TABLE;
	v_deleg_cur			T_OVERLAP_DELEG_CUR;
	v_deleg_inds_cur	T_OVERLAP_DELEG_INDS_CUR;
	v_overlap_rec		T_OVERLAP_DELEG_INDS_REC;
	v_overlap_table		security.T_SID_TABLE := security.T_SID_TABLE();
	v_policy_text		delegation_policy.submit_confirmation_text%TYPE;
BEGIN
	out_delegation_changed:=0;

	-- can user read parent delegation?
	IF NOT CheckDelegationPermission(in_act_id, in_parent_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading parent delegation');
	END IF;
	-- can user write to child delegation?
	IF NOT CheckDelegationPermission(in_act_id, in_child_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to child delegation');
	END IF;

	SELECT parent_sid, start_dtm, end_dtm
	  INTO v_parent_sid, v_start_dtm, v_end_dtm
	  FROM delegation
	 WHERE delegation_sid = in_child_sid;

	SELECT region_sid
	  BULK COLLECT INTO v_regs
	  FROM delegation_region
	 WHERE delegation_sid = in_child_sid;

	SELECT ind_sid
	  BULK COLLECT INTO v_inds
	  FROM (
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
		 MINUS
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
	  );
	v_ind_sid_table := security_pkg.SidArrayToTable(v_inds);

	-- populate v_overlap_table with the ind_sids of the overlaps
	ExFindOverlaps(
		in_act_id					=> in_act_id,
		in_delegation_sid			=> in_child_sid,
		in_ignore_self				=> 1,
		in_parent_sid				=> v_parent_sid,
		in_start_dtm				=> v_start_dtm,
		in_end_dtm					=> v_end_dtm,
		in_indicators_list			=> v_inds,
		in_regions_list				=> v_regs,
		out_deleg_cur				=> v_deleg_cur,
		out_deleg_inds_cur			=> v_deleg_inds_cur,
		out_deleg_regions_cur		=> out_overlap_reg_cur
	);
	WHILE TRUE
	LOOP
		FETCH v_deleg_inds_cur
		 INTO v_overlap_rec;

		EXIT WHEN v_deleg_inds_cur%NOTFOUND;

		v_overlap_table.EXTEND;
		v_overlap_table(v_overlap_table.COUNT) := v_overlap_rec.ind_sid;
	END LOOP;
	CLOSE v_deleg_inds_cur;
	
	out_has_overlaps := CASE WHEN v_overlap_table.COUNT > 0 THEN 1 ELSE 0 END;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_child_sid,
		'Synchronised with parent delegation ({0})', in_parent_sid);
	
	FOR r IN (
	SELECT t.*, i.description FROM (
		SELECT * FROM (
			SELECT in_child_sid delegation_sid, column_value ind_sid, 0 mandatory, 0 pos, NULL section_key, NULL meta_role, 0 allowed_na
			  FROM TABLE(v_ind_sid_table) t
			 MINUS
			SELECT in_child_sid, column_value, 0, 0, NULL, NULL, 0
			  FROM TABLE(v_overlap_table)
			)
		) t
	  JOIN v$ind i ON i.ind_sid = t.ind_sid
	 )
	LOOP
		INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, meta_role, allowed_na)
			 VALUES (r.delegation_sid, r.ind_sid, r.mandatory, r.pos, r.section_key, r.meta_role, r.allowed_na);

		out_delegation_changed:=1;

		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), r.delegation_sid,
		'Added indicator "{0}" ({1})', r.description, r.ind_sid);
	END LOOP;
	
	-- Add User Perf Accuracy metric info (if any)
	INSERT INTO deleg_meta_role_ind_selection (delegation_sid, ind_sid, lang, description)
	SELECT in_child_sid, ind_sid, lang, description FROM deleg_meta_role_ind_selection WHERE delegation_sid = in_parent_sid
	 MINUS
	SELECT in_child_sid, ind_sid, lang, description FROM deleg_meta_role_ind_selection WHERE delegation_sid = in_child_sid;

	-- delete stuff that has been deleted from parent
	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
		 MINUS
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
	 );

	DELETE FROM delegation_ind_cond
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
		 MINUS
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
	 );

	DELETE FROM delegation_ind_tag
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
		 MINUS
		SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
	 );

	-- add some recalc jobs
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation d, delegation_ind di
		  		WHERE d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  		  AND d.delegation_sid IN (in_child_sid, in_parent_sid)
		  		  AND di.ind_sid IN (
		  		  		-- inds added to parent
						(SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
						  MINUS
						 SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid)
						-- inds deleted from parent
						  UNION
						(SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
						  MINUS
						 SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid))
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	DELETE FROM deleg_ind_form_expr
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
			 MINUS
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
		 );

	DELETE FROM deleg_ind_group_member
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
			 MINUS
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
		 );

	DELETE FROM delegation_ind_description
	 WHERE delegation_sid = in_child_sid; -- we'll add these back where needed later

	DELETE FROM deleg_meta_role_ind_selection  -- Delete User Perf deleg info
	 WHERE delegation_sid = in_child_sid
	   AND ind_sid IN (
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
			 MINUS
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
		);

	FOR r IN (
	SELECT t.*, i.description FROM (
		SELECT * FROM (
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_child_sid
			 MINUS
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_parent_sid
		)
	) t
	JOIN v$ind i ON i.ind_sid = t.ind_sid
	)
	LOOP
		DELETE FROM delegation_ind 
		 WHERE delegation_sid = in_child_sid
		   AND ind_sid = r.ind_sid;
		   
		out_delegation_changed:=1;
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_child_sid,
		'Removed indicator "{0}" ({1})', r.description, r.ind_sid);
	END LOOP;
	
	-- sync content
	UPDATE delegation_ind c
	   SET (mandatory, pos, section_key, var_expl_group_id, visibility, css_class, meta_role, allowed_na) = (
			SELECT mandatory, pos, section_key, var_expl_group_id, visibility, css_class, meta_role, allowed_na
			  FROM delegation_ind p
			 WHERE p.delegation_sid = in_parent_sid
			   AND c.ind_sid = p.ind_sid)
	  WHERE c.delegation_sid = in_child_sid;

	-- Sync User Perf Accuracy metric info
	UPDATE deleg_meta_role_ind_selection dmris
	   SET (ind_sid, lang, description) = (
			SELECT ind_sid, lang, description
			  FROM deleg_meta_role_ind_selection dmris2
			 WHERE delegation_sid = in_parent_sid
			   AND dmris.ind_sid = dmris2.ind_sid
		)
	WHERE dmris.delegation_sid = in_child_sid;

	-- copy overridden descriptions down
	INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT in_child_sid, ind_sid, lang, description
		  FROM delegation_ind_description
		 WHERE delegation_sid = in_parent_sid
		   AND ind_sid NOT IN (
			SELECT column_value FROM TABLE(v_overlap_table)
		);

	UPDATE delegation
	   SET (name, section_xml, note, group_by, is_note_mandatory, is_flag_mandatory, hide_sheet_period, tag_visibility_matrix_group_id, allow_multi_period, show_aggregate) = (
			SELECT name, section_xml, note, group_by, is_note_mandatory, is_flag_mandatory, hide_sheet_period, tag_visibility_matrix_group_id, allow_multi_period, show_aggregate
			  FROM delegation
			 WHERE delegation_sid = in_parent_sid)
	 WHERE delegation_sid = in_child_sid;

	FOR r IN (SELECT lang, description 
				FROM delegation_description 
			   WHERE delegation_sid = in_parent_sid) LOOP
		SetTranslation(
			in_delegation_sid		=> in_child_sid,
			in_lang					=> r.lang,
			in_description			=> r.description
		);
	END LOOP;
	
	SELECT MIN(submit_confirmation_text)
	  INTO v_policy_text
	  FROM delegation_policy
	 WHERE delegation_sid = in_parent_sid;
	 
	UpdatePolicy(in_child_sid, NVL(v_policy_text, ''));
	
	-- Copy conditionals
	INTERNAL_CopyRootDelegBits(in_parent_sid, in_child_sid);
END;

PROCEDURE SetUsers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_users_list		IN	VARCHAR2
)
AS
	t_users			T_SPLIT_TABLE;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	t_users 	:= Utils_Pkg.splitString(in_users_list,',');
	

	-- delete stuff from delegation_user table
	FOR r IN (
	 	SELECT csr_user_sid
	 	  FROM csr_user cu
	     WHERE csr_user_sid IN (
			SELECT user_sid
			  FROM delegation_user
			 WHERE delegation_sid = in_delegation_sid
			   AND inherited_from_sid = in_delegation_sid
			   AND (delegation_sid, user_sid ) NOT IN ( -- don't delete users present in the delegaiton user table because they are providing temp cover
					SELECT delegation_sid, user_giving_cover_sid
					  FROM delegation_user_cover
					 WHERE app_sid = security_pkg.GetApp
					   AND delegation_sid = in_delegation_sid
				)
			MINUS
			-- we do a cast as without it with one or zero rows you get 'cannot access rows from a non-nested table item' for some bizarre reason!!
			SELECT TO_NUMBER(item) FROM TABLE(CAST(t_users AS T_SPLIT_TABLE))
		 )
	)
	LOOP
		DeleteUser(in_act_id, in_delegation_sid, r.csr_user_sid);
	END LOOP;

	-- what's new? (take pos + description from parent_sid)
	FOR r IN (
		SELECT DISTINCT csr_user_sid, full_name
		  FROM csr_user
		 WHERE csr_user_sid IN (
			SELECT user_sid FROM (
				SELECT in_delegation_sid delegation_sid, TO_NUMBER(item) user_sid FROM TABLE(CAST(t_users AS T_SPLIT_TABLE))
				  MINUS
			     SELECT delegation_sid, user_sid
				   FROM delegation_user
				  WHERE delegation_sid = in_delegation_sid
				    AND inherited_from_sid = delegation_sid
				    AND (delegation_sid, user_sid ) NOT IN ( -- fully add users only present in the delegaiton user table because they are providing temp cover
						SELECT delegation_sid, user_giving_cover_sid
						  FROM delegation_user_cover
						 WHERE app_sid = security_pkg.GetApp
						   AND delegation_sid = in_delegation_sid
					)
			) u
		 )
	)
	LOOP
		UNSEC_AddUser(in_act_id, in_delegation_sid, r.csr_user_sid);
	END LOOP;
END;

PROCEDURE DeleteUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_user_sid			security_pkg.T_SID_ID
)
AS
	v_full_name 		csr_user.full_name%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	-- left like this as I don't know if this is used in a way where it relies on not being logged on as an app
	--<audit>
	SELECT app_sid
	  INTO v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	SELECT full_name
      INTO v_full_name
	  FROM csr_user cu
	 WHERE csr_user_sid = in_user_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
		'Removed delegation user "{0}" ({1})', v_full_name, in_user_sid);

	-- clear this user from the cover table
	-- and clear up the users covering them
	FOR r IN (
		SELECT DISTINCT delegation_sid, user_giving_cover_sid
		  FROM delegation_user_cover
	     WHERE delegation_sid = in_delegation_sid
	       AND user_being_covered_sid = in_user_sid
	) LOOP
		user_cover_pkg.ClearUserCoverIfLastOne(r.delegation_sid, in_user_sid, r.user_giving_cover_sid);
	END LOOP;

	DELETE FROM delegation_user
	 WHERE user_sid = in_user_sid
	   AND inherited_from_sid = in_delegation_sid;
	
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
	     START WITH delegation_sid = in_delegation_sid
	   CONNECT BY PRIOR delegation_sid = parent_sid
	) LOOP
		DELETE FROM security.acl
		 WHERE acl_id = acl_pkg.GetDACLIDForSID(r.delegation_sid)
		   AND sid_id = in_user_sid
		   AND permission_set = security_pkg.PERMISSION_LIST_CONTENTS+security_pkg.PERMISSION_ADD_CONTENTS;
	END LOOP;
END;

PROCEDURE SetRoles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_roles_list		IN	VARCHAR2
)
AS
	t_roles			T_SPLIT_TABLE;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	t_roles 	:= Utils_Pkg.splitString(in_roles_list,',');

	-- get csr root sid
	SELECT app_sid
	  INTO v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- delete stuff from delegation_role table
	FOR r IN (
	 	SELECT role_sid, name
	 	  FROM role
	     WHERE role_sid IN (
			SELECT role_sid FROM delegation_role WHERE delegation_sid = in_delegation_sid AND inherited_from_sid = in_delegation_sid
			MINUS
			-- we do a cast as without it with one or zero rows you get 'cannot access rows from a non-nested table item' for some bizarre reason!!
			SELECT TO_NUMBER(item) FROM TABLE(CAST(t_roles AS T_SPLIT_TABLE))
		 )
	)
	LOOP
		-- <audit>
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, in_delegation_sid,
			'Removed role "{0}" ({1})', r.name, r.role_sid);

		DELETE FROM delegation_role
		 WHERE role_sid = r.role_sid
		   AND inherited_from_sid = in_delegation_sid;
	END LOOP;

	-- what's new? (take pos + description from parent_sid)
	FOR r IN (
		SELECT DISTINCT role_sid, name
		  FROM role
		 WHERE role_sid IN (
			SELECT TO_NUMBER(item) role_sid FROM TABLE(CAST(t_roles AS T_SPLIT_TABLE))
			  MINUS
			 SELECT role_sid FROM delegation_role WHERE delegation_sid = in_delegation_sid AND inherited_from_sid = in_delegation_sid
		 )
	)
	LOOP
		UNSEC_AddRole(in_act_id, in_delegation_sid, r.role_sid);
	END LOOP;
END;

PROCEDURE UpdateRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_region_sid					IN	VARCHAR2,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	VARCHAR2
)
AS
	v_langs							security.T_VARCHAR2_TABLE;
	v_translations					security.T_VARCHAR2_TABLE;
BEGIN
	-- TODO: check permissions?

	-- <audit>
	FOR r IN (
		 SELECT dr.delegation_sid, dr.region_sid, dr.pos, d.app_sid
		   FROM delegation_region dr, delegation d
		  WHERE d.delegation_sid = dr.delegation_sid
			AND dr.region_sid = in_region_sid
			AND dr.delegation_sid IN
	 			(SELECT delegation_sid
			   	   FROM delegation
				  		CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
						START WITH delegation_sid = in_delegation_sid)
	)
	LOOP
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid,
			'Delegation region position', r.pos, in_pos);
	END LOOP;

	v_langs := security_pkg.Varchar2ArrayToTable(in_langs);
	v_translations := security_pkg.Varchar2ArrayToTable(in_translations);

	-- audit description changes
	FOR r IN (
		SELECT app_sid, delegation_sid
		  FROM delegation
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			   START WITH delegation_sid = in_delegation_sid
	) LOOP
		FOR s IN (
			SELECT NVL(od.lang, nd.lang) lang, od.description old_description, nd.description new_description
			  FROM -- new descriptions
			  	   (SELECT l.value lang, t.value description
		  		  	  FROM TABLE(v_langs) l, TABLE(v_translations) t
		  		 	 WHERE l.pos = t.pos
		  		 	 MINUS
		  		 	SELECT lang, description
		  		 	  FROM region_description
		  		 	 WHERE region_sid = in_region_sid) nd
			  FULL JOIN
				   -- old descriptions
				   (SELECT lang, description
				   	  FROM delegation_region_description
				   	 WHERE delegation_sid = r.delegation_sid
				   	   AND region_sid = in_region_sid) od
			    ON nd.lang = od.lang
		) LOOP
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid,
				'Delegation region description', s.old_description, s.new_description);
		END LOOP;
	END LOOP;

	UPDATE delegation_region
	   SET pos = in_pos
	 WHERE region_sid = in_region_sid
	   AND delegation_sid IN (
		SELECT delegation_sid
		  FROM delegation
	    CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
	      START WITH delegation_sid = in_delegation_sid
	 );

	DELETE FROM delegation_region_description
	 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
		    	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			  	   START WITH delegation_sid = in_delegation_sid)
	   AND region_sid = in_region_sid;

	-- hack for ODP.NET which doesn't support empty arrays
	IF NOT (in_translations.COUNT = 0 OR (in_translations.COUNT = 1 AND in_translations(1) IS NULL)) THEN
		FOR i IN 1 .. in_translations.COUNT LOOP
			INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
				SELECT t.delegation_sid, tr.region_sid, tr.lang, tr.description
				  FROM (SELECT dt.delegation_sid
				  		  FROM (SELECT app_sid, delegation_sid
							  	  FROM delegation
						    	   	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
							  	   	   START WITH delegation_sid = in_delegation_sid) dt
						  JOIN delegation_region di
						    ON dt.app_sid = di.app_sid AND dt.delegation_sid = di.delegation_sid
						 WHERE di.region_sid = in_region_sid) t, -- delegations from tree that use the region
					   (SELECT in_region_sid region_sid, in_langs(i) lang, in_translations(i) description
					      FROM dual
					     MINUS
					    SELECT in_region_sid, lang, description
					      FROM region_description
					     WHERE region_sid = in_region_sid
					       AND lang = in_langs(i)) tr;
		END LOOP;
	END IF;
END;

PROCEDURE UpdateIndicator(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid						IN	VARCHAR2,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	VARCHAR2
)
AS
	v_langs							security.T_VARCHAR2_TABLE;
	v_translations					security.T_VARCHAR2_TABLE;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	-- <audit>
	FOR r IN (
		SELECT di.delegation_sid, di.ind_sid, di.pos, d.app_sid
		  FROM delegation_ind di, delegation d
		 WHERE d.delegation_sid = di.delegation_sid
		   AND di.ind_sid = in_ind_sid
		   AND di.delegation_sid IN
		 		(SELECT delegation_sid
				   FROM delegation
					    CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
						START WITH delegation_sid = in_delegation_sid)
	)
	LOOP
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid,
			'Delegation indicator position', r.pos, in_pos);
	END LOOP;

	v_langs := security_pkg.Varchar2ArrayToTable(in_langs);
	v_translations := security_pkg.Varchar2ArrayToTable(in_translations);

	-- audit description changes
	FOR r IN (
		SELECT app_sid, delegation_sid
		  FROM delegation
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			   START WITH delegation_sid = in_delegation_sid
	) LOOP
		FOR s IN (
			SELECT NVL(od.lang, nd.lang) lang, od.description old_description, nd.description new_description
			  FROM -- new descriptions
			  	   (SELECT l.value lang, t.value description
		  		  	  FROM TABLE(v_langs) l, TABLE(v_translations) t
		  		 	 WHERE l.pos = t.pos
		  		 	 MINUS
		  		 	SELECT lang, description
		  		 	  FROM ind_description
		  		 	 WHERE ind_sid = in_ind_sid) nd
			  FULL JOIN
				   -- old descriptions
				   (SELECT lang, description
				   	  FROM delegation_ind_description
				   	 WHERE delegation_sid = r.delegation_sid
				   	   AND ind_sid = in_ind_sid) od
			    ON nd.lang = od.lang
		) LOOP
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid,
				'Delegation indicator description', s.old_description, s.new_description);
		END LOOP;
	END LOOP;

	UPDATE delegation_ind
	   SET pos = in_pos
	 WHERE ind_sid = in_ind_sid
	   AND delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
		    CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			  START WITH delegation_sid = in_delegation_sid);

	DELETE FROM delegation_ind_description
	 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
		    	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			  	   START WITH delegation_sid = in_delegation_sid)
	   AND ind_sid = in_ind_sid;

	-- hack for ODP.NET which doesn't support empty arrays
	IF NOT (in_translations.COUNT = 0 OR (in_translations.COUNT = 1 AND in_translations(1) IS NULL)) THEN
		FOR i IN 1 .. in_translations.COUNT LOOP
			INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
				SELECT t.delegation_sid, tr.ind_sid, tr.lang, tr.description
				  FROM (SELECT dt.delegation_sid
				  		  FROM (SELECT app_sid, delegation_sid
							  	  FROM delegation
						    	   	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
							  	   	   START WITH delegation_sid = in_delegation_sid) dt
						  JOIN delegation_ind di
						    ON dt.app_sid = di.app_sid AND dt.delegation_sid = di.delegation_sid
						 WHERE di.ind_sid = in_ind_sid) t, -- delegations from tree that use the indicator
					   (SELECT in_ind_sid ind_sid, in_langs(i) lang, in_translations(i) description
					      FROM dual
					     MINUS
					    SELECT in_ind_sid, lang, description
					      FROM ind_description
					     WHERE ind_sid = in_ind_sid
					       AND lang = in_langs(i)) tr;
		END LOOP;
	END IF;
END;

PROCEDURE UpdateDates(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE
)
AS
	CURSOR c IS
		SELECT start_dtm, end_dtm, app_sid
		  FROM delegation d
		 WHERE delegation_sid = in_delegation_sid;
	r c%ROWTYPE;
	v_cnt	NUMBER(10);
	v_not_found	BOOLEAN;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	-- get original details to write a log entry describing the change...
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN;
	END IF;

	-- try and delete sheets where we can (i.e. where no values set)
	FOR r IN (
		SELECT dc.root_delegation_sid, s.start_dtm, s.end_dtm
		  FROM sheet s, sheet_value sv, (
			 SELECT delegation_sid, connect_by_root delegation_sid root_delegation_sid
			   FROM delegation
			  START WITH delegation_sid = in_delegation_sid
		    CONNECT BY PRIOR app_sid = app_sid AND prior delegation_sid = parent_sid
		    )dc
		 WHERE s.delegation_sid = dc.delegation_sid
		   AND (start_dtm < in_start_dtm or end_dtm > in_end_dtm)
		   AND s.sheet_id = sv.sheet_id(+)
		 GROUP BY dc.root_delegation_sid, s.start_dtm, s.end_dtm
		HAVING count(sv.sheet_value_Id) = 0
	)
	LOOP
		FOR rr IN (
			SELECT sheet_Id
			  FROM sheet
			 WHERE delegation_sid IN (
				 SELECT delegation_sid
				   FROM delegation
				  START WITH delegation_sid = r.root_delegation_sid
			    CONNECT BY PRIOR app_sid = app_sid AND prior delegation_sid = parent_sid
			   )
 			   AND start_dtm >= r.start_dtm
			   AND end_dtm <= r.end_dtm
		)
		LOOP
			sheet_pkg.deleteSheet(rr.sheet_id);
		END LOOP;
	END LOOP;

	-- check that we can do this (i.e. if we've got sheets then complain)
	SELECT count(*) INTO v_cnt
	  FROM sheet
	 WHERE delegation_sid = in_delegation_sid -- safe just to check top level since we won't delete a top level sheet in the query above
	   AND (start_dtm < in_start_dtm OR end_dtm > in_end_dtm);
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SHEETS_EXIST, 'Updating dates will delete existing sheets');
	END IF;

	-- TODO: check for overlaps if the sheet has increased in duration
	UPDATE delegation
	   SET start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm
	 WHERE delegation_sid IN (
		SELECT delegation_sid
		  FROM delegation
		  	   START WITH delegation_sid = in_delegation_sid
	     	   CONNECT BY PRIOR app_sid = app_sid AND prior delegation_sid = parent_sid);

	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, LEAST(in_start_dtm, MIN(d.start_dtm)) start_dtm, GREATEST(in_end_dtm, MAX(d.end_dtm)) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid IN (
		  		  		SELECT delegation_sid
		  		  		  FROM delegation
		  		  		 	   START WITH delegation_sid = in_delegation_sid
		  		  		 	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- <audit>
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, in_delegation_sid,
		'Start date', TO_CHAR(r.start_dtm, 'DD MON YYYY'), TO_CHAR(in_start_dtm, 'DD MON YYYY'));
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, in_delegation_sid,
		'End date', TO_CHAR(r.end_dtm, 'DD MON YYYY'), TO_CHAR(in_end_dtm, 'DD MON YYYY'));
END;

PROCEDURE UpdateDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_name					IN DELEGATION.name%TYPE,
	in_note					IN DELEGATION.NOTE%TYPE,
	in_group_by				IN DELEGATION.GROUP_BY%TYPE,
	in_is_note_mandatory	IN DELEGATION.IS_NOTE_MANDATORY%TYPE,
	in_is_flag_mandatory	IN DELEGATION.IS_FLAG_MANDATORY%TYPE,
	in_show_aggregate		IN DELEGATION.SHOW_AGGREGATE%TYPE,
	in_vis_matrix_tag_group	IN DELEGATION.tag_visibility_matrix_group_id%TYPE DEFAULT NULL
)
AS
	CURSOR c IS
		SELECT name, note, group_by, is_note_mandatory, is_flag_mandatory, show_aggregate, app_sid
		  FROM delegation d
		 WHERE delegation_sid = in_delegation_sid;
	r c%ROWTYPE;
	v_not_found BOOLEAN;
BEGIN
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	-- get original details to write a log entry describing the change...
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN;
	END IF;

	UPDATE delegation
	   SET note = in_note,
		   group_by = in_group_by,
		   is_note_mandatory = in_is_note_mandatory,
		   is_flag_mandatory = in_is_flag_mandatory,
		   show_aggregate = in_show_aggregate,
		   tag_visibility_matrix_group_id = in_vis_matrix_tag_group
	 WHERE delegation_sid = in_delegation_sid;

	-- has the name actually changed?
	IF r.name != in_name THEN
		-- propagate name change downwards....
		FOR rd IN (
			 SELECT name, delegation_Sid
			   FROM delegation
			  WHERE name = r.name -- just change things where the name is the same
			  START WITH delegation_sid = in_delegation_sid
			CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		)
		LOOP
			UPDATE delegation
			   SET name = trim(in_name)
			 WHERE delegation_sid = rd.delegation_sid;
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
				rd.delegation_sid, 'Name', rd.name, in_name);
		END LOOP;
	END IF;

	-- has the note actually changed?
	IF dbms_lob.compare(r.note, in_note) != 0 THEN
		-- propagate note change downwards....
		FOR rd IN (
			 SELECT note, delegation_sid
			   FROM delegation
			  WHERE dbms_lob.compare(NVL(note, EMPTY_CLOB()), NVL(r.note, EMPTY_CLOB())) = 0 -- only where the note wasn't overriden
			  START WITH delegation_sid = in_delegation_sid
			CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		)
		LOOP
			UPDATE delegation
			   SET note = in_note
			 WHERE delegation_sid = rd.delegation_sid;
			csr_data_pkg.AuditClobChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
				rd.delegation_sid, 'Note', rd.note, in_note);
		END LOOP;
	END IF;

	-- has the show aggregate flag actually changed?
	IF r.show_aggregate != in_show_aggregate THEN
		-- progate the change downwards....
		FOR rd in (
			 SELECT show_aggregate, delegation_sid
			   FROM delegation
			  WHERE show_aggregate = r.show_aggregate
			  START WITH delegation_sid = in_delegation_sid
			CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		)
		LOOP
			UPDATE delegation
			   SET show_aggregate = in_show_aggregate
			 WHERE delegation_sid = rd.delegation_sid;
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
				rd.delegation_sid, 'Show Aggregation', rd.show_aggregate, in_show_aggregate);
		END LOOP;
	END IF;

	-- <audit>
	csr_data_pkg.AuditClobChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
		in_delegation_sid, 'Note', r.note, in_note);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
		in_delegation_sid, 'Group by', r.group_by, in_group_by);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
		in_delegation_sid, 'Note is mandatory', r.is_note_mandatory, in_is_note_mandatory);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
		in_delegation_sid, 'Quality flag is mandatory', r.is_flag_mandatory, in_is_flag_mandatory);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid,
		in_delegation_sid, 'Show Aggregation', r.show_aggregate, in_show_aggregate);
END;

PROCEDURE UpdatePolicy(
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_submit_confirmation_text	IN DELEGATION_POLICY.SUBMIT_CONFIRMATION_TEXT%TYPE
)	
AS
	CURSOR c IS
		SELECT submit_confirmation_text, app_sid
		  FROM delegation_policy dp
		 WHERE delegation_sid = in_delegation_sid;
	r c%ROWTYPE;
	v_act			security_pkg.T_ACT_ID;
	v_app_sid 		security_pkg.T_SID_ID;
	v_audit_message VARCHAR2(50);
	v_submit_confirmation_text	DELEGATION_POLICY.SUBMIT_CONFIRMATION_TEXT%TYPE;
	v_not_found BOOLEAN;
BEGIN
	v_act := security_pkg.GetACT();
	-- check permissions
	IF NOT CheckDelegationPermission(v_act, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	v_app_sid := security_pkg.GetApp();
	v_submit_confirmation_text:= TRIM(in_submit_confirmation_text);
	-- get original details to write a log entry describing the change...
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found AND LENGTH(v_submit_confirmation_text) IS NULL THEN
		RETURN; -- Nothing to do if original doesn't exist and new text is blank
	END IF;

	IF v_not_found THEN
		INSERT INTO delegation_policy (app_sid, delegation_sid, submit_confirmation_text)
		VALUES (v_app_sid, in_delegation_sid, v_submit_confirmation_text);
		v_audit_message:='Created Delegation Policy';
	ELSE
		IF LENGTH(v_submit_confirmation_text) IS NULL THEN
			DELETE FROM delegation_policy
			 WHERE delegation_sid = in_delegation_sid;
			v_audit_message:='Deleted Delegation Policy';
		ELSE
			UPDATE delegation_policy
			   SET submit_confirmation_text = v_submit_confirmation_text
			 WHERE delegation_sid = in_delegation_sid;
			v_audit_message:='Updated Delegation Policy';
		END IF;
	END IF;
	
	-- <audit>
	csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
		in_delegation_sid, v_audit_message, r.submit_confirmation_text, v_submit_confirmation_text);
END;

PROCEDURE SetTranslation(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_lang					IN DELEGATION_DESCRIPTION.LANG%TYPE,
	in_description			IN DELEGATION_DESCRIPTION.DESCRIPTION%TYPE
)	
AS
	v_count			NUMBER;
	v_act			security_pkg.T_ACT_ID;
	v_app_sid		security_pkg.T_SID_ID;
	v_original      DELEGATION_DESCRIPTION.DESCRIPTION%TYPE;
	v_description   DELEGATION_DESCRIPTION.DESCRIPTION%TYPE;
BEGIN
	v_act := security_pkg.GetACT();
	v_app_sid := security_pkg.GetApp();
	-- check permissions
	IF NOT CheckDelegationPermission(v_act, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the delegation with sid ' ||in_delegation_sid);
	END IF;

	v_description := trim(in_description);
	v_original := '';

	FOR rd IN (  
		 SELECT delegation_sid
		   FROM delegation
		  START WITH delegation_sid = in_delegation_sid
		CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
	)
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM delegation_description
		 WHERE delegation_sid = rd.delegation_sid 
		   AND lang = in_lang;

		IF v_count > 0 THEN
			SELECT description
			  INTO v_original
			  FROM delegation_description
			 WHERE delegation_sid = rd.delegation_sid 
			   AND lang = in_lang;
		END IF;
		   
	   IF v_count = 0 THEN
			IF LENGTH(v_description) > 0 THEN
				INSERT INTO delegation_description (delegation_sid, lang, description, last_changed_dtm)
				   VALUES (rd.delegation_sid, in_lang, v_description, SYSDATE);
				
				csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
					rd.delegation_sid, 'Added Description (' || in_lang || ')', '', v_description);
			END IF;
		ELSE
			IF LENGTH(v_description) > 0 THEN
				-- has the description actually changed?
				IF v_original != v_description THEN
					UPDATE delegation_description
					   SET description = v_description,
					       last_changed_dtm = SYSDATE
					 WHERE delegation_sid = rd.delegation_sid 
					   AND lang = in_lang;
				   
					csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
						rd.delegation_sid, 'Updated Description (' || in_lang || ')', v_original, v_description);
				END IF;
			ELSE
				DELETE FROM delegation_description
				 WHERE delegation_sid = rd.delegation_sid 
				   AND lang = in_lang;
				csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
					rd.delegation_sid, 'Deleted Description (' || in_lang || ')', v_original, '');
			END IF;
		END IF;
		
	END LOOP;
END;

PROCEDURE SetSchedule(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_delegation_sid		IN security_pkg.T_SID_ID,
	in_schedule_xml			IN DELEGATION.SCHEDULE_XML%TYPE,
	in_submission_offset	IN DELEGATION.SUBMISSION_OFFSET%TYPE,
	in_reminder_offset		IN DELEGATION.REMINDER_OFFSET%TYPE
)	
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_original_schedule_xml			DELEGATION.SCHEDULE_XML%TYPE;
	v_original_submission_offset	DELEGATION.SUBMISSION_OFFSET%TYPE;
	v_original_reminder_offset		DELEGATION.REMINDER_OFFSET%TYPE;
BEGIN
	v_app_sid := security_pkg.GetApp();
	
	-- don't do anything if the data hasn't changed.
	SELECT schedule_xml, submission_offset, reminder_offset
	  INTO v_original_schedule_xml, v_original_submission_offset, v_original_reminder_offset
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	IF v_original_schedule_xml IS NOT NULL AND 
		RECURRENCE_PATTERN(XMLType(v_original_schedule_xml)).IsEqual(RECURRENCE_PATTERN(XMLType(in_schedule_xml))) AND
		v_original_submission_offset = in_submission_offset AND
		v_original_reminder_offset = in_reminder_offset
	THEN
		RETURN;
	END IF;
	
	-- check permissions
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating schedule for the delegation with sid ' ||in_delegation_sid);
	END IF;

    -- update delegation and all children.
	FOR r IN (
		SELECT delegation_sid
		  FROM v$delegation d
		WHERE app_sid = v_app_sid
		CONNECT BY PRIOR DELEGATION_SID = PARENT_SID
		START WITH delegation_sid = in_delegation_sid)
	LOOP
		UPDATE delegation
		   SET schedule_xml = in_schedule_xml,
			   submission_offset = in_submission_offset,
			   reminder_offset = in_reminder_offset
		 WHERE delegation_sid = r.delegation_sid AND
			   app_sid = v_app_sid;

		-- and create any new sheets if required.
		delegation_pkg.CreateSheetsForDelegation(r.delegation_sid);
		
		-- <audit>
		IF r.delegation_sid = in_delegation_sid THEN
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
				'Delegation schedule amended');
		ELSE
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, r.delegation_sid,
				'Delegation schedule amended (propogated from parent sid '|| in_delegation_sid ||')');
		END IF;
	END LOOP;
	
	delegation_pkg.UpdateSheetDatesForDelegation(in_delegation_sid, in_schedule_xml, in_submission_offset, in_reminder_offset);
END;

PROCEDURE UpdateSheetDatesForDelegation(
	in_delegation_sid		IN security_pkg.T_SID_ID,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_submission_offset	IN delegation.submission_offset%TYPE,
	in_reminder_offset		IN delegation.reminder_offset%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_submission_dtm		sheet.submission_dtm%TYPE;
	v_reminder_dtm			sheet.reminder_dtm%TYPE;
	v_delegation_end_dtm	DATE;
	v_period_set_id			delegation.period_set_id%TYPE;
	v_period_interval_id	delegation.period_interval_id%TYPE;
BEGIN
	v_app_sid := security_pkg.GetApp();
	-- internal only, no permissions check

	SELECT end_dtm, period_set_id, period_interval_id
	  INTO v_delegation_end_dtm, v_period_set_id, v_period_interval_id
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	FOR r IN (
		SELECT sheet_id FROM sheet
		 WHERE delegation_sid in (
		  SELECT delegation_sid
			FROM delegation d
			CONNECT BY PRIOR delegation_sid = parent_sid
			START WITH delegation_sid = in_delegation_sid))
	LOOP
		delegation_pkg.GetSheetSubmissionDtm(v_delegation_end_dtm, v_period_set_id, v_period_interval_id,
											 r.sheet_id, in_schedule_xml, in_submission_offset, v_submission_dtm);
		IF v_submission_dtm IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'No submission date found for period when updating sheet '||r.sheet_id||' for delegation '||in_delegation_sid);
		END IF;

        v_reminder_dtm := v_submission_dtm - in_reminder_offset;
	
		UPDATE sheet
		   SET reminder_dtm = v_reminder_dtm,
			   submission_dtm = v_submission_dtm
		 WHERE sheet_id = r.sheet_id AND 
		       app_sid = v_app_sid;
	END LOOP;
END;

PROCEDURE GetSheetSubmissionDtm(
	in_delegation_end_dtm	DATE,
	in_period_set_id		delegation.period_set_id%TYPE,
	in_period_interval_id	delegation.period_interval_id%TYPE,
	in_sheet_id				IN sheet.sheet_id%TYPE,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_submission_offset	IN delegation.submission_offset%TYPE,
	out_dtm					OUT sheet.submission_dtm%TYPE
)
AS
	v_submission_dtm				DATE;
	v_schedule_end_dtm				DATE;
	v_start_dtm 					DATE;
	v_end_dtm 						DATE;
BEGIN
	SELECT start_dtm, end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF in_schedule_xml IS NOT NULL THEN
		v_schedule_end_dtm := period_pkg.AddIntervals(in_period_set_id, in_period_interval_id, in_delegation_end_dtm, 1);
		delegation_pkg.GetDateFromScheduleXml(v_start_dtm, v_end_dtm, v_schedule_end_dtm, in_schedule_xml, 
			in_period_set_id, in_period_interval_id, v_submission_dtm);
	ELSE
		v_submission_dtm := v_end_dtm + in_submission_offset;
	END IF;
	
	out_dtm := v_submission_dtm;
END;

PROCEDURE GetDateFromScheduleXML(
	in_start_dtm			IN DATE,
	in_end_dtm				IN DATE,
	in_schedule_end_dtm		IN DATE,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_period_set_id		IN delegation.period_set_id%TYPE,
	in_period_interval_id	IN delegation.period_interval_id%TYPE,
	out_dtm					OUT DATE
)
AS
    v_recurrence			RECURRENCE_PATTERN;
    v_min_submission_dtm	DATE;
    v_submission_dates		T_RECURRENCE_DATES;
BEGIN
	-- we lop one day off the date, since strictly speaking the delegation
	-- ends at 23:59:59 on (say) 31st of month, so if schedule is first day
	-- of the month, we want the submission to be required the next day (i.e
	-- first of month)
	v_recurrence := RECURRENCE_PATTERN(XMLType(in_schedule_xml));

	-- Delegations with a monthly interval can have a user defined "repeat every N value", such as "The 1st day
	-- following every second month". For quarterly, half-yearly or annual forms this value is fixed.
	IF v_recurrence.repeat_every IS NOT NULL AND
	   in_period_set_id = 1 AND in_period_interval_id = 1 AND
	   v_recurrence.repeat_every > 1 
	THEN 
		v_min_submission_dtm := ADD_MONTHS(in_start_dtm, v_recurrence.repeat_every);
	ELSE
		v_min_submission_dtm := in_end_dtm;
	END IF;

	v_recurrence.MakeOccurrences(v_min_submission_dtm, in_schedule_end_dtm);
	v_submission_dates := v_recurrence.GetOccurrencesOnOrAfter(in_end_dtm);
	IF v_submission_dates.COUNT = 0 THEN
		out_dtm := NULL;
	ELSE
		out_dtm := v_submission_dates(v_submission_dates.FIRST); 
	END IF;
END;

-- ==================================
-- get information about a delegation
-- ==================================
PROCEDURE GetDelegation(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
	CURSOR c IS
		select app_sid, parent_sid
			from delegation
		 where delegation_sid = in_delegation_sid;
	r	c%ROWTYPE;
	v_user_sid		csr_user.csr_user_sid%TYPE;
	v_is_delegator	NUMBER(10);
	v_chk_deleg_sid	security_pkg.T_SID_ID;
	v_can_alter		NUMBER(10);
	v_can_delegate	NUMBER(10);
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN c;
	FETCH c INTO r;

	-- is the user the delegator?
	IF r.parent_sid = r.app_sid THEN
		-- top level, so just check this
		v_chk_deleg_sid := in_delegation_sid;
	ELSE
		-- check parent
		SELECT parent_sid
		  INTO v_chk_deleg_sid
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
	END IF;

	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_is_delegator
	  FROM (
		SELECT user_sid
		  FROM delegation_user
		 WHERE delegation_sid = v_chk_deleg_sid
		   AND user_sid = v_user_sid
		   AND inherited_from_sid = v_chk_deleg_sid
		 UNION
		SELECT user_sid
		  FROM delegation_role dlr
		  JOIN delegation_region dr ON dlr.delegation_Sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_Sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid
		 WHERE rrm.user_sid = v_user_sid
		   AND dlr.delegation_sid = v_chk_deleg_sid
		   AND dlr.inherited_from_sid = v_chk_deleg_sid
	  );

	IF CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_ALTER) THEN
		v_can_alter := 1;
	ELSE
		v_can_alter := 0;
	END IF;
	
	IF csr_data_pkg.CheckCapability(in_act_id, 'Subdelegation') THEN
		v_can_delegate := 1;
	ELSE
		v_can_delegate := 0;
	END IF;

	OPEN out_cur FOR
		SELECT d.delegation_sid, d.group_by, d.name, d.description, d.note, d.allocate_users_to,
			   d.period_set_id, d.period_interval_id, d.app_sid, d.start_dtm, d.end_dtm, full_name,
			   TO_CHAR(start_dtm,'dd Mon yyyy')||' - '||TO_CHAR(end_dtm-1, 'dd Mon yyyy') period_fmt,
			   is_note_mandatory, is_flag_mandatory, d.show_aggregate, d.parent_sid,
	 		   CASE
			   	WHEN d.parent_sid = d.app_sid THEN 1
				ELSE 0
			   END is_top_level,
			   v_is_delegator is_delegator, section_xml, v_can_alter can_alter, editing_url, schedule_xml,
			   reminder_offset, submission_offset, fully_delegated, v_can_delegate can_delegate,
			   submit_confirmation_text delegation_policy, layout_id, tag_visibility_matrix_group_id, allow_multi_period
		  FROM v$delegation_hierarchical d, csr_user cu
		 WHERE d.delegation_sid = in_delegation_sid
		   AND d.created_by_sid = cu.csr_user_sid;
END;

PROCEDURE GetAllFiles(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_cur_postit			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT x.region_description, x.period_set_id, x.period_interval_id, x.start_dtm, x.end_dtm,
			   fu.file_upload_sid, fu.filename, fu.mime_type, fu.data
		  FROM (
			SELECT DISTINCT r.description region_description,
				   d.period_set_id, d.period_interval_id, s.start_dtm, s.end_dtm,
				   svf.file_upload_sid
			  FROM v$region r, delegation d, sheet s, sheet_value sv, sheet_value_file svf
			 WHERE d.delegation_sid in (
					 SELECT delegation_sid
					   FROM delegation
					  START WITH delegation_sid = in_delegation_sid
					CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)
			   AND d.delegation_sid = s.delegation_sid
			   AND s.sheet_id = sv.sheet_id
			   AND sv.sheet_value_id = svf.sheet_value_id
			   AND sv.region_sid = r.region_sid
		 ) x, file_upload fu
		 WHERE x.file_upload_sid = fu.file_upload_sid
		 ORDER BY start_dtm, end_dtm, region_description, filename;
		 
	OPEN out_cur_postit FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, pf.data
		  FROM delegation_comment dc
			JOIN postit p ON dc.postit_id = p.postit_id AND dc.app_sid = p.app_sid
			JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE delegation_sid in (
				 SELECT delegation_sid 
				   FROM delegation 
				  START WITH delegation_sid = in_delegation_sid 
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid);
END;

-- return all the info about the delegation
PROCEDURE GetDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT CASE
				WHEN visibility = 'HIDE' OR hide_after_dtm IS NOT NULL THEN 'hidden-region'
				ELSE 'region'
			   END type, region_sid sid, description, pos, 0 sort_group, hide_after_dtm, NULL active
		  FROM v$delegation_region
		 WHERE delegation_sid = in_delegation_sid
		UNION ALL
		-- we want to differentiate indicators + categories, but sort them together
		SELECT CASE
			    WHEN visibility = 'HIDE' THEN 'hidden-ind'
				WHEN ind_type IN (1) THEN 'calculation'
				WHEN ind_type IN (2) THEN 'storedcalc'
				ELSE 'ind'
			   END type, di.ind_sid sid, di.description, di.pos, 1 sort_group, NULL hide_after_dtm, NULL active
		  FROM v$delegation_ind di, ind i
		 WHERE di.delegation_sid = in_delegation_sid
		   AND di.app_sid = i.app_sid
		   AND di.ind_sid = i.ind_sid
		   AND i.measure_sid IS NOT NULL
		UNION ALL
		SELECT 'category' type, di.ind_sid sid, di.description, di.pos, 1 sort_group, NULL hide_after_dtm, NULL active
		  FROM v$delegation_ind di, ind i
		 WHERE di.delegation_sid = in_delegation_sid
		   AND di.app_sid = i.app_sid
		   AND di.ind_sid = i.ind_sid
		   AND i.measure_sid IS NULL
		UNION ALL
		SELECT decode(duc.app_sid, NULL, 'delegee', 'delegee-cover') type, user_sid sid, full_name description, 0 pos, 2 sort_group, NULL hide_after_dtm, ut.account_enabled active
		  FROM delegation d
		  JOIN v$delegation_user du ON d.delegation_sid = du.delegation_sid AND d.app_sid = du.app_sid
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND cu.app_sid = du.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN delegation_user_cover duc ON duc.user_giving_cover_sid = du.user_sid AND duc.delegation_sid = d.delegation_sid 
		 WHERE d.delegation_sid = in_delegation_sid
		UNION ALL
		SELECT decode(duc.app_sid, NULL, 'delegator', 'delegator-cover') type, NVL(cuc.csr_user_sid, cu.csr_user_sid) sid, NVL(cuc.full_name, cu.full_name) description, 0 pos, 3 sort_group, NULL hide_after_dtm, NVL(utc.account_enabled, ut.account_enabled) active
		  FROM delegation d
		  JOIN delegation_delegator dd ON d.delegation_sid = dd.delegation_sid
		  JOIN csr_user cu ON dd.delegator_sid = cu.csr_user_sid AND cu.app_sid = dd.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN delegation_user_cover duc ON duc.user_giving_cover_sid = dd.delegator_sid and duc.delegation_sid = d.parent_sid
		  LEFT JOIN csr_user cuc ON duc.user_giving_cover_sid = cuc.csr_user_sid AND cuc.app_sid = duc.app_sid
		  LEFT JOIN security.user_table utc ON cuc.csr_user_sid = utc.sid_id
		 WHERE d.delegation_sid = in_delegation_sid
		 ORDER BY sort_group, pos;
END;

-- return all the descriptions for the delegation
PROCEDURE GetDelegationDescriptions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting delegation descriptions for the delegation with sid ' ||in_delegation_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT dd.lang, dd.description translated
		  FROM delegation_description dd
		 WHERE dd.delegation_sid = in_delegation_sid
 	     ORDER BY dd.lang;
END;

PROCEDURE GetMeasureConversions(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_delegation_sid	 	IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid		 		security_pkg.T_SID_ID;
BEGIN
	User_pkg.getSid(in_act_id, v_user_sid);
	
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		-- distinct because two inds on a delegation might have same UOM and conversion_factors
		SELECT DISTINCT mc.measure_conversion_id, mc.measure_conversion_id conversion_id, m.description, m.measure_sid, mc.description conversion_description,
			   NVL(mc.a, mcp.a) a, NVL(mc.b, mcp.b) b, NVL(mc.c, mcp.c) c
		  FROM delegation_ind di, ind i, measure m, measure_conversion mc, measure_conversion_period mcp
		 WHERE delegation_sid = in_delegation_sid
		   AND i.ind_sid = di.ind_sid
		   AND i.measure_sid = m.measure_sid
		   AND m.measure_sid = mC.measure_sid(+)
		   AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
		   AND (in_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
		   AND (in_start_dtm < mcp.end_dtm or mcp.end_dtm is null)
		 ORDER BY m.measure_sid, mc.measure_conversion_id; -- order matters since we group according to measure in output
END;

PROCEDURE INTERNAL_GetIndicators(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT di.ind_sid, NVL(isgmd.description, di.description) description,
			   NVL(i.format_mask, m.format_mask) format_mask,
			   NVL(i.scale, m.scale) scale, i.period_set_id, i.period_interval_id,
			   i.do_temporal_aggregation, i.calc_description, i.calc_xml, i.measure_sid,
			   i.aggregate, i.active, i.start_month, i.gri, i.target_direction,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.lookup_key,
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize,
			   m.description measure_description, m.option_set_id,
			   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.parent_sid,
			   i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp,
			   i.multiplier, i.info_xml, i.ind_type, di.pos, m.custom_field,
			   i.divisibility actual_divisibility,
			   NVL(i.divisibility, m.divisibility) divisibility,
			   CASE WHEN (di.mandatory = 1 AND d.allocate_users_to = 'region') THEN 1 ELSE 0 END mandatory,
			   di.section_key, dg.path grid_path, dg.form_sid, dg.aggregation_xml,
			   di.var_expl_group_id,  di.visibility, di.css_class,
			   CASE WHEN dgai.aggregate_to_ind_sid IS NULL THEN 0 ELSE 1 END is_aggregate_target,
			   NVL(isgm.master_ind_sid, isg.master_ind_sid) master_ind_sid,
			   CASE WHEN isgm.ind_sid IS NULL THEN 0 ELSE 1 END is_selection_group_member,
			   CASE WHEN isg.master_ind_sid IS NULL THEN 0 ELSE 1 END is_selection_group,
			   isgm.pos selection_group_pos, dp.name plugin_name, dp.js_class_type, NVL(aig.js_include, dp.js_include) js_include,
			   aigm.ind_sid aggregate_ind_sid,
			   CASE WHEN (di.allowed_na = 1 AND d.allocate_users_to = 'region') THEN 1 ELSE 0 END allowed_na
		  FROM v$delegation_ind di
		  JOIN delegation d ON di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  JOIN ind i ON i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  LEFT JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		  LEFT JOIN delegation_grid_aggregate_ind dgai ON di.app_sid = dgai.app_sid AND di.ind_sid = dgai.aggregate_to_ind_sid
		  LEFT JOIN aggregate_ind_group_member aigm ON di.app_sid = aigm.app_sid AND di.ind_sid = aigm.ind_sid
		  LEFT JOIN aggregate_ind_group aig ON aigm.app_sid = aig.app_sid AND aigm.aggregate_ind_group_id = aig.aggregate_ind_group_id
		  LEFT JOIN ind_selection_group_member isgm ON di.app_sid = isgm.app_sid AND di.ind_sid = isgm.ind_sid
		  LEFT JOIN ind_selection_group isg ON di.app_sid = isg.app_sid AND di.ind_sid = isg.master_ind_sid
		  LEFT JOIN ind_sel_group_member_desc isgmd ON isgmd.app_sid = isgm.app_sid AND isgmd.ind_sid = isgm.ind_sid
		   AND isgmd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		  LEFT JOIN delegation_plugin dp ON di.app_sid = dp.app_sid AND di.ind_sid = dp.ind_sid
		 WHERE di.delegation_sid = in_delegation_sid
		   AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
		 ORDER BY di.pos, isgm.pos;
END;

PROCEDURE INTERNAL_GetIndicatorFlags(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ifl.ind_sid, flag, ifl.description, requires_note
			FROM DELEGATION_IND DI, IND_FLAG IFL
		 WHERE DI.DELEGATION_SID = in_delegation_sid
			 AND IFL.IND_SID = DI.IND_SID
			 AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
		 ORDER BY ifl.ind_sid, flag;
END;

PROCEDURE INTERNAL_GetIndicatorTags(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DIT.ind_sid, DIT.tag
			FROM DELEGATION_IND DI, DELEGATION_IND_TAG DIT
		 WHERE DI.DELEGATION_SID = in_delegation_sid
			 AND DIT.IND_SID = DI.IND_SID AND DIT.delegation_sid = DI.delegation_sid
			 AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
		 ORDER BY DIT.ind_sid, DIT.tag;
END;

/* _OR_ consider doing this in delegation_body.INTERNAL_GetRegions
 * i.e. effectively some kind of region level security?
 *
 * -> when we fetch the delegation regions to show the user, we need to filter on role
\_ we need to think about the fact that we might be higher up the deleg tree, i.e.

   "Data provider"
	 |_ A
	   |_ B

	If I view B's sheet then I need to just show regions that match my role higher up

*
*/
PROCEDURE INTERNAL_GetRegions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT dr.region_sid, dr.description, dr.pos, 1 active, r.info_xml,
			   CASE WHEN (dr.mandatory = 1 AND d.allocate_users_to = 'indicator') THEN 1 ELSE 0 END mandatory,
			   r.parent_sid, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id,
			   r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref,
			   dr.aggregate_to_region_sid, dr.visibility,
			   CASE WHEN (dr.allowed_na = 1 AND d.allocate_users_to = 'indicator') THEN 1 ELSE 0 END allowed_na,
			   dr.hide_after_dtm, dr.hide_inclusive
		  FROM v$delegation_region dr, region r, delegation d
		 WHERE dr.delegation_sid = in_delegation_sid
		   AND r.app_sid = dr.app_sid AND r.region_sid = dr.region_sid
		   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.delegation_sid
		 ORDER BY dr.pos;
END;

PROCEDURE GetDelegationStructure(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur_deleg			OUT	SYS_REFCURSOR,
	out_cur_children		OUT	SYS_REFCURSOR,
	out_cur_inds			OUT	SYS_REFCURSOR,
	out_cur_ind_flags		OUT	SYS_REFCURSOR,
	out_cur_ind_tags		OUT SYS_REFCURSOR,
	out_cur_var_expl_groups	OUT	SYS_REFCURSOR,
	out_cur_var_expls		OUT	SYS_REFCURSOR,
	out_cur_valid_rules		OUT	SYS_REFCURSOR,
	out_cur_regions			OUT	SYS_REFCURSOR,
	out_cur_ind_depends		OUT SYS_REFCURSOR,
	out_cur_sheet_ids		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INTERNAL_GetIndicators(in_delegation_sid, in_section_key, out_cur_inds);
	INTERNAL_GetIndicatorFlags(in_delegation_sid, in_section_key, out_cur_ind_flags);
	INTERNAL_GetIndicatorTags(in_delegation_sid, in_section_key, out_cur_ind_tags);
	INTERNAL_GetRegions(in_delegation_sid, out_cur_regions);

	OPEN out_cur_deleg FOR
		SELECT d.delegation_sid, d.group_by, d.name, d.description, d.note, d.allocate_users_to,
			   d.period_set_id, d.period_interval_id, d.start_dtm, d.end_dtm, d.is_note_mandatory,
			   d.is_flag_mandatory, d.parent_sid,
			   -- there's no point showing the aggregate thing with a single region, unless it's a master for a delegation plan
			   CASE
					WHEN (
						SELECT COUNT(*)
						  FROM delegation_region
						 WHERE delegation_sid = in_delegation_sid) <=1
					 AND (
						SELECT COUNT(*)
						  FROM master_deleg
						 WHERE delegation_sid = in_delegation_sid) = 0 THEN 0
					ELSE show_aggregate
			   END show_aggregate,
	 		   CASE WHEN d.parent_sid = d.app_sid THEN 1 ELSE 0 END is_top_level,
			   d.section_xml, d.editing_url, d.schedule_xml, d.reminder_offset, d.hide_sheet_period,
			   delegation_pkg.GetRootDelegationSid(d.delegation_sid) root_delegation_sid,
			   dl.layout_id, dl.layout_xhtml, dl.valid layout_valid, d.tag_visibility_matrix_group_id, d.allow_multi_period, c.tolerance_checker_req_merged
		  FROM v$delegation d
		  LEFT JOIN delegation_layout dl ON d.app_sid = dl.app_sid AND d.layout_id = dl.layout_id
		       JOIN customer c ON d.app_sid = c.app_sid
		 WHERE d.delegation_sid = in_delegation_sid;

	OPEN out_cur_children FOR
		SELECT ind_sid, parent_region_sid region_sid, child_delegation_sid, is_different_interval,
			CASE WHEN COUNT(child_region_sid) > 1 THEN 1 ELSE 0 END is_split_region
		  FROM (
				SELECT dpi.ind_sid, dpr.region_sid parent_region_sid, dcr.region_sid child_region_sid,
					dc.delegation_sid child_delegation_sid,
					CASE WHEN dc.period_interval_id != dp.period_interval_id THEN 1 ELSE 0 END is_different_interval
				  FROM delegation dp
				  JOIN delegation dc ON dc.parent_sid = dp.delegation_sid
				  JOIN delegation_region dpr ON dp.delegation_sid = dpr.delegation_sid
				  JOIN delegation_region dcr -- child regions
					ON dc.delegation_sid = dcr.delegation_sid
				   AND dcr.aggregate_to_region_sid = dpr.region_sid
				  JOIN delegation_ind dpi ON dp.delegation_sid = dpi.delegation_sid
				  JOIN delegation_ind dci  -- child inds that are in the parent set we've selected
					ON dc.delegation_sid = dci.delegation_sid
				   AND dci.ind_sid = dpi.ind_sid
				 WHERE dp.delegation_sid = in_delegation_sid
				   AND (NVL(dpi.section_key,'_') = NVL(in_section_key,'_') OR NVL(in_section_key,'_') = 'all')
		    )
		 GROUP BY ind_sid, parent_region_sid, child_delegation_sid, is_different_interval;

	OPEN out_cur_var_expl_groups FOR
		SELECT DISTINCT veg.var_expl_group_id, veg.label
		  FROM delegation_ind di
		  JOIN var_expl_group veg ON di.var_expl_group_id = veg.var_expl_group_id
		 WHERE di.delegation_sid = in_delegation_sid
		   AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all');

	OPEN out_cur_var_expls FOR
		SELECT DISTINCT veg.var_expl_group_id, ve.var_expl_id, ve.label, ve.requires_note, ve.pos
		  FROM delegation_ind di
		  JOIN var_expl_group veg ON di.var_expl_group_id = veg.var_expl_group_id
		  JOIN var_expl ve ON veg.var_expl_group_id = ve.var_expl_group_id
		 WHERE di.delegation_sid = in_delegation_sid
		   AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
		   AND ve.hidden = 0
		 ORDER BY ve.pos;

	OPEN out_cur_valid_rules FOR
		SELECT ivr.ind_sid, ivr.expr, ivr.message, ivr.type
		  FROM delegation_ind di
		  JOIN ind_validation_rule ivr ON di.ind_sid = ivr.ind_sid
		 WHERE di.delegation_sid = in_delegation_sid
		   AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
		 ORDER BY ivr.ind_sid;

	OPEN out_cur_ind_depends FOR
		SELECT cd.ind_sid, cd.calc_ind_sid
		  FROM (SELECT DISTINCT ind_sid, CONNECT_BY_ROOT calc_ind_sid calc_ind_sid
				  FROM v$calc_dependency cd
				 START WITH calc_ind_sid in (
					SELECT ind_sid
					  FROM delegation_ind
					 WHERE delegation_sid = in_delegation_sid
					   AND (NVL(section_key,'_') = NVL(in_section_key,'_') or NVL(in_section_key,'_') = 'all')
				 )
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = calc_ind_sid) cd
		   JOIN delegation_ind di ON di.ind_sid = cd.ind_sid
		  WHERE di.delegation_sid = in_delegation_sid;
		
	OPEN out_cur_sheet_ids FOR
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = in_delegation_sid
		 ORDER BY start_dtm ASC;
END;

PROCEDURE GetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INTERNAL_GetIndicators(in_delegation_sid, in_section_key, out_cur);
END;

PROCEDURE GetIndicatorFlags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INTERNAL_GetIndicatorFlags(in_delegation_sid, in_section_key, out_cur);
END;

-- added experimentally for Vic Govt pitch -- not currently used as the
-- code in sheet.ashx is commented out.
PROCEDURE GetIndicatorDataSources(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT idst.ind_sid, ds.accuracy_type_id, dst.q_or_c, dst.max_score, ds.accuracy_type_option_id, ds.LABEL, ds.accuracy_weighting
			FROM DELEGATION_IND DI, accuracy_type_option DS, accuracy_TYPE dst, IND_accuracy_TYPE idst
		 WHERE DI.DELEGATION_SID = in_delegation_sid
					 AND DI.IND_SID = idst.IND_SID
					 AND idst.accuracy_TYPE_ID = dst.accuracy_TYPE_ID
					 AND dst.accuracy_TYPE_ID = ds.accuracy_TYPE_ID
					 AND (NVL(section_key,'_') = NVL(in_section_key,'_') OR NVL(in_section_key,'_') = 'all')
			 ORDER BY idst.ind_sid, dst.accuracy_type_id, ds.accuracy_weighting DESC;
END;

PROCEDURE GetUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT du.user_sid, cu.full_name, cu.csr_user_sid AS sid, cu.csr_user_sid, cu.email, cu.user_name,
			   ut.account_enabled active, cu.app_sid, cu.friendly_name, cu.enable_aria, cu.user_ref, cu.anonymised
		  FROM delegation_user du
			JOIN csr_user cu ON cu.csr_user_sid = du.user_sid AND cu.app_sid = du.app_sid
			JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id AND ut.sid_id = du.user_sid
		 WHERE du.delegation_sid = in_delegation_sid
		   AND du.inherited_from_sid = in_delegation_sid
		   AND (cu.csr_user_sid, cu.app_sid) NOT IN (
				SELECT user_giving_cover_sid, app_sid FROM delegation_user_cover WHERE delegation_sid = in_delegation_sid
		   )
		 UNION
		SELECT rrm.user_sid, cu.full_name, cu.csr_user_sid AS sid, cu.csr_user_sid, cu.email, cu.user_name,
			   ut.account_enabled active, cu.app_sid, cu.friendly_name, cu.enable_aria, cu.user_ref, cu.anonymised
		  FROM 	delegation d
			JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
			JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
			JOIN region_role_member rrm ON rrm.region_sid = dr.region_sid AND rrm.role_sid = dlr.role_sid AND rrm.app_sid = dr.app_sid AND rrm.app_sid = dlr.app_sid
			JOIN csr_user cu ON cu.csr_user_sid = rrm.user_sid AND cu.app_sid = rrm.app_sid
			JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id AND ut.sid_id = rrm.user_sid
		 WHERE d.delegation_sid =  in_delegation_sid;
END;

PROCEDURE GetRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INTERNAL_GetRegions(in_delegation_sid, out_cur);
END;

PROCEDURE GetLowestLevelRegions(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_root_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_root_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	OPEN out_cur FOR
	-- get lowest level points data was delegated to
		SELECT DISTINCT r.region_sid, r.description, r.pos, r.active,
			   r.parent_sid, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref, aggregate_to_region_sid
		  FROM delegation_region dr, v$region r,
			(SELECT delegation_sid, rownum rn
			   FROM delegation d
			  WHERE CONNECT_BY_ISLEAF = 1
			  START WITH delegation_sid = in_root_delegation_sid
			 CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)d
		 WHERE dr.delegation_sid = d.delegation_sid
		   AND dr.region_sid = r.region_sid
		 ORDER BY r.description; -- sort acc to hierarchy
END;

-- return the regions and indicators that belong to child delegations
-- also shows if we are the delgator to the region and if the granularity
-- differs. This is all very specific to displaying sheets
PROCEDURE GetChildDelegations(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_start_dtm					IN DATE,
	in_end_dtm						IN DATE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_parent_period_interval_id		delegation.period_interval_id%TYPE;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	SELECT period_interval_id
	  INTO v_parent_period_interval_id
	  FROM delegation
	 WHERE delegation_sid = in_parent_sid;

	OPEN out_cur FOR
		SELECT ch.delegation_sid, ch.type, ch.sid, DECODE(dd.delegator_sid, null, 0, 1) is_delegator,
			   DECODE(ch.period_interval_id, v_parent_period_interval_id, 0, 1) is_granularity_different
		  FROM delegation_delegator dd,
			   (SELECT di.delegation_sid, 'indicator' type, ind_sid sid, d.period_interval_id
				  FROM delegation_ind di, delegation d
				 WHERE d.delegation_sid = di.delegation_sid
				   AND d.parent_sid = in_parent_sid
				   AND d.start_dtm <= in_end_dtm
				   AND d.end_dtm > in_start_dtm
				 UNION
				SELECT DISTINCT dr.delegation_sid, 'region' type,
					   dr.aggregate_to_region_sid sid,
					   CASE WHEN dr.aggregate_to_region_sid != dr.region_sid THEN -1 ELSE d.period_interval_id END period_interval_id
				  FROM delegation_region dr, delegation d
				 WHERE d.delegation_sid = dr.delegation_sid
				   AND d.parent_sid = in_parent_sid
				   AND d.start_dtm <= in_end_dtm
				   AND d.end_dtm > in_start_dtm) ch
		 WHERE dd.delegation_sid(+) = ch.delegation_sid
		   AND dd.delegator_sid(+) = v_user_sid
		 ORDER BY delegation_sid, type;
END;

-- Simply returns all child delegations for the delegation sid passed in
-- that overlap the date range passed in
PROCEDURE GetAllChildDelegations(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	in_start_dtm		IN DATE,
	in_end_dtm			IN DATE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_parent_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT app_sid, delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml, note, group_by,
		       allocate_users_to, start_dtm, end_dtm, reminder_offset, is_note_mandatory, section_xml, editing_url, fully_delegated,
		       grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period, delegation_date_schedule_id, layout_id,
		       tag_visibility_matrix_group_id, period_set_id, period_interval_id, submission_offset, allow_multi_period, description,
		       delegation_policy
		  FROM v$delegation
		 WHERE parent_sid = in_parent_sid
		   AND start_dtm <= in_end_dtm
		   AND end_dtm > in_start_dtm
		 ORDER BY delegation_sid;
END;

PROCEDURE GetChildDelegationOverview(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR,
	out_user_cur		OUT SYS_REFCURSOR
)
AS
	v_parent_ind_count	NUMBER(10);
	v_parent_region_count	NUMBER(10);
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_parent_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT COUNT(*)
	  INTO v_parent_ind_count
	  FROM delegation_ind
	 WHERE delegation_sid = in_parent_sid;

	SELECT COUNT(*)
	  INTO v_parent_region_count
	  FROM delegation_region
	 WHERE delegation_sid = in_parent_sid;

	OPEN out_cur FOR
		SELECT delegation_sid, name, description,
			   period_set_id, period_interval_id,
			   CASE WHEN ind_count = 0 THEN 'No indicators' WHEN ind_count = v_parent_ind_count THEN 'All indicators' ELSE delegation_pkg.ConcatDelegationIndicators(delegation_Sid, 5) END inds,
			   CASE WHEN region_count = 0 THEN 'No regions' WHEN region_count = v_parent_region_count THEN 'All regions' ELSE delegation_pkg.ConcatDelegationRegions(delegation_Sid, 5) END regions
		  FROM (
			SELECT d.delegation_sid, d.name, d.description, d.period_set_id, d.period_interval_id,
				   COUNT(DISTINCT di.ind_sid) ind_count, COUNT(DISTINCT dr.region_sid) region_count
			  FROM v$delegation d, delegation_ind di, delegation_region dr
			 WHERE d.delegation_sid = di.delegation_sid(+)
			   AND d.delegation_sid = dr.delegation_sid(+)
			   AND d.parent_sid = in_parent_sid
			 GROUP BY d.delegation_Sid, d.name, d.description, d.period_set_id, d.period_interval_id
		 ) x;

	OPEN out_user_cur FOR
		SELECT d.delegation_sid, du.user_sid, cu.full_name, ut.account_enabled active
		  FROM csr.delegation d
		  JOIN csr.v$delegation_user du ON d.app_sid = du.app_sid AND d.delegation_sid = du.delegation_sid
		  JOIN csr.csr_user cu ON du.app_sid = cu.app_sid AND  du.user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE d.parent_sid = in_parent_sid;
END;

-- Determine which regions the given delegation could contain
PROCEDURE GetPossibleRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
	v_split_regions			NUMBER;
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT parent_sid
	  INTO v_parent_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	SELECT COUNT(*)
	  INTO v_split_regions
	  FROM delegation_region
	 WHERE delegation_sid = in_delegation_sid
	   AND aggregate_to_region_sid != region_sid;

	IF v_split_regions > 0 THEN
		-- get children of parent delegation's region
		OPEN out_cur FOR
			SELECT r.region_sid, r.description, dr.pos,
				   CASE WHEN (mandatory = 1 AND allocate_users_to = 'indicator') THEN 1 ELSE 0 END mandatory,
				   aggregate_to_region_sid
			  FROM delegation_region dr, v$region r, delegation d
			 WHERE r.app_sid = dr.app_sid AND r.parent_sid = dr.region_sid
			   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.parent_sid
			   AND d.delegation_sid = in_delegation_sid
			 ORDER BY pos;
	ELSE
		-- get parent delegation's region
		OPEN out_cur FOR
			SELECT dr.region_sid, dr.description, dr.pos,
				   CASE WHEN (mandatory = 1 and allocate_users_to = 'indicator') THEN 1 ELSE 0 END mandatory,
				   r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref, aggregate_to_region_sid
			  FROM v$delegation_region dr, region r, delegation d
			 WHERE r.app_sid = dr.app_sid AND r.region_sid = dr.region_sid
			   AND dr.delegation_sid = v_parent_sid
			   AND d.delegation_sid = v_parent_sid
			 ORDER BY pos;
	END IF;
END;

-- Determine which indicators the given delegation could contain
PROCEDURE GetPossibleIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	--added case to check if it is top level delegation or sub delegation and assign parent sid accordingly.
	SELECT 
	  CASE WHEN parent_sid = app_sid THEN in_delegation_sid ELSE parent_sid END
	  INTO v_parent_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- get inds that are in the parent delegation
	OPEN out_cur FOR
		SELECT di.ind_sid, di.description, di.pos, i.measure_sid
		  FROM v$delegation_ind di, ind i
		 WHERE delegation_sid = v_parent_sid
		   AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
		 ORDER BY di.pos;
END;

PROCEDURE GetPossibleChildDelItems(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_allocate_users_to	DELEGATION.allocate_users_to%TYPE;
BEGIN
	IF NOT CheckDelegationPermission(in_act_id, in_parent_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT allocate_users_to INTO v_allocate_users_to
		FROM DELEGATION
	 WHERE delegation_sid = in_parent_delegation_sid;

	-- all the items in the parent, minus the ones already allocated

	IF v_allocate_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT region_sid sid, description
			  FROM v$delegation_region
			 WHERE delegation_sid = in_parent_delegation_sid
			 ORDER BY pos;
	ELSE
		OPEN out_cur FOR
			SELECT ind_sid sid, description
			  FROM v$delegation_ind
			 WHERE delegation_sid = in_parent_delegation_sid
			 ORDER BY pos;
	END IF;
END;

-- ==================================
-- get delegations based on specific
-- criteria (e.g. by region, ind etc)
-- ==================================
PROCEDURE GetDelegsForRegionTerm(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_inactive_dtm	IN	DATE,
	out_delegs_cur	OUT	SYS_REFCURSOR
)
AS
	v_app_sid			security_pkg.T_ACT_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT app_sid
	  INTO v_app_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	-- return top level delegations for given region and child regions which ends after inactive date
	-- check for values in top delegation and child delegations
	OPEN out_delegs_cur FOR
		SELECT d.delegation_sid, d.name, d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id,
			   (
				SELECT MAX(s.start_dtm) 
				  FROM sheet s
				  JOIN sheet_value sv
				    ON s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
				 WHERE s.delegation_sid IN (
					   SELECT delegation_sid
						 FROM delegation
						WHERE app_sid = v_app_sid
						START WITH delegation_sid = d.delegation_sid
					  CONNECT BY PRIOR delegation_sid = parent_sid
					)
				   AND sv.region_sid IN (
						SELECT region_sid
						  FROM region
						 WHERE r.app_sid = v_app_sid
						 START WITH region_sid = in_region_sid
					   CONNECT BY PRIOR region_sid = parent_sid
					)
				   AND in_inactive_dtm < s.end_dtm
			   ) value_sheet_start_dtm
		  FROM v$delegation_hierarchical d
		  JOIN delegation_region dr
			ON d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
		  JOIN (
					SELECT r.region_sid, r.app_sid
					  FROM region r
				     WHERE r.app_sid = v_app_sid
					 START WITH r.region_sid = in_region_sid
				   CONNECT BY PRIOR r.region_sid = r.parent_sid
			   ) r
		    ON dr.app_sid = r.app_sid AND dr.region_sid = r.region_sid
		 WHERE d.parent_sid = d.app_sid
		   AND d.end_dtm > in_inactive_dtm;
END;

PROCEDURE GetDelegations(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_filter_ind					IN	security_pkg.T_SID_ID,
	in_filter_region				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_sheet_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
)
AS
	v_deleg_plans_region	security_pkg.T_SID_ID;
	v_fully_hide_sheets		NUMBER(1);
	v_user_tz				security.user_table.timezone%TYPE;
	v_delegation_detail_tbl	T_DELEGATION_DETAIL_TABLE;
	v_delegation_user_tbl	T_DELEGATION_USER_TABLE;
BEGIN
	IF in_ind_sid IS NOT NULL AND 
	   NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_region_sid IS NOT NULL AND
	   NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_deleg_plans_region := securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '/DelegationPlans/DelegPlansRegion');
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_plans_region, security_pkg.PERMISSION_READ) THEN
		v_deleg_plans_region := NULL;
	END IF;

	SELECT fully_hide_sheets
	  INTO v_fully_hide_sheets
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM region_list;	
	IF in_region_sid IS NULL AND in_filter_region IS NOT NULL THEN
		INSERT INTO region_list (region_sid)
			-- filter regions underneath the start points
			SELECT NVL(link_to_region_sid, region_sid)
			  FROM region
			 START WITH region_sid IN (
					SELECT region_sid
					  FROM region_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		 INTERSECT
			-- restrict to regions underneath the filter root
			SELECT NVL(link_to_region_sid, region_sid)
			  FROM region
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_filter_region
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
			 UNION
			SELECT v_deleg_plans_region
			  FROM dual
			 WHERE v_deleg_plans_region IS NOT NULL;
	ELSE
		INSERT INTO region_list (region_sid)
			-- filter regions underneath the start point
			SELECT NVL(r.link_to_region_sid, r.region_sid)
			  FROM region r
			 -- include the given region only, or all under the start point
			 -- if no region was specified
			 WHERE (in_region_sid IS NULL OR NVL(link_to_region_sid, region_sid) = in_region_sid)
			 START WITH region_sid IN (
					SELECT region_sid
					  FROM region_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
		-- note that this implies filtering by region, so DelegPlansRegion is omitted
	END IF;

	DELETE FROM ind_list;
	IF in_ind_sid IS NULL AND in_filter_ind IS NOT NULL THEN
		INSERT INTO ind_list (ind_sid)
			-- filter inds underneath the start points
			SELECT i.ind_sid
			  FROM ind i
			 START WITH ind_sid IN (
					SELECT ind_sid
					  FROM ind_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   CONNECT BY PRIOR ind_sid = parent_sid AND PRIOR app_sid = app_sid
		 INTERSECT
			-- restrict to inds underneath the filter root
			SELECT ind_sid
			  FROM ind
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ind_sid = in_filter_ind
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid;
	ELSE 
		INSERT INTO ind_list (ind_sid)
			-- filter inds underneath the start point
			SELECT i.ind_sid
			  FROM ind i
			 -- include the given indicator only, or all under the start point
			 -- if no indicator was specified
			 WHERE (in_ind_sid IS NULL OR ind_sid = in_ind_sid)
			 START WITH ind_sid IN (
					SELECT ind_sid
					  FROM ind_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   CONNECT BY PRIOR ind_sid = parent_sid AND PRIOR app_sid = app_sid;
	END IF;

	DELETE FROM temp_delegation_sid;
	IF in_user_sid IS NOT NULL THEN
		INSERT INTO temp_delegation_sid (delegation_sid)
			SELECT di.delegation_sid
			  FROM delegation_ind di, ind_list il
			 WHERE di.ind_sid = il.ind_sid
		 INTERSECT
			SELECT dr.delegation_sid
			  FROM delegation_region dr, region_list rl
			 WHERE dr.region_sid = rl.region_sid
		 INTERSECT
		    SELECT du.delegation_sid
		      FROM v$delegation_user du
		     WHERE user_sid = in_user_sid;
	ELSE
		INSERT INTO temp_delegation_sid (delegation_sid)
			SELECT di.delegation_sid
			  FROM delegation_ind di, ind_list il
			 WHERE di.ind_sid = il.ind_sid
		 INTERSECT
			SELECT dr.delegation_sid
			  FROM delegation_region dr, region_list rl
			 WHERE dr.region_sid = rl.region_sid;
	END IF;
		
	SELECT COALESCE(ut.timezone, a.timezone, 'Etc/GMT') 
	  INTO v_user_tz
	  FROM security.user_table ut, security.application a
	 WHERE a.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND ut.sid_id = SYS_CONTEXT('SECURITY', 'SID');
        
	INSERT INTO temp_delegation_detail (delegation_sid, parent_sid, name, editing_url,
		root_delegation_sid, period_set_id, period_interval_id, rid, start_dtm, end_dtm)
		SELECT d.delegation_sid, d.parent_sid, d.name, d.editing_url,
			   d.root_delegation_sid, d.period_set_id, d.period_interval_id, d.rid,
			   d.start_dtm, d.end_dtm
		  FROM temp_delegation_sid tds, (
				SELECT delegation_sid, editing_url, period_set_id, period_interval_id,
					   name, parent_sid, start_dtm, end_dtm, ROWNUM rid,
					   connect_by_root delegation_sid root_delegation_sid
				  FROM delegation d
				 WHERE start_dtm < NVL(in_end_dtm, SYSDATE)
				   AND end_dtm > in_start_dtm
				 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND parent_sid = SYS_CONTEXT('SECURITY', 'APP')
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
				 ORDER SIBLINGS BY name
			) d
		 WHERE tds.delegation_sid = d.delegation_sid;

	SELECT T_DELEGATION_DETAIL(
		sheet_id,
		parent_sheet_id,
		delegation_sid,
		parent_delegation_sid,
		is_visible,
		name,
		start_dtm,
		end_dtm,
		period_set_id,
		period_interval_id,
		delegation_start_dtm,
		delegation_end_dtm,
		submission_dtm,
		status,
		sheet_action_description,
		sheet_action_downstream,
		fully_delegated,
		editing_url,
		last_action_id,
		is_top_level,
		approve_dtm,
		delegated_by_user,
		percent_complete,
		rid,
		root_delegation_sid,
		parent_sid		
	)
	  BULK COLLECT INTO v_delegation_detail_tbl
	  FROM (SELECT 
				sheet_id,
				parent_sheet_id,
				delegation_sid,
				parent_delegation_sid,
				is_visible,
				name,
				start_dtm,
				end_dtm,
				period_set_id,
				period_interval_id,
				delegation_start_dtm,
				delegation_end_dtm,
				submission_dtm,
				status,
				sheet_action_description,
				sheet_action_downstream,
				fully_delegated,
				editing_url,
				last_action_id,
				is_top_level,
				approve_dtm,
				delegated_by_user,
				percent_complete,
				rid,
				root_delegation_sid,
				parent_sid		
			  FROM temp_delegation_detail);


	-- checks security on each delegation
	-- WHERE?!
	OPEN out_deleg_cur FOR
		SELECT d.delegation_sid, d.parent_sid, d.name, NVL(dd.description, d.name) description,
			   d.period_set_id, d.period_interval_id, d.start_dtm, d.end_dtm,
			   d.editing_url, d.root_delegation_sid			   
		  FROM TABLE(v_delegation_detail_tbl) d
		  LEFT JOIN delegation_description dd
			     ON dd.delegation_sid = d.delegation_sid 
	   		    AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
         ORDER BY d.rid;

	OPEN out_sheet_cur FOR
		SELECT s.delegation_sid, s.sheet_id, s.start_dtm, s.end_dtm,
			   she.sheet_action_id last_action_id, s.submission_dtm,
			   CASE WHEN SYSTIMESTAMP AT TIME ZONE tz.user_tz >= from_tz_robust(cast(s.submission_dtm as timestamp), v_user_tz)
	                 AND she.sheet_action_id IN (0,10,2) 
	                    THEN 1 
					WHEN SYSTIMESTAMP AT TIME ZONE tz.user_tz >= from_tz_robust(cast(s.reminder_dtm as timestamp), v_user_tz)
	                 AND she.sheet_action_id IN (0,10,2)
	                    THEN 2 
					ELSE 3
			   END status,
			   sha.description sheet_action_description,
			   sha.colour last_action_colour
		  FROM TABLE(v_delegation_detail_tbl) d
		  	   -- AT TIME ZONE cannot take a bind variable (gives ORA-00920: invalid relational operator),
		  	   -- but it works fine with a column
		  JOIN (SELECT v_user_tz user_tz
		  	      FROM dual) tz ON 1=1
	      JOIN sheet s
			ON d.delegation_sid = s.delegation_sid
		  LEFT JOIN sheet_history she ON s.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = s.sheet_id AND s.app_sid = she.app_sid
		  LEFT JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id
	   	 WHERE (s.is_visible = 1 OR v_fully_hide_sheets = 0) -- is_visible normally just hides on myDelegations, but some customers want it hidden on browse deleg too
         ORDER BY d.rid, s.start_dtm;

	DELETE FROM temp_delegation_user;
	INSERT INTO temp_delegation_user (delegation_sid, user_sid)
		SELECT /*+CARDINALITY(tdd, 10000) CARDINALITY(dr, 20000) CARDINALITY(rrm, 1000000)*/
			   DISTINCT dlr.delegation_sid, rrm.user_sid
		  FROM TABLE(v_delegation_detail_tbl) tdd
		  JOIN delegation_role dlr ON tdd.delegation_sid = dlr.delegation_sid AND tdd.delegation_sid = dlr.inherited_from_sid
		  JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid;
	
	SELECT T_DELEGATION_USER(delegation_sid, user_sid)
	  BULK COLLECT INTO v_delegation_user_tbl
	  FROM (SELECT delegation_sid, user_sid
			  FROM temp_delegation_user);

	OPEN out_users_cur FOR
		SELECT /*+CARDINALITY(tdd, 10000)*/
			   DISTINCT du.delegation_sid, cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM TABLE(v_delegation_detail_tbl) tdd
		  JOIN delegation_user du ON tdd.delegation_sid = du.delegation_sid AND du.inherited_from_sid = tdd.delegation_sid
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 UNION
		SELECT /*+CARDINALITY(tu, 100000) CARDINALITY(cu, 100000) CARDINALITY(ut, 100000)*/
			   tu.delegation_sid, cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM TABLE(v_delegation_user_tbl) tu
		  JOIN csr_user cu ON tu.user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id;
END;

PROCEDURE GetSheetStatsForPortletGauge_Legacy(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_deleg_plans_region	security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_fully_hide_sheets		NUMBER(1);
	cur_regions				SYS_REFCURSOR;
BEGIN
	IF (in_region_sid IS NOT NULL) AND (NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	v_deleg_plans_region := securableObject_pkg.GetSidFromPath(in_act_id, v_app_sid, '/DelegationPlans/DelegPlansRegion');
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_deleg_plans_region, security_pkg.PERMISSION_READ) THEN
		v_deleg_plans_region := NULL;
	END IF;
	
	SELECT fully_hide_sheets 
	  INTO v_fully_hide_sheets 
	  FROM customer 
	 WHERE app_sid = v_app_sid;

	 OPEN out_cur FOR
		SELECT sla.sheet_id, d.delegation_sid, d.parent_sid, d.name, d.region_sid, sla.start_dtm, sla.end_dtm, d.period_set_id, d.period_interval_id, sla.last_action_id, sla.submission_dtm, 
			TO_CHAR(sla.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, sla.status, delegation_pkg.ConcatDelegationUsers(d.delegation_sid) users, sla.last_action_desc sheet_action_description, 
			d.editing_url, d.root_delegation_sid, sla.last_action_colour, d.lvl "LEVEL"
		  FROM (
			SELECT DISTINCT d.app_sid, d.delegation_sid, d.parent_sid, d.name, dr.region_sid, d.editing_url, d.root_delegation_sid,
				   d.period_set_id, d.period_interval_id, d.rid, d.lvl
			  FROM (
				SELECT app_sid, delegation_sid, ind_sid
				  FROM delegation_ind di 
				 WHERE ind_sid IN (
					SELECT i.ind_sid
					  FROM ind i
					 START WITH ind_sid IN (
						SELECT ind_sid
						  FROM ind_start_point
						 WHERE user_sid = security_pkg.GetSid
						)
				   CONNECT BY PRIOR ind_sid = parent_sid AND PRIOR app_sid = app_sid
					)
				) di, 
				delegation_region dr,           	
				(
					SELECT app_sid, delegation_sid, editing_url, period_set_id, period_interval_id, name,
						   parent_sid, start_dtm, ROWNUM rid, connect_by_root delegation_sid root_delegation_sid, level lvl
					  FROM delegation
					 WHERE start_dtm < NVL(in_end_dtm, SYSDATE)
					   AND end_dtm > in_start_dtm 
					 START WITH app_sid = v_app_sid AND parent_sid = v_app_sid
				   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid  
					 ORDER SIBLINGS BY name 
				) d
			 WHERE d.app_sid = di.app_sid
			   AND d.delegation_sid = di.delegation_sid(+)
			   AND d.app_sid = dr.app_sid
			   AND d.delegation_sid = dr.delegation_sid(+)
			   -- Checking for the requested region, or its children.
			   AND (in_region_sid IS NULL OR (dr.region_sid = in_region_sid OR (dr.region_sid IN (
					SELECT region_sid
					  FROM region
					 START WITH region_sid = in_region_sid
					 CONNECT BY PRIOR region_sid = parent_sid))))
			   AND d.app_sid = v_app_sid
			   -- Checking for region start points or descendants
			   AND (in_region_sid IS NOT NULL OR (dr.region_sid IN (
					SELECT region_sid
					  FROM region
						   START WITH app_sid = v_app_sid 
							 AND region_sid IN (SELECT region_sid
												  FROM region_start_point
												 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
						   CONNECT BY PRIOR app_sid = app_sid 
							 AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				   ) OR dr.region_sid = v_deleg_plans_region))
			  GROUP BY d.app_sid, d.delegation_sid, d.parent_sid, d.name, dr.region_sid, d.editing_url, d.root_delegation_sid, 
					   d.period_set_id, d.period_interval_id, d.rid, d.lvl
		 ) d, sheet_with_last_action sla
		 WHERE d.app_sid = sla.app_sid(+)
		   AND d.delegation_sid = sla.delegation_sid(+)
		   AND (is_visible = 1 OR v_fully_hide_sheets = 0) -- is_visible normally just hides on myDelegations, but some customers want it hidden on browse deleg too
		 ORDER BY rid, start_dtm;
END;

PROCEDURE GetSheetStatsForPortletGauge(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_deleg_plans_region	security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_fully_hide_sheets		NUMBER(1);
	cur_regions				SYS_REFCURSOR;
BEGIN
	IF (in_region_sid IS NOT NULL) AND (NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	v_deleg_plans_region := securableObject_pkg.GetSidFromPath(in_act_id, v_app_sid, '/DelegationPlans/DelegPlansRegion');
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_deleg_plans_region, security_pkg.PERMISSION_READ) THEN
		v_deleg_plans_region := NULL;
	END IF;
	
	SELECT fully_hide_sheets 
	  INTO v_fully_hide_sheets 
	  FROM customer 
	 WHERE app_sid = v_app_sid;

	OPEN out_cur FOR
		WITH selected_region_tree AS (
            SELECT NVL(link_to_region_sid, region_sid) region_sid
              FROM region
             START WITH region_sid IN (
                SELECT region_sid
                  FROM region
                 WHERE region_sid = in_region_sid
                    OR (in_region_sid IS NULL AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = security.security_pkg.GetSid))
                 )
               CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
        )
        SELECT sla.sheet_id, d.delegation_sid, d.parent_sid, d.name, dr.region_sid, sla.start_dtm, sla.end_dtm, d.period_set_id, d.period_interval_id, sla.last_action_id, sla.submission_dtm, 
            TO_CHAR(sla.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, sla.status, sla.last_action_desc sheet_action_description, 
            d.editing_url, d.root_delegation_sid, sla.last_action_colour, d.lvl "LEVEL"
          FROM (
                SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, 
                    d.start_dtm, d.end_dtm, d.reminder_offset, d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory,
                    d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id, d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id,
                    d.submission_offset, d.allow_multi_period, ROWNUM rid, CONNECT_BY_ROOT(d.delegation_sid) root_delegation_sid, LEVEL lvl
                  FROM delegation d
                 START WITH d.delegation_sid IN (SELECT delegation_sid FROM delegation WHERE parent_sid = app_sid AND start_dtm < NVL(in_end_dtm, SYSDATE) AND end_dtm > in_start_dtm)
               CONNECT BY d.parent_sid = PRIOR d.delegation_sid
          ) d
          JOIN csr.delegation_region dr ON d.delegation_sid = dr.delegation_sid
          JOIN /*+ index(security.user_table PK_USER_TABLE) */sheet_with_last_action sla ON sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid AND (sla.is_visible = 1 OR v_fully_hide_sheets = 0)
          JOIN selected_region_tree r ON dr.region_sid = r.region_sid
         WHERE delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getact, d.delegation_sid, DELEG_PERMISSION_READ) = 1
         ORDER BY d.rid, d.start_dtm;
END;

PROCEDURE GetMyDelegations(
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetMyDelegations(
		in_region_sid => NULL,
		in_days => NULL,
		out_sheets => out_sheets,
		out_users => out_users,
		out_deleg_regions => out_deleg_regions
	);
END;

PROCEDURE GetMyDelegations(
	in_days					IN	NUMBER,
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetMyDelegations(
		in_region_sid => NULL,
		in_days => in_days,
		out_sheets => out_sheets,
		out_users => out_users,
		out_deleg_regions => out_deleg_regions
	);
END;

PROCEDURE GetMyDelegations(
	in_region_sid			IN	NUMBER, -- null means all
	in_days					IN	NUMBER, -- null means all
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
)
AS
	v_now						DATE;
	v_show_curr_period_sheets	NUMBER(1);
	v_period_name				reporting_period.name%TYPE;
	v_period_start_dtm			reporting_period.start_dtm%TYPE;
	v_period_end_dtm			reporting_period.end_dtm%TYPE;
	v_delegation_detail_tbl		T_DELEGATION_DETAIL_TABLE;
	v_delegation_user_tbl		T_DELEGATION_USER_TABLE;
BEGIN
	-- should we show all the sheets for the current reporting period, or be smart about it and work out what's best for the user?
	-- (some customers like to see everything, hence this option...)
	SELECT show_all_sheets_for_rep_prd
	  INTO v_show_curr_period_sheets
	  FROM customer;
	
	IF v_show_curr_period_sheets = 1 THEN
		reporting_period_pkg.GetCurrentPeriod(SYS_CONTEXT('SECURITY', 'APP'), v_period_name, v_period_start_dtm, v_period_end_Dtm);
	END IF;

	DELETE FROM temp_delegation_sid;
	DELETE FROM temp_delegation_detail;
	DELETE FROM temp_delegation_user;

	SELECT SYSDATE INTO v_now FROM DUAL;

	-- delegations I'm involved in
	INSERT INTO temp_delegation_sid (delegation_sid)
		SELECT delegation_sid
		  FROM (
				SELECT app_sid, delegation_sid, user_sid
				  FROM csr.delegation_user
				 WHERE inherited_from_sid = delegation_sid
				   AND user_sid = SYS_CONTEXT('SECURITY','SID')
				 UNION ALL
				SELECT /*+ALL_ROWS CARDINALITY(rrm, 1000000)*/ DISTINCT d.app_sid, d.delegation_sid, rrm.user_sid
				  FROM csr.delegation d
				  JOIN csr.delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
				  JOIN csr.delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
				  JOIN csr.region_role_member rrm ON rrm.region_sid = dr.region_sid AND rrm.role_sid = dlr.role_sid AND rrm.app_sid = d.app_sid
				 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				   AND NOT EXISTS (
					SELECT NULL
					  FROM csr.delegation_user
					 WHERE user_sid = rrm.user_sid
					   AND delegation_sid = d.delegation_sid
				)
		)x
		WHERE EXISTS (
			SELECT 1
			  FROM delegation_region dr
			 WHERE x.delegation_sid = dr.delegation_sid
			   AND dr.app_sid = SYS_CONTEXT('SECURITY','APP')
		); -- hide delegs with no regions

	INSERT INTO temp_delegation_detail (parent_sheet_id, is_visible, sheet_id, delegation_sid, name, start_dtm, end_dtm,
										delegation_start_dtm, delegation_end_dtm, period_set_id, period_interval_id,
										submission_dtm, status, sheet_action_description, sheet_action_downstream,
										fully_delegated, parent_delegation_sid, editing_url, last_action_id,
										is_top_level, approve_dtm, delegated_by_user, percent_complete)
		-- i've delegated these
		SELECT /*+ALL_ROWS*/ sp.sheet_id parent_sheet_id, sp.is_visible, sla.sheet_id, d.delegation_sid, d.description name,
			   sla.start_dtm, sla.end_dtm, d.start_dtm delegation_start_dtm, d.end_dtm delegation_end_dtm,
			   d.period_set_id, d.period_interval_id, sla.submission_dtm,
			   DECODE(sla.last_action_id, csr_data_pkg.ACTION_SUBMITTED, sp.status,
					  csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, sp.status, sla.status) status,
			   sa.description sheet_action_description, sa.downstream_description sheet_action_downstream,
			   d.fully_delegated, d.parent_sid parent_delegation_sid,
			   d.editing_url, sla.last_action_id, DECODE(d.parent_sid, d.app_sid, 1, 0) is_top_level,
			   sp.submission_dtm approve_dtm,
			   1 delegated_by_user,
			   sla.percent_complete
		  FROM temp_delegation_sid td
		  JOIN v$delegation d ON td.delegation_sid = d.parent_sid AND d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN sheet_with_last_action sp ON td.delegation_sid = sp.delegation_sid AND sp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN sheet_with_last_action sla ON d.delegation_sid = sla.delegation_sid AND d.app_sid = sla.app_sid AND sla.is_visible = 1
		  JOIN sheet_action sa ON sla.last_action_id = sa.sheet_action_id
		 WHERE sp.start_dtm <= sla.start_dtm
		   AND sp.end_dtm >= sla.end_dtm
		   AND -- time out xx days after submission date, or 7 days after last action
			   (sla.submission_dtm > SYSDATE - NVL(in_days, 60)
					OR sla.last_action_dtm > SYSDATE - 7
					OR sla.last_action_id NOT IN (csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_ACCEPTED_WITH_MOD, csr_data_pkg.ACTION_MERGED)
					OR (sla.end_dtm > v_period_start_dtm AND sla.start_dtm < v_period_end_Dtm AND v_show_curr_period_sheets = 1));

	INSERT INTO temp_delegation_detail (parent_sheet_id, is_visible, sheet_id, delegation_sid, name, start_dtm, end_dtm,
										delegation_start_dtm, delegation_end_dtm, period_set_id, period_interval_id,
										submission_dtm, status, sheet_action_description, sheet_action_downstream, fully_delegated,
										parent_delegation_sid, editing_url, last_action_id,
										is_top_level, approve_dtm, delegated_by_user, percent_complete)
		-- i'm filling in these
		SELECT /*+ALL_ROWS*/ 0 parent_sheet_id, sla.is_visible, sla.sheet_id, d.delegation_sid, d.description name,
			   sla.start_dtm, sla.end_dtm, d.start_dtm delegation_start_dtm, d.end_dtm delegation_end_dtm,
			   d.period_set_id, d.period_interval_id, sla.submission_dtm, sla.status,
			   sa.description sheet_action_description, sa.downstream_description sheet_action_downstream,
			   d.fully_delegated, d.parent_sid parent_delegation_sid,
			   d.editing_url, sla.last_action_id, DECODE(d.parent_sid, d.app_sid, 1, 0) is_top_level,
			   sla.submission_dtm approve_dtm,
			   0 delegated_by_user,
			   sla.percent_complete
		  FROM temp_delegation_sid td
		  JOIN v$delegation d ON td.delegation_sid = d.delegation_sid AND d.app_sid = SYS_CONTEXT('SECURITY','APP')
		  JOIN sheet_with_last_action sla ON d.delegation_sid = sla.delegation_sid AND d.app_sid = sla.app_sid AND sla.is_visible = 1
		  JOIN sheet_action sa ON sla.last_action_id = sa.sheet_action_id
		 WHERE -- time out xx days after submission date, or 7 days after last action
		 	   (sla.submission_dtm > SYSDATE - NVL(in_days, 60)
			 		OR sla.last_action_dtm > SYSDATE - 7
		 			OR sla.last_action_id NOT IN (csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_ACCEPTED_WITH_MOD, csr_data_pkg.ACTION_MERGED)
			 		OR (sla.end_dtm > v_period_start_dtm AND sla.start_dtm < v_period_end_Dtm AND v_show_curr_period_sheets = 1)
			 		OR ( -- if we've got something open in the subdelegated list, then include the parent
						sla.sheet_id IN (SELECT parent_sheet_id FROM temp_delegation_detail)
			 		)
		 	    );

	INSERT INTO temp_delegation_detail (parent_sheet_id, is_visible, sheet_id, delegation_sid, name, start_dtm, end_dtm,
										delegation_start_dtm, delegation_end_dtm, period_set_id, period_interval_id,
										submission_dtm, status, sheet_action_description, sheet_action_downstream,
										fully_delegated, parent_delegation_sid, editing_url, last_action_id,
										is_top_level, approve_dtm, delegated_by_user, percent_complete)
		-- i need to approve DCR on these, d is the sheet for dcr, dp is my sheet pretending to be parent 
		SELECT /*+ALL_ROWS*/ sp.sheet_id parent_sheet_id, sp.is_visible, sla.sheet_id, d.delegation_sid, d.description name,
			   sla.start_dtm, sla.end_dtm, dp.start_dtm delegation_start_dtm, dp.end_dtm delegation_end_dtm,
			   d.period_set_id, d.period_interval_id, sla.submission_dtm,
			   DECODE(sla.last_action_id, csr_data_pkg.ACTION_SUBMITTED, sp.status,
					  csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, sp.status, sla.status) status,
			   sa.description sheet_action_description, sa.downstream_description sheet_action_downstream,
			   d.fully_delegated, dp.parent_sid parent_delegation_sid,
			   d.editing_url, sla.last_action_id, DECODE(d.parent_sid, d.app_sid, 1, 0) is_top_level,
			   sp.submission_dtm approve_dtm,
			   1 delegated_by_user,
			   sla.percent_complete
		  FROM (
				SELECT s2.sheet_id, s2.delegation_sid, s.delegation_sid parent_sid
				  FROM delegation_user du
				  JOIN sheet s ON s.delegation_sid = du.delegation_sid
				  JOIN sheet_change_req sr ON sr.active_sheet_id = s.sheet_id AND processed_dtm IS NULL
				  JOIN sheet s2 ON sr.req_to_change_sheet_id = s2.sheet_id
				 WHERE du.inherited_from_sid = du.delegation_sid
				   AND du.user_sid = SYS_CONTEXT('SECURITY','SID')
			) td
		  JOIN v$delegation d ON td.delegation_sid = d.delegation_sid AND d.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN v$delegation dp ON td.parent_sid = dp.delegation_sid AND dp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN sheet_with_last_action sla ON td.sheet_id = sla.sheet_id AND sla.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  JOIN sheet_with_last_action sp ON dp.delegation_sid = sp.delegation_sid AND dp.app_sid = sp.app_sid AND sp.is_visible = 1
		  JOIN sheet_action sa ON sla.last_action_id = sa.sheet_action_id
		 WHERE sp.start_dtm <= sla.start_dtm
		   AND sp.end_dtm >= sla.end_dtm
		   AND d.parent_sid != td.parent_sid;

	SELECT T_DELEGATION_DETAIL(
		sheet_id,
		parent_sheet_id,
		delegation_sid,
		parent_delegation_sid,
		is_visible,
		name,
		start_dtm,
		end_dtm,
		period_set_id,
		period_interval_id,
		delegation_start_dtm,
		delegation_end_dtm,
		submission_dtm,
		status,
		sheet_action_description,
		sheet_action_downstream,
		fully_delegated,
		editing_url,
		last_action_id,
		is_top_level,
		approve_dtm,
		delegated_by_user,
		percent_complete,
		rid,
		root_delegation_sid,
		parent_sid		
	)
	  BULK COLLECT INTO v_delegation_detail_tbl
	  FROM (SELECT 
				sheet_id,
				parent_sheet_id,
				delegation_sid,
				parent_delegation_sid,
				is_visible,
				name,
				start_dtm,
				end_dtm,
				period_set_id,
				period_interval_id,
				delegation_start_dtm,
				delegation_end_dtm,
				submission_dtm,
				status,
				sheet_action_description,
				sheet_action_downstream,
				fully_delegated,
				editing_url,
				last_action_id,
				is_top_level,
				approve_dtm,
				delegated_by_user,
				percent_complete,
				rid,
				root_delegation_sid,
				parent_sid		
			  FROM temp_delegation_detail);


	-- uses v_delegation_detail_tbl

	INSERT INTO temp_delegation_user (delegation_sid, user_sid)
		SELECT /*+CARDINALITY(tdd, 10000) CARDINALITY(dr, 20000) CARDINALITY(rrm, 1000000)*/
			   DISTINCT dlr.delegation_sid, rrm.user_sid
		  FROM TABLE(v_delegation_detail_tbl) tdd
		  JOIN csr.delegation_role dlr ON tdd.delegation_sid = dlr.delegation_sid AND dlr.inherited_from_sid = tdd.delegation_sid
		  JOIN csr.delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN csr.region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid;
		 
	INSERT INTO temp_delegation_user (delegation_sid, user_sid)
		SELECT /*+CARDINALITY(tdd, 10000) CARDINALITY(dr, 20000) CARDINALITY(rrm, 1000000)*/
			   DISTINCT dlr.delegation_sid, rrm.user_sid
		  FROM csr.temp_delegation_detail tdd
		  JOIN csr.delegation_role dlr ON tdd.parent_delegation_sid = dlr.delegation_sid AND tdd.delegated_by_user = 0 AND dlr.inherited_from_sid = tdd.parent_delegation_sid
		  JOIN csr.delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN csr.region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid;


	SELECT T_DELEGATION_USER(delegation_sid, user_sid)
	  BULK COLLECT INTO v_delegation_user_tbl
	  FROM (SELECT delegation_sid, user_sid
			  FROM temp_delegation_user);

	OPEN out_sheets FOR
		-- TODO: 13p / 18n fix
		SELECT /*+CARDINALITY(d, 10000)*/
			   d.parent_sheet_id, d.delegated_by_user, d.is_visible, d.sheet_id, d.delegation_sid, d.name, d.start_dtm,
		 	   d.end_dtm, d.period_set_id, d.period_interval_id, d.delegation_start_dtm, d.delegation_end_dtm,
		 	   d.end_dtm - d.start_dtm duration, v_now now_dtm,
			   d.submission_dtm, TO_CHAR(d.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, d.status,
			   d.sheet_action_description, d.sheet_action_downstream,
			   d.fully_delegated, d.parent_delegation_sid,
			   d.editing_url, d.last_action_id, d.is_top_level,
			   d.approve_dtm, sr.sheet_change_req_id, csc.child_sheet_colour,
			   d.percent_complete
		  FROM TABLE(v_delegation_detail_tbl) d
	 LEFT JOIN (SELECT d.delegation_sid,
		  			   DECODE(MAX(DECODE(slac.last_action_colour,'R',2,'O',1,'G',0)),0,'G',1,'O',2,'R') child_sheet_colour -- we need the MAX because might be multiple children
			      FROM TABLE(v_delegation_detail_tbl) d
				  JOIN delegation dc ON dc.parent_sid = d.delegation_sid
				  JOIN sheet_with_last_action slac ON dc.app_sid = slac.app_sid AND dc.delegation_sid = slac.delegation_sid
				 WHERE slac.start_dtm < d.end_dtm AND slac.end_dtm > d.start_dtm
				 GROUP BY d.delegation_sid) csc
			  ON d.delegation_Sid = csc.delegation_sid
		  LEFT JOIN sheet_change_req sr ON d.sheet_id = sr.req_to_change_sheet_id AND (sr.active_sheet_id = d.parent_sheet_id OR d.parent_sheet_id = 0) AND processed_dtm IS NULL
	   ORDER BY parent_delegation_sid, delegation_sid, start_dtm, parent_sheet_id DESC;		-- Should it be some hierarchical query, we do insert delegation before/after and it relies on order by?

	OPEN out_users FOR
		SELECT du.delegation_sid, cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM delegation_user du
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE (du.delegation_sid, du.inherited_from_sid) IN (
			SELECT /*+CARDINALITY(ddt, 10000)*/ delegation_sid, delegation_sid
			  FROM TABLE(v_delegation_detail_tbl) ddt
			 UNION ALL
			SELECT /*+CARDINALITY(ddt, 10000)*/ parent_delegation_sid, parent_delegation_sid
			  FROM TABLE(v_delegation_detail_tbl) ddt
			 WHERE delegated_by_user = 0)
		 UNION
		SELECT /*+CARDINALITY(tu, 100000) CARDINALITY(cu, 100000) CARDINALITY(ut, 100000)*/
			   tu.delegation_sid, cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM TABLE(v_delegation_user_tbl) tu
		  JOIN csr_user cu ON tu.user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id;			 

	OPEN out_deleg_regions FOR
		SELECT dr.delegation_sid, dr.region_sid, dr.mandatory, dr.description, dr.pos, dr.aggregate_to_region_sid, dr.visibility
		  FROM v$delegation_region dr
		 WHERE dr.delegation_sid IN (SELECT DISTINCT delegation_sid FROM TABLE(v_delegation_detail_tbl))
		   AND (in_region_sid IS NULL
				OR region_sid IN (
					SELECT region_sid FROM region START WITH region_sid = in_region_sid CONNECT BY PRIOR region_sid = parent_sid
				)
			)
		 ORDER BY dr.delegation_sid, dr.description;
END;

-- Looks like it's only used by GreenPrint client code, which is all redundant (client no longer exists).
PROCEDURE GetMyVarianceCounts(
	out_variance_counts		OUT	SYS_REFCURSOR
)
AS
	v_count number(10);
BEGIN
	OPEN out_variance_counts FOR
		SELECT sv.sheet_id, count(*) cnt
		  FROM sheet_value sv
		  JOIN temp_delegation_detail tdd ON sv.sheet_id = tdd.sheet_id
		 WHERE sv.var_expl_note IS NOT NULL
		 GROUP BY sv.sheet_id;
END;

PROCEDURE GetDelegationsForSheetEditor(
	in_start_dtm					IN	delegation.start_dtm%TYPE,
	in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_from_level					IN	NUMBER,
	in_to_level						IN	NUMBER,
	in_delegation_name_match		IN	VARCHAR2,
	in_delegation_name				IN	delegation.name%TYPE,
	in_delegation_user_sid			IN	delegation_user.user_sid%TYPE,
	in_root_region_sid				IN	delegation_region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	--Get all the non master delegation data and place into temp table
	INSERT INTO tmp_deleg_search (app_sid, delegation_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id, editing_url, root_delegation_sid, lvl, max_lvl)
	SELECT d.app_sid, d.delegation_sid, d.name, d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id, d.editing_url, d.root_delegation_sid, d.lvl, maxes.max_lvl
	  FROM (
		SELECT app_sid, delegation_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id, editing_url,
			   CONNECT_BY_ROOT delegation_sid root_delegation_sid, level lvl, rownum rn
		  FROM delegation
		 START WITH app_sid = parent_sid
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 ORDER SIBLINGS BY LOWER(name), start_dtm, end_dtm
			) d
		  JOIN (
			SELECT root_delegation_sid, MAX(lvl) max_lvl
			  FROM (
				SELECT level lvl, CONNECT_BY_ROOT delegation_sid root_delegation_sid
				  FROM delegation
				 START WITH app_sid = parent_sid
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
				 ORDER SIBLINGS BY LOWER(name), start_dtm, end_dtm
				) GROUP BY root_delegation_sid
			) maxes ON d.root_delegation_sid = maxes.root_delegation_sid
		  LEFT JOIN MASTER_DELEG mg ON mg.delegation_sid = d.delegation_sid
         WHERE mg.app_sid is null
         ORDER BY rn;

	--User filter
	IF in_delegation_user_sid IS NOT NULL THEN
		DELETE FROM tmp_deleg_search
		 WHERE NOT EXISTS(
			SELECT *
			  FROM tmp_deleg_search ts
			  JOIN delegation_user du on du.delegation_sid = ts.delegation_sid AND du.user_sid = in_delegation_user_sid AND du.inherited_from_sid = ts.delegation_sid
			 WHERE ts.delegation_sid = tmp_deleg_search.delegation_sid			  
			);
    END IF;

	--Region filter
	IF in_root_region_sid IS NOT NULL THEN
		DELETE FROM tmp_deleg_search WHERE NOT EXISTS(
			SELECT *
			  FROM tmp_deleg_search ts
			  JOIN delegation_region dr ON dr.delegation_sid = ts.delegation_sid
			  JOIN (
				SELECT region_sid
				  FROM region
				 START WITH region_sid = in_root_region_sid
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				) r ON r.region_sid = dr.region_sid
			 WHERE ts.delegation_sid = tmp_deleg_search.delegation_sid
			);
	END IF;

	--Misc filter
	DELETE FROM tmp_deleg_search
	 WHERE NOT EXISTS(
		SELECT * from tmp_deleg_search ts
		 WHERE (in_start_dtm IS NULL OR end_dtm > in_start_dtm)
	       AND (in_end_dtm IS NULL OR start_dtm < in_end_dtm)
		   AND (in_from_level IS NULL OR lvl >= in_from_level)
		   AND (in_to_level IS NULL OR lvl <= in_to_level)
		   AND (in_delegation_name IS NULL OR
			   (in_delegation_name_match = 'begins' AND LOWER(name) LIKE REPLACE(LOWER(in_delegation_name), '\', '\\')||'%' ESCAPE '\') OR --'
			   (in_delegation_name_match = 'contains' AND LOWER(name) LIKE '%'||REPLACE(LOWER(in_delegation_name), '\', '\\')||'%' ESCAPE '\')) --'
		   AND ts.delegation_sid = tmp_deleg_search.delegation_sid
		);

	--Output data
	OPEN out_cur FOR
		SELECT app_sid, delegation_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id, editing_url, root_delegation_sid, lvl, max_lvl
		  FROM tmp_deleg_search;

	OPEN out_regions_cur FOR
		SELECT ts.app_sid, ts.delegation_sid, ts.name, ts.start_dtm, ts.end_dtm, ts.period_set_id, ts.period_interval_id,
		       ts.editing_url, ts.root_delegation_sid, ts.lvl, ts.max_lvl, dr.region_sid, dr.description
		  FROM tmp_deleg_search ts
		  JOIN v$delegation_region dr ON dr.delegation_sid = ts.delegation_sid;
END;

PROCEDURE GetSheetsForSheetEditor(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t 								security.T_SID_TABLE;
BEGIN
 	t := security_pkg.SidArrayToTable(in_delegation_sids);

	OPEN out_cur FOR
		SELECT count(d.delegation_sid) delegations, d.lvl, s.start_dtm, s.end_dtm
		  FROM (SELECT delegation_sid, name, description, start_dtm, end_dtm, period_set_id, period_interval_id, editing_url, level lvl
  				  FROM v$delegation_hierarchical 
  				  	   START WITH app_sid = parent_sid 
  				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d,
			   TABLE(securableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
					 	securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Delegations'),
			   			security_pkg.PERMISSION_WRITE)) v,
			   sheet s
		 WHERE s.delegation_sid = v.sid_id
		   AND s.delegation_sid IN (SELECT column_value FROM TABLE(t))
		   AND d.delegation_sid = v.sid_id
		   AND s.delegation_sid = d.delegation_sid
		 GROUP BY d.lvl, s.start_dtm, s.end_dtm
		 ORDER BY d.lvl, s.start_dtm, s.end_dtm;
END;

PROCEDURE SetSheetDates(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_reminder_dtm					IN	sheet.reminder_dtm%TYPE,
	in_submission_dtm				IN	sheet.submission_dtm%TYPE,
	out_affected					OUT	NUMBER
)
AS
	t 								security.T_SID_TABLE;
BEGIN
 	t := security_pkg.SidArrayToTable(in_delegation_sids);

	UPDATE sheet
	   SET reminder_dtm = NVL(in_reminder_dtm, reminder_dtm),
	   	   submission_dtm = NVL(in_submission_dtm, submission_dtm)
	 WHERE sheet_id IN (
			SELECT s.sheet_id
			  FROM (SELECT delegation_sid, level lvl
	  				  FROM delegation
	  				  	   START WITH app_sid = parent_sid
	  				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d,
				   TABLE(securableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), t, security_pkg.PERMISSION_WRITE)) v,
				   sheet s
			 WHERE s.delegation_sid = v.sid_id
			   AND d.delegation_sid = v.sid_id
			   AND s.delegation_sid = d.delegation_sid
			   AND d.lvl = in_level
			   AND s.start_dtm = in_start_dtm
			   AND s.end_dtm = in_end_dtm);

	out_affected := SQL%ROWCOUNT;
END;


PROCEDURE SetSheetVisibility(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_is_visible					IN  NUMBER,
	out_affected					OUT	NUMBER
)
AS
	t 								security.T_SID_TABLE;
BEGIN
 	t := security_pkg.SidArrayToTable(in_delegation_sids);

	UPDATE sheet
	   SET is_visible = in_is_visible
	 WHERE sheet_id IN (
			SELECT s.sheet_id
			  FROM (SELECT delegation_sid, level lvl
	  				  FROM delegation
	  				  	   START WITH app_sid = parent_sid
	  				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d,
				   TABLE(securableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), t, security_pkg.PERMISSION_WRITE)) v,
				   sheet s
			 WHERE s.delegation_sid = v.sid_id
			   AND d.delegation_sid = v.sid_id
			   AND s.delegation_sid = d.delegation_sid
			   AND d.lvl = in_level
			   AND s.start_dtm = in_start_dtm
			   AND s.end_dtm = in_end_dtm);

	out_affected := SQL%ROWCOUNT;
END;

PROCEDURE SetSheetReadOnly(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_is_read_only					IN  NUMBER,
	out_affected					OUT	NUMBER
)
AS
	t 								security.T_SID_TABLE;
BEGIN
 	t := security_pkg.SidArrayToTable(in_delegation_sids);

	UPDATE sheet
	   SET is_read_only = in_is_read_only
	 WHERE sheet_id IN (
			SELECT s.sheet_id
			  FROM (SELECT delegation_sid, level lvl
	  				  FROM delegation
	  				  	   START WITH app_sid = parent_sid
	  				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d,
				   TABLE(securableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), t, security_pkg.PERMISSION_WRITE)) v,
				   sheet s
			 WHERE s.delegation_sid = v.sid_id
			   AND d.delegation_sid = v.sid_id
			   AND s.delegation_sid = d.delegation_sid
			   AND d.lvl = in_level
			   AND s.start_dtm = in_start_dtm
			   AND s.end_dtm = in_end_dtm);

	out_affected := SQL%ROWCOUNT;
END;

PROCEDURE SetSheetResendAlerts(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_resend_reminder				IN	NUMBER DEFAULT 0,
	in_resend_overdue				IN	NUMBER DEFAULT 0,
	out_affected					OUT	NUMBER
)
AS
	t								security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_delegation_sids);

	UPDATE sheet_alert
	   SET reminder_sent_dtm = (CASE in_resend_reminder WHEN 1 THEN null ELSE reminder_sent_dtm END),
		   overdue_sent_dtm = (CASE in_resend_overdue WHEN 1 THEN null ELSE overdue_sent_dtm END)
	 WHERE sheet_id IN (
			SELECT s.sheet_id
			  FROM (SELECT delegation_sid, level lvl
					  FROM delegation
						   START WITH app_sid = parent_sid
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d,
				   TABLE(securableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), t, security_pkg.PERMISSION_WRITE)) v,
				   sheet s
			 WHERE s.delegation_sid = v.sid_id
			   AND d.delegation_sid = v.sid_id
			   AND s.delegation_sid = d.delegation_sid
			   AND d.lvl = in_level
			   AND s.start_dtm = in_start_dtm
			   AND s.end_dtm = in_end_dtm
	);

	out_affected := SQL%ROWCOUNT;
END;

PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicator_list	IN	VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.name, di.description, i.lookup_key, m.name measure_name,
			   m.description measure_description, m.measure_sid, i.gri, i.multiplier,
			   NVL(i.scale, m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask,
			   i.active, i.scale actual_scale, i.format_mask actual_format_mask,
			   i.calc_xml, 
			   NVL(i.divisibility, m.divisibility) divisibility, i.start_month,
			   CASE
				   WHEN i.measure_sid IS NULL THEN 'Category'
				   WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
				   WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
				   ELSE 'Indicator'
			   END node_type, ind_type,
			   i.target_direction, i.last_modified_dtm, EXTRACT(info_xml,'/').getClobVal() info_xml,
			   i.parent_sid, di.pos
		  FROM v$delegation_ind di, ind i, measure m, TABLE(Utils_Pkg.SplitString(in_indicator_list,','))l
		 WHERE i.measure_sid = m.measure_sid(+)
		   AND l.item = i.ind_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ)=1
		   AND di.ind_sid = i.ind_sid
		   AND di.delegation_sid = in_delegation_sid
		 ORDER BY l.pos;
END;

PROCEDURE GetRegionsForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_region_list	IN	VARCHAR2,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, name, dr.description, active, r.pos, 'Region' node_type, aggregate_to_region_sid,
			   r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM TABLE(Utils_Pkg.SplitString(in_region_list,',')) l, region r, v$delegation_region dr
		 WHERE l.item = r.region_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ) = 1
		   AND dr.region_sid = r.region_sid
		   AND dr.delegation_sid = in_delegation_sid
		 ORDER BY l.POS;
END;

-- return summary info about sheets that exist for a delegation
PROCEDURE GetSheets(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	csr_data_pkg.T_SHEET_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
        WITH postit_periods AS (
            SELECT DISTINCT dc.start_dtm, dc.end_dtm
              FROM (
                SELECT delegation_sid
                  FROM delegation
                 START WITH delegation_sid = in_delegation_sid
                CONNECT BY PRIOR delegation_sid = parent_sid
              ) d
              JOIN delegation_comment dc ON d.delegation_sid = dc.delegation_sid
		)
		SELECT cu.full_name last_action_full_name, sla.start_dtm, sla.end_dtm, d.period_set_id,
		 	   d.period_interval_id, sa.description action_description, sla.sheet_id,
			   sla.last_action_dtm, sla.submission_dtm, sla.reminder_dtm, sla.status,
			   CASE WHEN pp.start_dtm IS NULL THEN 0 ELSE 1 END has_postits,
			   sla.is_visible, sla.is_read_only, sla.percent_complete,
			   ut.account_enabled active
		  FROM sheet_with_last_action sla
		  JOIN sheet_action sa ON sla.last_action_id = sa.sheet_action_id
		  JOIN delegation d ON d.delegation_sid = sla.delegation_sid
		  JOIN csr_user cu ON cu.csr_user_sid = last_action_from_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
          LEFT JOIN postit_periods pp ON sla.start_dtm = pp.start_dtm AND sla.end_dtm = pp.end_dtm
		 WHERE d.delegation_sid = in_delegation_sid
		 ORDER BY sla.start_dtm;
END;

PROCEDURE GetSheetsForTree(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
				START WITH delegation_sid = in_delegation_sid
				CONNECT BY parent_sid = PRIOR delegation_sid
			);
END;

-- no security
PROCEDURE GetSheetIds(
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = in_delegation_sid;
END;

-- Get the sheet ids within a given year
PROCEDURE GetSheetIds(
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	in_year				IN  NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = in_delegation_sid
		   AND (in_year IS NULL OR EXTRACT(YEAR FROM start_dtm) = in_year)
	  ORDER BY start_dtm;
END;

PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_send_alerts					IN	NUMBER DEFAULT 1
)
AS
	v_cur							SYS_REFCURSOR;
BEGIN
	CreateSheetsForDelegation(in_delegation_sid, 0, in_send_alerts, v_cur);
END;

PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CreateSheetsForDelegation(in_delegation_sid, 0, in_send_alerts, out_cur);
END;

PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_at_least_one					IN	NUMBER DEFAULT 0,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CreateSheetsForDelegation(in_delegation_sid, in_at_least_one, SYSDATE, in_send_alerts, out_cur);
END;

PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_at_least_one					IN	NUMBER DEFAULT 0,
	in_date_to						IN 	DATE DEFAULT SYSDATE,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_delegation_start_dtm			DATE;
	v_delegation_end_dtm			DATE;
	v_schedule_end_dtm				DATE;
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
	v_create_sheets_at_period_end	customer.create_sheets_at_period_end%TYPE;
	v_start_dtm 					DATE;
	v_end_dtm 						DATE;
	v_val_id						val.val_id%TYPE;
	v_creation_dtm					DATE;
	v_submission_dtm				DATE;
	v_sheet_id						sheet.sheet_id%TYPE;
	v_copy_vals_to_new_sheets 		customer.copy_vals_to_new_sheets%TYPE;
	v_allow_multiperiod_forms		customer.allow_multiperiod_forms%TYPE;
	v_sheet_ids						security.T_SID_TABLE := security.T_SID_TABLE();
	v_sheet_count					NUMBER;
BEGIN
	SELECT create_sheets_at_period_end, copy_vals_to_new_sheets, allow_multiperiod_forms
	  INTO v_create_sheets_at_period_end, v_copy_vals_to_new_sheets, v_allow_multiperiod_forms
	  FROM customer
	 WHERE app_sid = (
		SELECT app_sid FROM delegation WHERE delegation_sid = in_delegation_sid
	 );

	SELECT start_dtm, end_dtm, period_set_id, period_interval_id
	  INTO v_delegation_start_dtm, v_delegation_end_dtm, v_period_set_id, v_period_interval_id
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	DELETE FROM temp_dates; -- just in case
	
	v_start_dtm := v_delegation_start_dtm;
	WHILE v_start_dtm < v_delegation_end_dtm LOOP
		v_end_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_start_dtm, 1);
		--security_pkg.debugmsg('start = '||v_start_dtm||' end = '||v_end_dtm||', int = '||v_period_interval_id);

		-- This is vastly quicker to join to than TABLE OF DATE
		INSERT INTO temp_dates (column_value, eff_date)
		SELECT v_start_dtm, 
				CASE WHEN sds.creation_dtm IS NOT NULL THEN sds.creation_dtm
					 WHEN v_create_sheets_at_period_end = 1 THEN v_end_dtm
					 ELSE v_start_dtm
				END
		  FROM delegation d
		  LEFT JOIN sheet_date_schedule sds ON sds.app_sid = d.app_sid AND sds.delegation_date_schedule_id = d.delegation_date_schedule_id AND sds.start_dtm = v_start_dtm
		 WHERE d.delegation_sid = in_delegation_sid;

		v_start_dtm := v_end_dtm;
	END LOOP;

	FOR r IN (
		 SELECT d.delegation_sid, s.min_sheet_start_dtm, d.schedule_xml, d.submission_offset, s.sheets,
				(SELECT COUNT(*) FROM delegation WHERE parent_sid = d.delegation_sid) child_count
		   FROM (SELECT d.app_sid, d.delegation_sid, MIN(CASE WHEN s.sheet_id IS NULL THEN t.column_value ELSE NULL END) min_sheet_start_dtm, COUNT(s.sheet_id) sheets
				   FROM delegation d
				  CROSS JOIN temp_dates t
				   LEFT JOIN sheet s ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid AND s.start_dtm = t.column_value
				  WHERE d.delegation_sid = in_delegation_sid
			      GROUP BY d.app_sid, d.delegation_sid, d.end_dtm
				 HAVING ( MAX(NVL(s.end_dtm, d.start_dtm)) < d.end_dtm -- delegations which need sheets creating
						  AND (MIN(CASE WHEN s.sheet_id IS NULL THEN t.eff_date ELSE NULL END) <= in_date_to OR v_allow_multiperiod_forms = 1)) OR	-- min sheet creation dtm <= in_date_to
						(in_at_least_one = 1 AND COUNT(s.sheet_id) = 0) -- at least one sheet
				 ) s, delegation d
	       WHERE s.app_sid = d.app_sid
	         AND s.delegation_sid = d.delegation_sid
	) LOOP
		v_start_dtm := r.min_sheet_start_dtm;
		v_sheet_count := r.sheets;
		WHILE (v_start_dtm < v_delegation_end_dtm) LOOP
			v_end_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_start_dtm, 1);

			SELECT eff_date
			  INTO v_creation_dtm
			  FROM temp_dates
			 WHERE column_value = v_start_dtm;

			IF v_creation_dtm <= in_date_to OR (v_sheet_count = 0 AND in_at_least_one = 1) OR v_allow_multiperiod_forms = 1 THEN
				-- if present use fixed due date, otherwise use date generated from schedule_xml
				SELECT sds.submission_dtm
				  INTO v_submission_dtm
				  FROM delegation d
				  LEFT JOIN sheet_date_schedule sds ON sds.app_sid = d.app_sid AND sds.delegation_date_schedule_id = d.delegation_date_schedule_id AND sds.start_dtm = v_start_dtm
				 WHERE d.delegation_sid = in_delegation_sid;
	
				IF v_submission_dtm IS NULL THEN		
					-- figure out the scheduled submission date
					IF r.schedule_xml IS NOT NULL THEN

						IF v_schedule_end_dtm IS NULL THEN
							v_schedule_end_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_delegation_end_dtm, 1);
						END IF;

						delegation_pkg.GetDateFromScheduleXml(v_start_dtm, v_end_dtm, v_schedule_end_dtm, r.schedule_xml, 
							v_period_set_id, v_period_interval_id, v_submission_dtm);
						IF v_submission_dtm IS NULL THEN
							RAISE_APPLICATION_ERROR(-20001, 'No submission date found for period when creating sheet for delegation '||r.delegation_sid);
						END IF;
					ELSE
						v_submission_dtm := v_end_dtm + r.submission_offset;
					END IF;
				END IF;
	
				sheet_pkg.CreateSheet(SYS_CONTEXT('SECURITY', 'ACT'), r.delegation_sid, v_start_dtm, v_submission_dtm, v_sheet_id, v_end_dtm);
				IF v_sheet_id IS NULL THEN
					EXIT;
				END IF;
				
				v_sheet_count := v_sheet_count + 1;
				v_sheet_ids.extend(1);
				v_sheet_ids(v_sheet_ids.count) := v_sheet_id;

				IF v_copy_vals_to_new_sheets = 1 AND r.child_count = 0 THEN
					-- copy values over if it's the leaf
					FOR sr IN (
						SELECT v.val_id, s.sheet_Id, s.start_dtm, s.end_dtm, di.ind_sid, dr.region_sid, v.val_number, v.entry_measure_conversion_id, v.entry_val_number, v.note
						  FROM sheet s
						  JOIN delegation d ON s.delegation_sid = d.delegation_sid AND s.app_sid = d.app_sid
						  JOIN delegation_ind di ON d.delegation_sid = di.delegation_sid AND d.app_sid = di.app_sid
						  JOIN ind i ON di.ind_sid = i.ind_sid AND di.app_sid = i.app_sid
						  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
						  JOIN region r on dr.region_sid = r.region_sid AND dr.app_sid = r.app_sid
						  JOIN val v
							ON s.start_dtm < v.period_end_dtm  -- in theory we should take exact matches on dates unless ind_sid is indivisible
						   AND s.end_dtm > v.period_start_dtm
						   AND i.ind_sid = v.ind_sid
						   AND r.region_sid = v.region_sid
						 WHERE s.sheet_id = v_sheet_id
					)
					LOOP
						delegation_pkg.SaveValue(
							in_act_id				=> security_pkg.getact,
							in_sheet_id				=> sr.sheet_id,
							in_ind_sid				=> sr.ind_sid,
							in_region_sid			=> sr.region_sid,
							in_val_number			=> sr.val_number,
							in_entry_conversion_id	=> sr.entry_measure_conversion_id,
							in_entry_val_number		=> sr.entry_val_number,
							in_note					=> sr.note,
							in_reason				=> 'Copied from val_id '||sr.val_id,
							in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
							in_file_count			=> 0,
							in_flag					=> null,
							in_write_history		=> 1,
							out_val_id				=> v_val_id);
					END LOOP;
				END IF;
				
				IF in_send_alerts = 1 THEN
					sheet_pkg.RaiseSheetCreatedAlert(v_sheet_id); -- Exits above if sheet_id is null
				END IF;
			END IF;

			v_start_dtm := v_end_dtm;
		END LOOP;
	END LOOP;

	OPEN out_cur FOR
		SELECT s.sheet_id, s.start_dtm, s.end_dtm, s.submission_dtm, s.reminder_dtm, d.editing_url
		  FROM TABLE(v_sheet_ids) sid, delegation d, sheet s
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND s.sheet_id = sid.column_value
		   AND d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
		 ORDER BY s.start_dtm;
END;

-- Called from a scheduled job to roll forward each month and create sheets
PROCEDURE CreateNewSheets
AS
BEGIN
	user_pkg.LogonAdmin(timeout => 86400);
	-- ensure we've rollforwarded first (the indicator_pkg.RollForward fn with no params excludes sites where we're copying values to new sheets)
	FOR r IN (SELECT app_sid
				FROM ind
			   WHERE roll_forward = 1
			   GROUP BY app_sid
		   INTERSECT
			  SELECT app_sid
			    FROM customer
			   WHERE copy_vals_to_new_sheets = 1) LOOP
		security_pkg.SetApp(r.app_sid);
		indicator_pkg.RollForward(null);
		security_pkg.SetApp(null);
		COMMIT;
	END LOOP;

	-- now create new sheets
	FOR r IN (
		SELECT /*+ALL_ROWS*/ app_sid, delegation_sid
		  FROM (SELECT d.app_sid, d.delegation_sid
				  FROM sheet s, delegation d, customer c
				 WHERE s.app_sid(+) = d.app_sid
				   AND s.delegation_sid(+) = d.delegation_sid
				   AND d.app_sid = c.app_sid
				   AND d.app_sid = d.parent_sid	-- do top level delegations first
			     GROUP BY d.app_sid, d.delegation_sid, d.end_dtm
				HAVING MAX(NVL(s.end_dtm,d.start_dtm)) < d.end_dtm
				   -- Commented out, it's now possible to define specific sheet creation dates (stored in sheet_date_schedule table).
				   -- If specific sheet creation dates have been specified, the below AND statement cannot be used.
				   -- It's ok to leave this commented out because delegation_pkg.CreateSheetsForDelegation proc won't create sheets that should not be created anyway
				   --AND MAX(ADD_MONTHS(NVL(s.end_dtm, d.start_dtm), c.create_sheets_at_period_end * DECODE(d.interval, 'y', 12, 'h', 6, 'q', 3, 'm', 1))) <= SYSDATE
				)
		 GROUP BY app_sid, delegation_sid
		 ORDER BY app_sid
	)
	LOOP
		security_pkg.SetApp(r.app_sid);
		FOR s IN (SELECT delegation_sid
					FROM delegation
				   START WITH delegation_sid = r.delegation_sid
				 CONNECT BY PRIOR delegation_sid = parent_sid
		)
		LOOP
			BEGIN
				delegation_pkg.CreateSheetsForDelegation(s.delegation_sid);
			EXCEPTION
				WHEN OTHERS THEN
					-- Write a log message which gets picked up and emailed.
					-- We need to carry on so that sheets get created for other hosts / delegations
					-- (the cause is usually broken schedule xml).
					aspen2.error_pkg.LogError('Creating sheets for the delegation with sid ' ||
						r.delegation_sid || ' failed with ' || SQLERRM);
			END;
		END LOOP;

		security_pkg.SetApp(null);

		COMMIT;
	END LOOP;
	
	user_pkg.LogOff(security_pkg.GetAct);
END;

PROCEDURE GetTrashedItems(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_trash_sid		security_pkg.T_SID_ID;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	-- all the other SPs like this take the ACT, so rather than mixing in_act_id
	-- with security_pkg.getApp, we just pull the app here.
	SELECT app_sid
	  INTO v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	v_trash_sid := securableobject_pkg.getsidfrompath(in_act_id, v_app_sid, 'Trash');

	OPEN out_cur FOR
		-- first indicators
		SELECT ind_sid sid
		  FROM DELEGATION_IND
		 WHERE ind_sid IN (
			SELECT root_ind_sid
			  FROM (
				-- work up the ind tree starting with the indicators in the delegation
				SELECT parent_sid, CONNECT_BY_ROOT ind_sid root_ind_sid
				  FROM ind
				 START WITH ind_sid IN (
					SELECT ind_sid
					  FROM delegation_ind di
					 WHERE delegation_sid = in_delegation_sid
				 )
				CONNECT BY PRIOR parent_sid = ind_sid
			 )
			 WHERE parent_sid = v_trash_sid
		 )
		UNION
		-- and now regions
		SELECT region_sid sid
		  FROM DELEGATION_region
		 WHERE region_sid IN (
			SELECT root_region_sid
			  FROM (
				-- work up the region tree starting with the regions in the delegation
				SELECT parent_sid, CONNECT_BY_ROOT region_sid root_region_sid
				  FROM region
				 START WITH region_sid IN (
					SELECT region_sid
					  FROM delegation_region dr
					 WHERE delegation_sid = in_delegation_sid
				 )
				CONNECT BY PRIOR parent_sid = region_sid
			 )
			 WHERE parent_sid = v_trash_sid
		 );
END;

-- legacy stuff - new delegation/sheets2 code ignore this
PROCEDURE GetDelegationBlockers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_id, i.description ind_description, r.description region_description,
		 	   reason, i.ind_sid, r.region_sid, bl.section_key
		  FROM (SELECT ir.sheet_id, ir.ind_sid, ir.region_sid, section_key,
				   	   'This value must be entered before you can submit' reason
			 	  FROM (SELECT s.sheet_id, di.ind_sid, region_sid
						  FROM delegation_ind di,
							   delegation_region dr,
							   delegation d,
							   sheet s,
							   ind
					     WHERE di.delegation_sid = in_delegation_sid
						   AND dr.delegation_sid = in_delegation_sid
						   AND dr.visibility = 'SHOW'
						   AND d.delegation_sid = in_delegation_sid
						   AND (   (di.mandatory = 1 AND d.allocate_users_to = 'region')
								OR (dr.mandatory = 1 AND d.allocate_users_to = 'indicator')
							   )
						   AND di.ind_sid = ind.ind_sid
						   AND ind.ind_type IN (csr_data_pkg.IND_TYPE_NORMAL)
						   AND ind.measure_sid IS NOT NULL
						   AND s.delegation_sid = d.delegation_sid
						 MINUS
		        		SELECT DISTINCT s.sheet_id, sv.ind_sid, sv.region_sid
	             	  	 FROM sheet_value sv, ind i, measure m, sheet s
	                 	WHERE s.delegation_sid = in_delegation_sid AND s.sheet_id = sv.sheet_id AND
	                          sv.ind_sid = i.ind_sid and i.measure_sid = m.measure_sid and
						      ((trim(m.custom_field) = '|' and sv.note is not null) or
							   val_number is not null)) ir,
					  delegation_ind di
			 	WHERE ir.ind_sid = di.ind_sid
				  AND delegation_sid = in_delegation_sid
			    UNION
				-- if a number has been filled in, then it must have a note
				SELECT s.sheet_id, sv.ind_sid, sv.region_sid, di.section_key,
					  'An explanatory note must be provided for all values' reason
				  FROM sheet_value sv,
					   delegation_ind di,
					   delegation d, sheet s
			     WHERE sv.sheet_id = s.sheet_id
				   AND s.delegation_sid = d.delegation_sid
				   AND sv.val_number IS NOT NULL
				   AND sv.note IS NULL
				   AND d.delegation_sid = in_delegation_sid
				   AND d.is_note_mandatory = 1
				   AND di.ind_sid = sv.ind_sid
			 	 UNION
				-- alerts where there is no explanatory note
				SELECT s.sheet_id, sv.ind_sid, sv.region_sid, di.section_key,
					   'An explanatory note must be provided because the number differs significantly from a previous figure' reason
				  FROM sheet_value sv,
					   delegation_ind di, sheet s
			 	 WHERE sv.alert IS NOT NULL
				   AND sv.note IS NULL
				   AND sv.sheet_id = s.sheet_id
				   AND s.delegation_sid = di.delegation_sid
				   AND di.ind_sid = sv.ind_sid
				   AND di.delegation_sid = in_delegation_sid) bl,
			  v$delegation_ind i, v$delegation_region r, ind ii
		WHERE i.delegation_sid =in_delegation_sid
		  AND i.ind_sid = bl.ind_sid
		  AND r.region_sid = bl.region_sid
		  AND i.delegation_sid = in_delegation_sid
		  AND r.delegation_Sid = in_delegation_sid
		  AND i.ind_sid = ii.ind_sid
		  AND ii.ind_type = csr_data_pkg.IND_TYPE_NORMAL
		ORDER BY sheet_Id, section_key, i.description, r.description;
END;

-- =========================
-- general utility functions
-- =========================

-- fully delegated meaning everything to one sub delegation
FUNCTION IsFullyDelegated(
	in_delegation_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_region_sid					security_pkg.T_SID_ID;
	v_ind_sid						security_pkg.T_SID_ID;
	v_num							NUMBER(10);
	v_not_found						BOOLEAN;
	CURSOR c IS
	  SELECT region_sid, di.ind_sid
	    FROM delegation_region dr
        JOIN delegation_ind di ON di.app_sid = dr.app_sid AND di.delegation_sid = dr.delegation_sid
        JOIN ind i ON i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
        LEFT JOIN delegation_grid dg ON dg.app_sid = i.app_sid AND dg.ind_sid = i.ind_sid
        LEFT JOIN delegation_plugin dp ON dp.app_sid = i.app_sid AND dp.ind_sid = i.ind_sid
	   WHERE dr.delegation_sid = in_delegation_sid
         AND (
          i.measure_sid IS NOT NULL
          OR
          dg.ind_sid IS NOT NULL
          OR
          dp.ind_sid IS NOT NULL
		) -- we dont' care about cross-headers (i.e. container nodes with no UoM), but we do care about delegations with just grids on them
		 AND NOT (
			di.meta_role IS NOT NULL
			AND
			di.visibility = 'HIDE'
		) -- ignore hidden user performance score inds, they are usually added to the top level delegation only
	 MINUS
	  SELECT aggregate_to_region_sid, ind_sid
	    FROM delegation_region dr, delegation_ind di, delegation d
	   WHERE dr.app_sid = di.app_sid
	     AND dr.app_sid = d.app_sid
	     AND di.app_sid = d.app_sid
	     AND dr.delegation_sid = d.delegation_sid
	     AND di.delegation_sid = d.delegation_sid
		 AND d.parent_sid = in_delegation_sid;
BEGIN
	OPEN c;
	FETCH c INTO v_region_sid, v_ind_sid;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		-- do some more checks
		SELECT COUNT(*) INTO v_num
		  FROM delegation d
		 WHERE d.parent_sid = in_delegation_sid;
		IF v_num > 1 THEN
			RETURN csr_data_pkg.FULLY_DELEGATED_TO_MANY; -- more than 1 sub delegation
		ELSIF v_num = 1 THEN
			RETURN csr_data_pkg.FULLY_DELEGATED_TO_ONE; -- everything delegated to one person
		ELSE
			RETURN csr_data_pkg.NOT_FULLY_DELEGATED; -- No sub delegations so top level delegation
		END IF;
	ELSE
		RETURN csr_data_pkg.NOT_FULLY_DELEGATED;
	END IF;
END;

-- This is buggy: if you ask it for 1 region you'll get 2
-- not yet fixed, because I'm not sure what else will break if it is (probably needs all callers bumping up by 1)
FUNCTION ConcatDelegationRegions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_regions			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT dr.description
		  FROM v$delegation_region dr, region r
		 WHERE delegation_sid = in_delegation_sid
		   AND dr.app_sid = r.app_sid AND dr.region_sid = r.region_sid
		 ORDER BY dr.description
	)
	LOOP
		-- if we've shown enough already but we're still in the loop then
		-- there's more to come, so shove on some dots and bail out.
		-- Do the same if we're about to run out of string buffer
		IF LENGTHB(v_item || v_sep || r.description)<1020 AND v_cnt <= in_max_regions THEN
			v_item := v_item || v_sep || r.description;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegRegionsByUserLang(
	in_delegation_sid	IN security_pkg.T_SID_ID,
	in_csr_user_sid		IN security_pkg.T_SID_ID,
	in_max_regions		IN  NUMBER DEFAULT 10
) RETURN VARCHAR2
IS
	v_lang	security.user_table.language%TYPE;
	v_item	VARCHAR2(1024) := '';
	v_sep	VARCHAR2(2) := '';
	v_cnt	NUMBER(10) := 0;
BEGIN
	SELECT NVL(language, 'en')
	  INTO v_lang
	  FROM security.user_table
	 WHERE sid_id = in_csr_user_sid;

	FOR r IN (
		SELECT rd.description
		  FROM delegation_region dr
		  JOIN region_description rd ON (dr.app_sid = rd.app_sid AND dr.region_sid = rd.region_sid)
		 WHERE dr.delegation_sid = in_delegation_sid
		   AND rd.lang = v_lang
	)
	LOOP
		--Same logic as delegation_pkg.ConcatDelegationRegions
		--If buffer or max_regions is exceeded, add some dots and exit
		IF LENGTHB(v_item || v_sep || r.description)<1020 AND v_cnt <= in_max_regions THEN
			v_item := v_item || v_sep || r.description;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;

	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegationIndicators(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_inds				IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT di.description
		  FROM v$delegation_ind di, ind i
		 WHERE delegation_sid = in_delegation_sid
		   AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
		 ORDER BY di.description
	)
	LOOP
		-- if we've shown enough already but we're still in the loop then
		-- there's more to come, so shove on some dots and bail out.
		-- Do the same if we're about to run out of string buffer
		IF LENGTHB(v_item || v_sep || r.description)<1020 AND v_cnt <= in_max_inds THEN
			v_item := v_item || v_sep || r.description;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegationUsers(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT cu.full_name
		  FROM delegation_user du
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		 WHERE du.delegation_sid = in_delegation_sid
		   AND du.inherited_from_sid = in_delegation_sid
		 UNION
		SELECT cu.full_name
		  FROM delegation_role dlr
		  JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN region r ON dr.region_sid = r.region_sid AND dr.app_Sid = r.app_sid
		  JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND r.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND r.app_sid = rrm.app_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		 WHERE dlr.delegation_sid = in_delegation_sid
		   AND dlr.inherited_from_sid = in_delegation_sid
	)
	LOOP
		IF LENGTHB(v_item || v_sep || r.full_name)<1020 AND v_cnt < in_max_users THEN
			v_item := v_item || v_sep || r.full_name;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegationUserSids(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT du.user_sid
		  FROM delegation_user du
		 WHERE du.delegation_sid = in_delegation_sid
		   AND du.inherited_from_sid = in_delegation_sid
		 UNION
		 SELECT rrm.user_sid
		   FROM delegation_role dlr
		   JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		   JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid
		  WHERE dlr.delegation_sid = in_delegation_sid
		    AND dlr.inherited_from_sid = in_delegation_sid
	)
	LOOP
		IF LENGTHB(v_item || v_sep || r.user_sId)<1020 AND v_cnt <= in_max_users THEN
			v_item := v_item || v_sep || r.user_sid;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ',';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

-- Used by heinekenspm and socgen.
FUNCTION ConcatDelegationUserAndEmail(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
BEGIN
	RETURN ConcatDelegProviders(in_delegation_sid, in_max_users);
END;

FUNCTION ConcatDelegProviders(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT cu.full_name||' ('||cu.email||')' name_and_email
		  FROM delegation_user du
			JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		 WHERE du.delegation_sid = in_delegation_sid
		   AND du.inherited_from_sid = in_delegation_sid
		 UNION
		 SELECT cu.full_name||' ('||cu.email||')' name_and_email
		   FROM delegation_role dlr
			JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
			JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid
			JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  WHERE dlr.delegation_sid = in_delegation_sid
		    AND dlr.inherited_from_sid = in_delegation_sid
	)
	LOOP
		IF LENGTHB(v_item || v_sep || r.name_and_email)<1020 AND v_cnt <= in_max_users THEN
			v_item := v_item || v_sep || r.name_and_email;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ',';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegApprovers(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT cu.full_name||' ('||cu.email||')' name_and_email
		  FROM delegation_user du
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		  JOIN delegation d ON d.delegation_sid = in_delegation_sid AND d.app_sid = cu.app_sid
		  JOIN delegation pd ON pd.delegation_sid = d.parent_sid AND pd.app_sid = cu.app_sid
		 WHERE du.delegation_sid = pd.delegation_sid
		   AND du.inherited_from_sid = pd.delegation_sid
		 UNION
		 SELECT cu.full_name||' ('||cu.email||')' name_and_email
		   FROM delegation_role dlr
			JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
			JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND dr.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND dr.app_sid = rrm.app_sid
			JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
			JOIN delegation d ON d.delegation_sid = in_delegation_sid AND d.app_sid = cu.app_sid
			JOIN delegation pd ON pd.delegation_sid = d.parent_sid AND pd.app_sid = cu.app_sid
		  WHERE dlr.delegation_sid = pd.delegation_sid
		    AND dlr.inherited_from_sid = pd.delegation_sid
	)
	LOOP
		IF LENGTHB(v_item || v_sep || r.name_and_email)<1020 AND v_cnt <= in_max_users THEN
			v_item := v_item || v_sep || r.name_and_email;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ',';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

FUNCTION ConcatDelegationDelegators(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_delegators		IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item			VARCHAR2(1024) := '';
	v_sep			VARCHAR2(2) := '';
	v_cnt			NUMBER(10) := 0;
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	FOR r IN (
		SELECT cu.full_name
		  FROM delegation_user du
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid
		 WHERE du.delegation_sid = v_parent_sid
		   AND du.inherited_from_sid = v_parent_sid
		 UNION
		SELECT cu.full_name
		  FROM delegation d
		  JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
		  JOIN delegation_region dr ON dlr.delegation_sid = dr.delegation_sid AND dlr.app_sid = dr.app_sid
		  JOIN region r ON dr.region_sid = r.region_sid AND dr.app_sid = r.app_sid
		  JOIN region_role_member rrm ON dlr.role_sid = rrm.role_sid AND r.region_sid = rrm.region_sid AND dlr.app_sid = rrm.app_sid AND r.app_sid = rrm.app_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		 WHERE d.delegation_sid = v_parent_sid
		   AND dlr.inherited_from_sid = v_parent_sid
	)
	LOOP
		IF LENGTHB(v_item || v_sep || r.full_name)<1020 AND v_cnt <= in_max_delegators THEN
			v_item := v_item || v_sep || r.full_name;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

-- applies a user chain to a delegation, creating copies of the parent delegation if necessary
-- user chain is / delimited, with comma delimited for multiple users to one delegation
PROCEDURE ApplyChainToRegion(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_start_delegation_sid		IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_user_list				IN	VARCHAR2,
	in_replace_users_in_start	IN	NUMBER DEFAULT 1,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	CURSOR cd(in_delegation_sid	security_pkg.T_SID_ID) IS
	  	SELECT app_sid, name, description, period_set_id, period_interval_id, schedule_xml, note,
	  		   master_delegation_sid, grid_xml, editing_url, section_xml, start_dtm, end_dtm
          FROM v$delegation
         WHERE delegation_sid = in_delegation_sid;
    rd	cd%ROWTYPE;
    v_parent_delegation_sid	security_pkg.T_SID_ID;
    v_new_delegation_sid	security_pkg.T_SID_ID;
    v_count					BINARY_INTEGER := 0;
    v_exists				NUMBER(10);
    v_sheet_id				sheet.sheet_id%TYPE;
    v_end_dtm				sheet.end_dtm%TYPE;
    v_last_sheet_id			sheet.sheet_id%TYPE;
	v_delegation_sids		security.T_SID_TABLE := security.T_SID_TABLE();
	v_has_unmerged_scenario BOOLEAN;
	v_locked_app			BOOLEAN;
BEGIN
	v_has_unmerged_scenario := csr_data_pkg.HasUnmergedScenario;
	v_locked_app := FALSE;

	v_parent_delegation_sid := in_start_delegation_sid;
	FOR r IN (
		SELECT item, pos FROM TABLE ( CAST(utils_pkg.splitString(in_user_list,'/') AS T_SPLIT_TABLE))
	)
	LOOP
       	-- DBMS_OUTPUT.PUT_LINE('User sid '||r.item);
       	-- if it's the first one, we know it exists already since it's our starting point...
       	IF v_count = 0 THEN
			IF in_replace_users_in_start = 1 THEN
				-- this will zap any other users on this delegation
				delegation_pkg.SetUsers(in_act_id, v_parent_delegation_sid, r.item);
			ELSE
				-- if user isn't present, then add them in
				SELECT COUNT(*)
				  INTO v_exists
				  FROM delegation_user
				 WHERE user_sid = r.item
				   AND delegation_sid = v_parent_delegation_sid
				   AND inherited_from_sid = v_parent_delegation_sid;
				   
				IF v_exists = 0 THEN
					UNSEC_AddUser(in_act_id, v_parent_delegation_sid, r.item);
				END IF;
			END IF;
			-- if region isn't present, then add it in
			SELECT COUNT(*)
			  INTO v_exists
			  FROM delegation_region
			 WHERE region_sid = in_region_sid
			   AND delegation_sid = v_parent_delegation_sid;
			IF v_exists = 0 THEN
				INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility)
					SELECT v_parent_delegation_sid, region_sid, 0, 1, region_sid, 'SHOW'
					  FROM region
					 WHERE region_sid = in_region_sid;

				IF v_has_unmerged_scenario THEN
					IF NOT v_locked_app THEN
						csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
						v_locked_app := TRUE;
					END IF;
					MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
					USING (SELECT di.ind_sid, d.start_dtm start_dtm, d.end_dtm end_dtm
					  		 FROM delegation_ind di, delegation d
					  		WHERE di.delegation_sid = v_new_delegation_sid
					  		  AND d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid) d
					   ON (svcl.ind_sid = d.ind_sid)
					 WHEN MATCHED THEN
						UPDATE
						   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
							   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
					 WHEN NOT MATCHED THEN
						INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
						VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
				END IF;
			END IF;

			v_new_delegation_sid := v_parent_delegation_sid; -- we're re-using it
			-- DBMS_OUTPUT.PUT_LINE('using existing ('||v_parent_delegation_sid||')');
		ELSE
	        -- does a sub delegation exist for this region already?
			BEGIN
	            SELECT d.delegation_sid
	              INTO v_new_delegation_sid
	              FROM delegation_region dr, delegation d
	             WHERE dr.delegation_sid = d.delegation_sid
	               AND d.parent_sid = v_parent_delegation_sid
	               AND dr.region_sid = in_region_sid;
	            -- NB: this will zap any other users on this delegation
	       		delegation_pkg.SetUsers(in_act_id, v_new_delegation_sid, r.item);
				-- DBMS_OUTPUT.PUT_LINE('using existing ('||v_new_delegation_sid||')');
			EXCEPTION
	           	WHEN NO_DATA_FOUND THEN
					-- get delegation details about parent
			       	OPEN cd(v_parent_delegation_sid);
			        FETCH cd INTO rd;
			        CLOSE cd;

					-- create a delegation based on the parent
					delegation_pkg.CreateNonTopLevelDelegation(
						in_act_id				=> in_act_id,
						in_parent_sid			=> v_parent_delegation_sid,
						in_app_sid 				=> rd.app_sid,
						in_name					=> rd.name,
						in_regions_list			=> in_region_sid,
						in_user_sid_list		=> r.item,
						in_period_set_id		=> rd.period_set_id,
						in_period_interval_id	=> rd.period_interval_id,
						in_schedule_xml			=> rd.schedule_xml,
						in_note					=> rd.note,
						out_delegation_sid		=> v_new_delegation_sid
					);

	                -- NB: this will zap any other users on this delegation
                    delegation_pkg.SetUsers(in_act_id, v_new_delegation_sid, r.item);

                    -- manually update some fields
					UPDATE delegation
					   SET editing_url = rd.editing_url, section_xml = rd.section_xml,
						   grid_xml = rd.grid_xml, master_delegation_sid = rd.master_delegation_sid
					 WHERE delegation_sid = v_new_delegation_sid;

	                -- add indicators (we set the regions above)
					INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na)
	                	SELECT v_new_delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, allowed_na
	                      FROM delegation_ind
	                     WHERE delegation_sid = v_parent_delegation_sid;

					INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
	                	SELECT v_new_delegation_sid, ind_sid, lang, description
	                      FROM delegation_ind_description
	                     WHERE delegation_sid = v_parent_delegation_sid;

	                -- add calc jobs for the added indicators
					IF v_has_unmerged_scenario THEN
						IF NOT v_locked_app THEN
							csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
							v_locked_app := TRUE;
						END IF;
						MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
						USING (SELECT di.ind_sid, rd.start_dtm start_dtm, rd.end_dtm end_dtm
						  		 FROM delegation_ind di
						  		WHERE di.delegation_sid = v_new_delegation_sid) d
						   ON (svcl.ind_sid = d.ind_sid)
						 WHEN MATCHED THEN
							UPDATE
							   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
								   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
						 WHEN NOT MATCHED THEN
							INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
							VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
					END IF;

					-- insert some sheets
					v_last_sheet_id := null;
					FOR s IN (
						 SELECT sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm
						   FROM sheet
						  WHERE delegation_sid = v_parent_delegation_sid
					)
					LOOP
						sheet_pkg.CreateSheet(in_act_id, v_new_delegation_sid, s.start_dtm, s.submission_dtm, v_sheet_id, v_end_dtm);
						v_last_sheet_id := v_sheet_id;
					END LOOP;
					IF v_last_sheet_id IS NOT NULL AND alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_DELEGATION) THEN
						INSERT INTO new_delegation_alert (new_delegation_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
							SELECT new_delegation_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), v_last_sheet_id
							  FROM delegation_user du
								JOIN customer_alert_type cat ON du.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_NEW_DELEGATION
								JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_Id = at.customer_alert_type_id  -- ensure there's really a template there
							 WHERE delegation_sid = v_new_delegation_sid
							   AND inherited_from_sid = v_new_delegation_sid;
					END IF;
			END;
			-- move down the tree
			v_parent_delegation_sid := v_new_delegation_sid;
       	END IF;
		v_count := v_count + 1;

		-- keep track of the sids
		v_delegation_sids.extend;
		v_delegation_sids(v_delegation_sids.COUNT) := v_new_delegation_sid;
	END LOOP;

	-- delete extra delegations that should no-longer be assigned
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 WHERE parent_sid = v_new_delegation_sid
	)
	LOOP
		securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), r.delegation_sid);
	END LOOP;

	OPEN out_cur FOR
		SELECT column_value delegation_sid FROM TABLE(v_delegation_sids);
END;

-- =======================
-- Regional sub delegation
-- =======================
PROCEDURE GetRegionalSubdelegState(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	out_result						OUT NUMBER
)
AS
	v_children_in_regions			NUMBER(10);
	v_child_delegations				NUMBER(10);
	v_split_count					NUMBER(10);
BEGIN
	-- results:
	-- 0: it's not split, and it can't be split
	-- 1: it's not split, and it can be split
	-- 2: it's already split

	-- check that this isn't already split
	SELECT COUNT(*)
	  INTO v_split_count
	  FROM delegation_region
	 WHERE delegation_sid = in_delegation_sid
	   AND aggregate_to_region_sid != region_sid;
	IF v_split_count > 0 THEN
		out_result := 2;
		RETURN;
	END IF;

	-- we are left with 0/1 as possible results now
	out_result := 0;

	-- can the user write to the delegation? if they can't write to it then it's not possible
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_WRITE) OR
	   NOT csr_data_pkg.CheckCapability('Split delegations') THEN
		RETURN;
	END IF;

	-- does it have a child in the region structure?
	SELECT COUNT(*)
	  INTO v_children_in_regions
	  FROM delegation_region dr, region r
	 WHERE dr.app_sid = r.app_sid
	   AND delegation_sid = in_delegation_sid
	   AND dr.region_sid = r.parent_sid;
	IF v_children_in_regions = 0 THEN
		RETURN;
	END IF;

	-- check that there are no child delegations
	SELECT COUNT(*)
	  INTO v_child_delegations
	  FROM delegation
	 WHERE parent_sid = in_delegation_sid;
	IF v_child_delegations > 0 THEN
		RETURN;
	END IF;

	-- all checks passed, so this can be split
	out_result := 1;
END;

-- see FB12653:
-- https://staples.credit360.com/csr/site/delegation/detailsDeleg.acds?delegsid=11371169
-- a) delegation_pkg.CombineSubdelegation needs to write to the audit log
-- b) the code needs checking to see why pressing recombine (when there's nothing to recombine) deletes data
-- c) we also need to work out why "recombine" is showing on this page anyway.
PROCEDURE CombineSubdelegation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_file_count		NUMBER(10);
	v_dr_tbl			T_DELEGATION_REGION_TABLE;
	v_drd_tbl			T_DELEG_REGION_DESC_TABLE;
	v_sheet_value_id	sheet_value.sheet_value_id%TYPE;
BEGIN
	-- permission check
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- update and get some simple info
	SELECT parent_sid, app_sid
	  INTO v_parent_sid, v_app_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- check this isn't the top
	IF v_parent_sid = v_app_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot combine top-level delegation');
	END IF;

	-- now fix up any values
	-- fixing up the values will add any needed recalc jobs
	FOR r IN (
		SELECT min(sv.sheet_value_id), sv.sheet_id, sv.ind_sid,
			dr.aggregate_to_region_sid,
			CASE
				WHEN aggregate IN ('SUM', 'FORCE SUM') THEN SUM(val_number)
				WHEN aggregate IN ('DOWN', 'FORCE DOWN', 'AVERAGE') THEN AVG(val_number)
			END val_number,
			STRAGG(sv.note) note,
			CASE
				-- we check for different entry_measure_conversion_ids
				WHEN COUNT(DISTINCT NVL(entry_measure_conversion_id,-1)) = 1 THEN MIN(entry_measure_conversion_id)
				ELSE null
			END entry_measure_conversion_id,
			CASE
				-- we check for different entry_measure_conversion_ids
				WHEN COUNT(DISTINCT NVL(entry_measure_conversion_id,-1)) = 1 THEN
					CASE
						WHEN aggregate IN ('SUM', 'FORCE SUM') THEN SUM(entry_val_number)
						WHEN aggregate IN ('DOWN', 'FORCE DOWN', 'AVERAGE') THEN AVG(entry_val_number)
					END
				ELSE null
			END entry_val_number,
			CASE
				WHEN COUNT(DISTINCT flag) = COUNT(flag) THEN MIN(flag)
				ELSE null
			END flag,
			MIN(status) status, -- take min status since the flags are in a sensible sequence (i.e. 0 = worst-case = entered -> 3 = best-case = merged)
			STRAGG(sheet_value_id) sheet_value_ids
		FROM sheet_value_converted sv, -- ignore pct ownership
			sheet s, ind i, delegation d, delegation_region dr
		 WHERE s.delegation_sid = in_delegation_sid
		   AND s.sheet_id = sv.sheet_id
		   AND sv.ind_sid = i.ind_sid
		   AND s.delegation_sid = d.delegation_sid
		   AND d.delegation_sid = dr.delegation_sid
		   AND sv.region_sid = dr.region_sid
		 GROUP BY sv.sheet_id, sv.ind_sid, i.aggregate, dr.aggregate_to_region_sid
		 ORDER BY sheet_id, ind_sid
	)
	LOOP
		-- We need the file upload count for all contributing sheet values
		SELECT COUNT(*)
		  INTO v_file_count
		  FROM sheet_value_file
		 WHERE sheet_value_id IN (
			SELECT item
			  FROM TABLE(utils_pkg.SplitString(r.sheet_value_ids,','))
		 );

		SaveValue(in_act_id, r.sheet_id, r.ind_sid, r.aggregate_to_region_sid, r.val_number,
			r.entry_measure_conversion_id, r.entry_val_number,
			r.note,
			'Combined', -- reason
			r.status,
			v_file_count, -- Procedure now takes the file count so the value is created if the note was null buit there are uploads
			r.flag,
			1, -- write history
			v_sheet_value_id
		);

		-- copy accuracy info up
		DELETE FROM sheet_value_accuracy
		 WHERE sheet_value_id = v_sheet_value_id;
		INSERT INTO sheet_value_accuracy (
			sheet_value_id, accuracy_type_option_id, pct
		 )
			SELECT v_sheet_value_id, accuracy_type_option_id, AVG(pct) pct
			  FROM sheet_value_accuracy
			 WHERE sheet_value_id IN (
				SELECT item
				  FROM TABLE(utils_pkg.SplitString(r.sheet_value_ids,','))
				)
			 GROUP BY accuracy_type_option_id;

		-- copy file upload info up
		DELETE FROM sheet_value_file
		 WHERE sheet_value_id = v_sheet_value_id;
		INSERT INTO sheet_value_file (
			sheet_value_id, file_upload_sid
		 )
			SELECT v_sheet_value_id, file_upload_sid
			  FROM sheet_value_file
			 WHERE sheet_value_id IN (
				SELECT item
				  FROM TABLE(utils_pkg.SplitString(r.sheet_value_ids,','))
				);

		-- clean up old values
		FOR rr IN (
			SELECT item
			  FROM TABLE(utils_pkg.SplitString(r.sheet_value_ids,','))
		)
		LOOP
			sheet_pkg.INTERNAL_DeleteSheetValue(rr.item);
		END LOOP;
	END LOOP;

	-- now fix up the region structure
	-- we have to delete stuff, but also add a new set of rows in that
	-- depend on what we're deleting.
	SELECT dr.delegation_sid, pdr.region_sid,
		   MAX(dr.mandatory) mandatory, -- best guess, go mandatory if one of them is
		   pdr.pos, pdr.region_sid, dr.app_sid, dr.visibility
	  BULK COLLECT INTO v_dr_tbl
	  FROM delegation_region pdr, delegation_region dr
	 WHERE pdr.delegation_sid = v_parent_sid
	   AND dr.delegation_sid = in_delegation_sid
	   AND pdr.app_sid = dr.app_sid AND pdr.region_sid = dr.aggregate_to_region_sid
     GROUP BY dr.delegation_sid, pdr.region_sid, pdr.pos, pdr.region_sid, dr.app_sid, dr.visibility;

	SELECT drd.delegation_sid, drd.region_sid, drd.lang, drd.description
	  BULK COLLECT INTO v_drd_tbl
	  FROM delegation_region_description drd
	 WHERE (app_sid, delegation_sid, region_sid) IN (
	 		SELECT dr.app_sid, dr.delegation_sid, pdr.region_sid
			  FROM delegation_region pdr, delegation_region dr
			 WHERE pdr.delegation_sid = v_parent_sid
			   AND dr.delegation_sid = in_delegation_sid
			   AND pdr.app_sid = dr.app_sid AND pdr.region_sid = dr.aggregate_to_region_sid);

	DELETE FROM delegation_region_description
	 WHERE delegation_sid = in_delegation_Sid;

	DELETE FROM delegation_region
	 WHERE delegation_sid = in_delegation_Sid;

	FOR i IN 1 .. v_dr_tbl.COUNT
	LOOP
		INSERT INTO delegation_region (
			delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility
		) VALUES (
			v_dr_tbl(i).delegation_sid,
			v_dr_tbl(i).region_sid,
			v_dr_tbl(i).mandatory,
			v_dr_tbl(i).pos,
			v_dr_tbl(i).aggregate_to_region_Sid,
			v_dr_tbl(i).visibility
		);
	END LOOP;

	FOR i IN 1 .. v_drd_tbl.COUNT
	LOOP
		INSERT INTO delegation_region_description (
			delegation_sid, region_sid, lang, description
		) VALUES (
			v_drd_tbl(i).delegation_sid,
			v_drd_tbl(i).region_sid,
			v_drd_tbl(i).lang,
			v_drd_tbl(i).description
		);
	END LOOP;
END;

PROCEDURE DoRegionalSubdelegation(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_regions_list				IN	VARCHAR2,
	in_aggregate_to_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_count					NUMBER(10);
	v_parent_sid			security_pkg.T_SID_ID;
	v_start_dtm				delegation.start_dtm%TYPE;
	v_end_dtm				delegation.end_dtm%TYPE;
	t_regions				T_SPLIT_TABLE;
	v_overlaps				SYS_REFCURSOR;
	v_o_delegation_sid		security_pkg.T_SID_ID;
	v_o_name				delegation.name%TYPE;
	v_o_description			delegation_description.description%TYPE;
	v_o_start_dtm			delegation.start_dtm%TYPE;
	v_o_end_dtm				delegation.end_dtm%TYPE;
	v_o_parent_sid			delegation.parent_sid%TYPE;
	v_o_allocate_users_to	delegation.allocate_users_to%TYPE;
	v_o_group_by			delegation.group_by%TYPE;
	v_o_reminder_offset		delegation.reminder_offset%TYPE;
	v_o_is_note_mandatory	delegation.is_note_mandatory%TYPE;
	v_o_is_flag_mandatory	delegation.is_flag_mandatory%TYPE;
	v_o_fully_delegated		delegation.fully_delegated%TYPE;
	v_o_period_set_id		delegation.period_set_id%TYPE;
	v_o_period_interval_id	delegation.period_interval_id%TYPE;
	v_o_schedule_xml		delegation.schedule_xml%TYPE;
	v_o_show_aggregate		delegation.show_aggregate%TYPE;
	v_o_delegation_policy	v$delegation.delegation_policy%TYPE;
	v_o_submission_offset	v$delegation.submission_offset%TYPE;
	v_o_tag_vis_matrix_group_id	v$delegation.tag_visibility_matrix_group_id%TYPE;
	v_o_allow_multi_period	v$delegation.allow_multi_period%TYPE;
	v_state					NUMBER(10);
	v_is_top				NUMBER(10);
	v_found					BOOLEAN;
BEGIN
	-- can user write to delegation?
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- is it even possible to do this?
	GetRegionalSubdelegState(in_delegation_sid, v_state);
	IF v_state != 1 THEN
		RETURN;
	END IF;

	t_regions := Utils_Pkg.splitstring(in_regions_list, ',');

	-- check no child delegations
	SELECT count(*) INTO v_count FROM delegation where parent_sid = in_delegation_sid;
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CANNOT_SUBDIVIDE_REGION, 'Can''t subdivide - subdelegated already');
	END IF;

	-- check for overlaps
	SELECT parent_sid, start_dtm, end_dtm, case when parent_sid = app_sid then 1 else 0 end is_top
	  INTO v_parent_sid, v_start_dtm, v_end_dtm, v_is_top
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	-- TODO Refactor to use ExFindOverlaps. 
	delegation_pkg.FindOverlaps(in_act_id, in_delegation_sid, v_parent_sid, v_start_dtm, v_end_dtm, NULL, in_regions_list, v_overlaps);
	FETCH v_overlaps
	 INTO v_o_delegation_sid, v_o_parent_sid, v_o_name, v_o_description, v_o_allocate_users_to, v_o_group_by,
		  v_o_reminder_offset, v_o_is_note_mandatory, v_o_is_flag_mandatory, v_o_fully_delegated,
		  v_o_start_dtm, v_o_end_dtm, v_o_period_set_id, v_o_period_interval_id, v_o_schedule_xml,
		  v_o_show_aggregate, v_o_delegation_policy, v_o_submission_offset, v_o_tag_vis_matrix_group_id, v_o_allow_multi_period;
	v_found := v_overlaps%FOUND;
	CLOSE v_overlaps;
	IF v_found THEN
		-- shouldn't happen TBH...
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SHEET_OVERLAPS, 'Overlaps');
	END IF;

	-- delete any sheet values for sheets for this delegation
	-- Or not apparently, what's 1 = 0 doing in here?!
	FOR r_sv IN (
		SELECT sheet_value_id
		  FROM sheet_value sv, sheet s
		 WHERE sv.sheet_id = s.sheet_id
		   AND s.delegation_sid = in_delegation_sid
		   AND 1 = 0
	)
	LOOP
		sheet_pkg.INTERNAL_DeleteSheetValue(r_sv.sheet_value_id);
	END LOOP;

	-- if it's a top level delegation we have to do things a bit differently
	IF v_is_top = 1 THEN
		-- this is nasty as it renames regions "as parent - child"
		-- we'll try and i8n it. ick.
		FOR r IN (
			SELECT x.region_sid parent_region_sid, x.child_region_sid, dr.mandatory,
				   dr.pos,  -- this is wrong but hey who cares about the order. We should join back to t_regions to figure it out
				   dr.visibility, dr.allowed_na
			  FROM delegation_region dr
			  JOIN (SELECT region_sid, CONNECT_BY_ROOT region_sid child_region_sid
					  FROM region
						   START WITH region_sid IN (
								SELECT item
								  FROM TABLE (t_regions))
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid) x
				ON dr.region_sid = x.region_sid
			 WHERE delegation_sid = in_delegation_sid
			   AND x.child_region_sid NOT IN (
					SELECT region_sid FROM delegation_region WHERE delegation_sid = in_delegation_sid
			   )
		) LOOP

			INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
			VALUES (in_delegation_sid, r.child_region_sid, r.mandatory, r.pos, r.child_region_sid, r.visibility, r.allowed_na);

			INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
				SELECT in_delegation_sid, r.child_region_sid, prd.lang, prd.description || ' - ' || crd.description
				  FROM region_description prd, region_description crd
				 WHERE prd.lang = crd.lang
				   AND prd.region_sid = r.parent_region_sid
				   AND crd.region_sid = r.child_region_sid;
		END LOOP;

		DELETE FROM delegation_region_description
		 WHERE delegation_sid = in_delegation_sid
		   AND region_sid NOT IN (SELECT item FROM TABLE(t_regions));

		DELETE FROM delegation_region
		 WHERE delegation_sid = in_delegation_sid
		   AND region_sid NOT IN (SELECT item FROM TABLE(t_regions));

	ELSE
		DELETE FROM delegation_region_description
		 WHERE delegation_sid = in_delegation_sid;

		-- update delegation_region and set flag on our delegation (XXX: what flag?)
		DELETE FROM delegation_region
		 WHERE delegation_sid = in_delegation_sid;

		-- figure out where the ancestors of the regions we've been passed intersect with
		-- the regions of the parent delegation

		INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility, allowed_na)
			SELECT in_delegation_sid, rr.child_region_sid, dr.mandatory,
				   dr.pos,  -- this is wrong but hey who cares about the order. We should join back to t_regions to figure it out
				   dr.region_sid, dr.visibility, dr.allowed_na
			  FROM delegation_region dr, (
					SELECT region_sid, CONNECT_BY_ROOT region_sid child_region_sid
					  FROM region
						   START WITH region_sid IN (
								SELECT item
								  FROM TABLE (t_regions))
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid) rr
			 WHERE dr.region_sid = rr.region_sid
			   AND dr.delegation_sid = v_parent_sid;
	END IF;

	-- add recalc jobs
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid, MIN(d.start_dtm) start_dtm, MAX(d.end_dtm) end_dtm
		  		 FROM delegation_ind di, delegation d
		  		WHERE di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		  		  AND di.delegation_sid = in_delegation_sid
				GROUP BY di.ind_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, d.start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, d.end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, d.start_dtm, d.end_dtm);
	END IF;

	-- propagate sheet values down
	FOR r_sv IN (
		SELECT s.sheet_id
		  FROM sheet s
		  JOIN customer c ON s.app_sid = c.app_sid
		 WHERE s.delegation_sid = in_delegation_sid
		   AND c.propagate_deleg_values_down = 1
	)
	LOOP
		sheet_pkg.CopyValuesFromParentSheet(in_act_id, r_sv.sheet_id);
	END LOOP;

	-- <audit>
	-- write to audit log
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_delegation_sid,
		'Fill in for subsidiary regions "{0}"', delegation_pkg.ConcatDelegationRegions(in_delegation_sid, 5));
END;

PROCEDURE SetSectionKey(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_section_key			IN	delegation_ind.section_key%TYPE
)
AS
	t_indicators	T_SPLIT_TABLE;
BEGIN
	-- check permission
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	t_indicators 	:= Utils_Pkg.splitString(in_indicators_list,',');
	UPDATE delegation_ind
	   SET section_key = in_section_key
 	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid IN (SELECT item FROM TABLE(t_indicators));
END;

PROCEDURE SetSectionXML(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_section_xml		IN	delegation.section_xml%TYPE
)
AS
BEGIN
	-- check permission
	IF NOT CheckDelegationPermission(in_act_id, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE delegation
	   SET section_xml = in_section_xml
 	 WHERE delegation_sid = in_delegation_sid;

 	-- if no section_xml, then set all section keys on indicators to null
 	IF in_section_xml IS NULL THEN
		UPDATE delegation_ind
		   SET section_key = null
		 WHERE delegation_sid = in_delegation_sid;
 	END IF;
END;

-- =================================================================
-- specific things for adminDeleg page (dropdown list/list contents)
-- =================================================================
-- gets all possible delegations periods (remove at some point - just
-- used for dropdown in adminDeleg.acds)

-- DO NOT USE
-- Only used by C:\cvs\csr\web\site\delegation\adminDeleg.aspx.cs -- which should be phased out
PROCEDURE GetFullDelegationPeriods(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
		  FROM sheet s, delegation d
		 WHERE s.delegation_sid = d.delegation_sid
		   AND d.app_sid = in_app_sid
		 GROUP BY s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
		 ORDER BY s.start_dtm;
END;

-- DO NOT USE
-- Only used by C:\cvs\csr\web\site\delegation\adminDeleg.aspx.cs -- which should be phased out
PROCEDURE GetFullDelegations(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	sheet.end_dtm%TYPE,
	in_end_dtm						IN	sheet.start_dtm%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		-- parents
		SELECT 0 parent_sheet_id, sla.sheet_id, d.delegation_sid, d.name, d.description, sla.start_dtm, sla.end_dtm,
			   d.period_set_id, d.period_interval_id, sla.submission_dtm, sla.status,
			   delegation_pkg.ConcatDelegationUsers(d.delegation_sid) users,
			   sa.description sheet_action_description, d.editing_url
		  FROM v$delegation_hierarchical d, sheet_with_last_action sla, sheet_action sa
		 WHERE d.parent_sid = in_app_sid
		   AND sla.delegation_sid = d.delegation_sid
		   AND sla.last_action_id = sa.sheet_action_id
		   AND sla.start_dtm = in_start_dtm
		   AND sla.end_dtm = in_end_dtm
--		   AND status = 1
		 UNION
		-- their children
		SELECT sp.sheet_id parent_sheet_id, sla.sheet_id, d.delegation_sid, d.name, d.description, sla.start_dtm,
			   sla.end_dtm, d.period_set_id, d.period_interval_id, sla.submission_dtm, sla.status,
			   delegation_pkg.ConcatDelegationUsers(d.delegation_sid) users,
			   sa.description sheet_action_description, d.editing_url
		  FROM v$delegation_hierarchical d, delegation dp, sheet_with_last_action sla, sheet_action sa, sheet sp,
			   (SELECT d.delegation_sid
				  FROM delegation d, sheet_with_last_action sla
				 WHERE d.parent_sid = in_app_sid
				   AND sla.delegation_sid = d.delegation_sid
				   AND sla.start_dtm = in_start_dtm
				   AND sla.end_dtm = in_end_dtm
				 --AND status = 1
			   ) dpp
		 WHERE sla.delegation_sid = d.delegation_sid
		   AND d.parent_sid = dp.delegation_sid
		   AND sla.last_action_id = sa.sheet_action_id
		   AND sp.start_dtm <= sla.start_dtm
		   AND sp.end_dtm >= sla.end_dtm
		   AND sp.delegation_sid = dp.delegation_sid
		   AND dp.delegation_sid = dpp.delegation_sid;
END;

-- =================================================================
-- specific things for old audit page (which we want to remove)
-- =================================================================
PROCEDURE AuditDelegTrail(
	in_date_from					IN	sheet.start_dtm%TYPE,
	in_date_to						IN	sheet.end_dtm%TYPE,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_user_from_sid				IN	security_pkg.T_SID_ID,
	in_user_to_sid					IN	security_pkg.T_SID_ID,
	in_sheet_action_id				IN	sheet_action.SHEET_ACTION_ID%TYPE,
	in_top_level					IN	NUMBER,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by						VARCHAR2(1000);
	v_delegation_sid				VARCHAR2(1000);
	v_user_from_sid					VARCHAR2(1000);
	v_user_to_sid					VARCHAR2(1000);
	v_sheet_action_id				VARCHAR2(1000);
	v_top_level						VARCHAR2(1000);
	v_csr_delegation_sid			security_pkg.T_SID_ID;
BEGIN
	v_csr_delegation_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'),
		SYS_CONTEXT('SECURITY', 'APP'), 'Delegations');

	IF NOT CheckDelegationPermission(SYS_CONTEXT('SECURITY', 'ACT'), v_csr_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'delegation_sid,name,period_fmt,user_from,user_to,description,action_dtm,sheet_id');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	IF in_delegation_sid IS NOT NULL THEN
		v_delegation_sid := ' AND d.delegation_sid= ' || in_delegation_sid;
	END IF;

	IF in_user_from_sid IS NOT NULL THEN
		v_user_from_sid := ' AND cuf.csr_user_sid= ' || in_user_from_sid;
	END IF;

	IF in_user_to_sid IS NOT NULL THEN
		v_user_to_sid := ' AND cu.csr_user_sid= ' || in_user_to_sid;
	END IF;

	IF in_sheet_action_id IS NOT NULL THEN
		v_sheet_action_id := ' AND sh.sheet_action_id= ' || in_sheet_action_id;
	END IF;

	IF in_top_level = 1 THEN
		v_top_level := ' AND d.parent_sid=' || SYS_CONTEXT('SECURITY', 'APP');
	END IF;

	-- NB we add 1 to the date because we want everything prior to midnight that night
	EXECUTE IMMEDIATE 
		'SELECT COUNT(*) '||
		  'FROM sheet_history sh, sheet s, delegation d, sheet_action sa, csr_user cuf '||
		 'WHERE sh.sheet_id = s.sheet_id'||
		  ' AND s.delegation_sid = d.delegation_sid'||
		  ' AND sh.sheet_history_id = s.last_sheet_history_id'||
		  v_top_level||
		  v_delegation_sid||
		  v_user_from_sid||
		  v_user_to_sid||
		  ' AND sa.sheet_action_id = sh.sheet_action_id'||
		  v_sheet_action_id||
		  ' AND sh.from_user_sid = cuf.csr_user_sid'||
		  ' AND (:in_date_from IS NULL OR action_dtm > :in_date_from) '||
		  ' AND (:in_date_to IS NULL OR action_dtm < :in_date_to + 1)'
		INTO out_total_rows
		USING in_date_from, in_date_from, in_date_to, in_date_to;

	OPEN out_cur FOR
		'SELECT * '||
		  'FROM (SELECT q.*, rownum rn ' ||
				  'FROM (SELECT d.delegation_sid, d.name, d.start_dtm delegation_start_dtm, d.end_dtm delegation_end_dtm, '||
							   's.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id, '||
							   'cuf.full_name user_from, sa.description, sh.action_dtm, s.sheet_id '||
						  'FROM sheet_history sh, sheet s, delegation d, sheet_action sa, csr_user cuf '||
						 'WHERE sh.sheet_id = s.sheet_id'||
						  ' AND s.delegation_sid = d.delegation_sid'||
						  ' AND sh.sheet_history_id = s.last_sheet_history_id'||
						  v_top_level||
						  v_delegation_sid||
						  v_user_from_sid||
						  v_user_to_sid||
						  ' AND sa.sheet_action_id = sh.sheet_action_id'||
						  v_sheet_action_id||
						  ' AND sh.from_user_sid = cuf.csr_user_sid'||
						  ' AND (:in_date_from IS NULL OR action_dtm > :in_date_from) '||
						  ' AND (:in_date_to IS NULL OR action_dtm < :in_date_to + 1) '||
						  v_order_by||') q '||
				 'WHERE rownum < :in_start_row + :in_page_size) '||
		 'WHERE rn >= :in_start_row'				  
		USING in_date_from, in_date_from, in_date_to, in_date_to, in_start_row, in_page_size, in_start_row;
END;

PROCEDURE AuditSheetTrail(
	in_date_from					IN	sheet.start_dtm%TYPE,
	in_date_to						IN	sheet.end_dtm%TYPE,
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_include_children				IN	NUMBER,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by						VARCHAR2(1000);
	v_sql							VARCHAR2(4000);
	v_start_dtm						sheet.start_dtm%TYPE;
	v_end_dtm						sheet.end_dtm%TYPE;
	v_delegation_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid, start_dtm, end_dtm
	  INTO v_delegation_sid, v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT CheckDelegationPermission(SYS_CONTEXT('SECURITY', 'ACT'), v_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'sheet_id,ind_description,region_description,full_name,val_number,set_dtm,alert,note');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	-- NB we add 1 to the date because we want everything prior to midnight that night
	IF in_include_children = 1 THEN
		EXECUTE IMMEDIATE
			'SELECT COUNT(*) '||
			  'FROM sheet_value sv '||
			  'JOIN sheet_value_change svc ON svc.app_sid = sv.app_sid AND svc.sheet_value_id = sv.sheet_value_id '||
			  'JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id '||
			 'WHERE s.delegation_sid IN ('||
					'SELECT delegation_sid '||
					  'FROM delegation '||
						   'START WITH delegation_sid = :v_delegation_sid '||
						   'CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) '||
			   'AND s.start_dtm >= :v_start_dtm '||
			   'AND s.end_dtm <= :v_end_dtm '||
			   'AND (:in_date_from IS NULL OR sv.set_dtm >= :in_date_from) '||
			   'AND (:in_date_to IS NULL OR sv.set_dtm < :in_date_to + 1)'
		 INTO out_total_rows
		USING v_delegation_sid, v_start_dtm, v_end_dtm, in_date_from, in_date_from, 
			  in_date_to, in_date_to;

		OPEN out_cur FOR
			'SELECT * '||
			  'FROM (SELECT q.*, rownum rn ' ||
					  'FROM (SELECT sv.sheet_id, i.description ind_description, r.description region_description, '||
								   'cu.full_name, svc.val_number, svc.changed_dtm set_dtm, sv.alert, svc.note, svc.reason, '||
								   'case when (sh.sheet_action_id = 9) then 1 else 0 end merged, '||
								   'NVL(i.format_mask, m.format_mask) format_mask, NVL(i.scale, m.scale) scale '||
							  'FROM sheet_value sv '||
							  'JOIN sheet_value_change svc ON svc.app_sid = sv.app_sid AND svc.sheet_value_id = sv.sheet_value_id '||
							  'JOIN v$ind i ON sv.app_sid = i.app_sid AND sv.ind_sid = i.ind_sid '||
							  'LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid '||
							  'JOIN v$region r ON sv.app_sid = r.app_sid AND sv.region_sid = r.region_sid '||
							  'JOIN csr_user cu ON sv.app_sid = cu.app_sid AND sv.set_by_user_sid = cu.csr_user_sid '||
							  'JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id '||
							  'JOIN sheet_history sh ON s.app_sid = sh.app_sid AND s.last_sheet_history_id = sh.sheet_history_id '||
							 'WHERE s.delegation_sid IN ('||
									'SELECT delegation_sid '||
									  'FROM delegation '||
										   'START WITH delegation_sid = :v_delegation_sid '||
										   'CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) '||
							   'AND s.start_dtm >= :v_start_dtm '||
							   'AND s.end_dtm <= :v_end_dtm '||
							   'AND (:in_date_from IS NULL OR sv.set_dtm >= :in_date_from) '||
							   'AND (:in_date_to IS NULL OR sv.set_dtm < :in_date_to + 1)'||
							   v_order_by||') q '||
					 'WHERE rownum < :in_start_row + :in_page_size) '||
			 'WHERE rn >= :in_start_row'				  
			USING v_delegation_sid, v_start_dtm, v_end_dtm, in_date_from, in_date_from, 
				  in_date_to, in_date_to, in_start_row, in_page_size, in_start_row;
	ELSE
		EXECUTE IMMEDIATE
			'SELECT COUNT(*) '||
			  'FROM sheet_value sv '||
			  'JOIN sheet_value_change svc ON svc.app_sid = sv.app_sid AND svc.sheet_value_id = sv.sheet_value_id '||
			  'JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id '||
			 'WHERE sv.sheet_id = :in_sheet_id '||
			   'AND (:in_date_from IS NULL OR sv.set_dtm >= :in_date_from) '||
			   'AND (:in_date_to IS NULL OR sv.set_dtm < :in_date_to + 1)'
		 INTO out_total_rows
		USING in_sheet_id, in_date_from, in_date_from, in_date_to, in_date_to;

		OPEN out_cur FOR
			'SELECT * '||
			  'FROM (SELECT q.*, rownum rn ' ||
					  'FROM (SELECT sv.sheet_id, i.description ind_description, r.description region_description, '||
								   'cu.full_name, svc.val_number, svc.changed_dtm set_dtm, sv.alert, svc.note, svc.reason, '||
								   'case when (sh.sheet_action_id = 9) then 1 else 0 end merged, '||
								   'NVL(i.format_mask, m.format_mask) format_mask, NVL(i.scale, m.scale) scale '||
							  'FROM sheet_value sv '||
							  'JOIN sheet_value_change svc ON svc.app_sid = sv.app_sid AND svc.sheet_value_id = sv.sheet_value_id '||
							  'JOIN v$ind i ON sv.app_sid = i.app_sid AND sv.ind_sid = i.ind_sid '||
							  'LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid '||
							  'JOIN v$region r ON sv.app_sid = r.app_sid AND sv.region_sid = r.region_sid '||
							  'JOIN csr_user cu ON sv.app_sid = cu.app_sid AND sv.set_by_user_sid = cu.csr_user_sid '||
							  'JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id '||
							  'JOIN sheet_history sh ON s.app_sid = sh.app_sid AND s.last_sheet_history_id = sh.sheet_history_id '||
							 'WHERE sv.sheet_id = :in_sheet_id '||
							   'AND (:in_date_from IS NULL OR sv.set_dtm >= :in_date_from) '||
							   'AND (:in_date_to IS NULL OR sv.set_dtm < :in_date_to + 1)'||
							  v_order_by||') q '||
					 'WHERE rownum < :in_start_row + :in_page_size) '||
			 'WHERE rn >= :in_start_row'				  
			USING in_sheet_id, in_date_from, in_date_from, in_date_to, in_date_to, in_start_row, in_page_size, in_start_row;
	END IF;
END;

PROCEDURE GetAllDelegationNames(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, description, delegation_sid
		  FROM v$delegation_hierarchical
			   START WITH parent_sid = in_app_sid
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 ORDER BY name;
END;

PROCEDURE GetAllStatusDescription(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT description, sheet_action_id
		  FROM sheet_action
		 ORDER BY sheet_action_id;
END;

PROCEDURE GetDelegationSummaryReport(
	in_start_dtm	IN	delegation.start_dtm%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF NOT sqlreport_pkg.CheckAccess('csr.delegation_pkg.GetDelegationSummaryReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- imperfect if they split or do complex things but helpful for AMs
	OPEN out_cur FOR
		SELECT CASE WHEN
				  LAG(root_sid, 1) OVER (ORDER BY root_sid) = x.root_sid THEN null
				  ELSE x.root_Sid
			   END id,
			   CASE WHEN
				  LAG(root_sid, 1) OVER (ORDER BY root_sid) = x.root_sid THEN NULL
				  ELSE start_dtm || ' to ' || (end_dtm-1)
			   END period,
			   CASE WHEN
				  LAG(root_sid, 1) OVER (ORDER BY root_sid) = x.root_sid THEN null
				  ELSE d.name
			   END name,
			   -- TODO: 13p fix
			   CASE WHEN
				  LAG(root_sid, 1) OVER (ORDER BY root_sid) = x.root_sid THEN NULL
				  ELSE decode(d.period_interval_id, 1, 'Monthly', 2, 'Quarterly', 3, 'Half yearly', 4, 'Annual', 'Unknown')
			   END interval,
			   x.description,
			   x.users
		  FROM (
				SELECT DISTINCT e.root_sid, e.description, e.users
				  FROM (
					  SELECT e.root_sid, drd.description,
						  STRAGG(e.users) OVER (
							  PARTITION BY e.root_sid, drd.description
								  ORDER BY e.lvl
								  RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
						  ) users
						FROM (
							  SELECT d.root_sid, d.delegation_sid, d.lvl, '('||lvl||') ' ||STRAGG(cu.full_name) users
								FROM (
									  SELECT d.root_sid, d.delegation_sid, d.lvl, NVL(du.user_sid, rrm.user_sid) user_sid
										FROM (
											  SELECT app_sid, delegation_sid, level lvl, connect_by_root delegation_sid root_sid
												FROM delegation
											   WHERE end_dtm > in_start_dtm
											   START WITH parent_sid = SYS_CONTEXT('SECURITY','APP')
											 CONNECT BY PRIOR delegation_sid = parent_sid
										) d
										JOIN delegation_region dr ON d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
										LEFT JOIN delegation_user du ON du.app_sid = d.app_sid AND du.delegation_sid = d.delegation_sid AND du.inherited_from_sid = d.delegation_sid
										LEFT JOIN delegation_role dlr ON dlr.app_sid = d.app_sid AND dlr.delegation_sid = d.delegation_sid AND dlr.inherited_from_sid = d.delegation_sid
										LEFT JOIN region_role_member rrm ON dlr.app_sid = rrm.app_sid AND dlr.role_sid = rrm.role_sid AND rrm.region_sid = dr.region_sid
									   GROUP BY d.root_sid, d.delegation_sid, d.lvl, NVL(du.user_sid, rrm.user_sid)
								) d
								LEFT JOIN csr_user cu ON d.user_sid  = cu.csr_user_sid
							   GROUP BY d.root_sid, d.delegation_sid, d.lvl
						) e
						JOIN v$delegation_region drd ON drd.delegation_sid = e.delegation_sid
				  ) e
          ) x
		  JOIN v$delegation d on x.root_sid = d.delegation_sid
		 ORDER BY x.root_Sid, d.name, x.description;
END;

PROCEDURE GetReportDelegationBlockers(
	in_overdue_only	IN	NUMBER,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
    v_start_dtm    	 	reporting_period.start_dtm%TYPE;
    v_end_dtm      		reporting_period.start_dtm%TYPE;
    v_submission_dtm	reporting_period.start_dtm%TYPE;
    v_region_root_sids	security.T_SID_TABLE;
BEGIN
	IF NOT sqlreport_pkg.CheckAccess('csr.delegation_pkg.GetReportDelegationBlockers') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_overdue_only = 1 THEN
		v_submission_dtm := sysdate;
	ELSE
		v_submission_dtm := null;
	END IF;

	-- Paranoia. The region picker appears to restrict the UI based on mount points, but I imagine any SID could be POSTed in.
	IF in_region_sid IS NOT NULL THEN
		BEGIN
			SELECT in_region_sid
			  BULK COLLECT INTO v_region_root_sids
			  FROM region
			 WHERE region_sid = in_region_sid
			 START WITH region_sid IN (SELECT region_sid
										 FROM region_start_point
										WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
					'Delegation blockers report request for region sid not under user''s mount point: '||in_region_sid);
		END;
	ELSE
		v_region_root_sids := csr_user_pkg.GetRegionStartPointsAsTable;
	END IF;

    SELECT start_dtm, end_dtm
      INTO v_start_dtm, v_end_dtm
      FROM reporting_period rp, customer c
     WHERE rp.reporting_period_sid = c.current_reporting_period_sid
       AND c.app_sid = SYS_CONTEXT('SECURITY','APP');

    OPEN out_cur FOR
		SELECT period_set_id, period_interval_id, start_dtm, end_dtm,
			   name "Name", description "Description",
			   delegation_pkg.ConcatDelegationRegions(delegation_sid) "Region",
			   delegation_pkg.ConcatDelegProviders(delegation_sid) "Provider",
			   delegation_pkg.ConcatDelegApprovers(delegation_sid) "Approver",
			   lvl "Level",
			   reminder_dtm "Reminder date",
			   submission_dtm "Due date",
			   last_action_desc "Sheet status",
			   delegation_sid, sheet_id
		  FROM (SELECT root_sheet_id, sheet_id, last_action_id, score, lvl, period_set_id, period_interval_id,
		  	 		   start_dtm, end_dtm, delegation_sid, reminder_dtm, submission_dtm, last_action_desc, name, description,
					   CASE WHEN first_value(sheet_id) over (partition by root_sheet_id order by score asc) = sheet_id then 1 else 0 end process
				  FROM (SELECT d.app_sid, d.name, d.description, connect_by_root d.delegation_sid root_delegation_sid, d.delegation_sid, d.parent_sid,
							   level lvl, s.sheet_id, prior s.sheet_id parent_sheet_id, d.period_set_id, d.period_interval_id,
							   s.start_dtm, s.end_dtm, last_action_id, last_action_colour, connect_by_root sheet_id root_sheet_id,
							   reminder_dtm, submission_dtm, last_action_desc,
							   CASE
									WHEN last_action_id in (csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_MERGED_WITH_MOD) then 1 * level * 10
									WHEN last_action_id in (csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_ACCEPTED_WITH_MOD) then 2000  -- ignore
									WHEN last_action_id in (csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD) then 3 * level * 10
									WHEN last_action_id in (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED_WITH_MOD) then 1000 - (4 * level * 10)
							   END score
						  FROM v$delegation d
						  JOIN sheet_with_last_action s on d.delegation_sid = s.delegation_sid  AND d.app_sid = s.app_sid
						 WHERE d.app_sid = SYS_CONTEXT('SECURITY','APP')
						   AND s.end_dtm > v_start_dtm
						   AND s.start_dtm < v_end_dtm
						   AND (s.submission_dtm < v_submission_dtm or v_submission_dtm IS NULL)
						 	   START WITH d.parent_sid = d.app_sid
						       CONNECT BY PRIOR d.delegation_sid = d.parent_sid
									  AND PRIOR s.end_dtm > s.start_dtm
									  AND PRIOR s.start_dtm < s.end_dtm
					  ) s
			    )
		 WHERE process = 1
		   AND last_action_id in (
				csr_data_pkg.ACTION_SUBMITTED,
				csr_data_pkg.ACTION_SUBMITTED_WITH_MOD,
				csr_data_pkg.ACTION_WAITING,
				csr_data_pkg.ACTION_WAITING_WITH_MOD,
				csr_data_pkg.ACTION_MERGED_WITH_MOD,
				csr_data_pkg.ACTION_RETURNED_WITH_MOD
			   ) -- exclude anything in 9 (merged) + (3,6)
		   AND delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation_region
			 WHERE region_sid IN (
				SELECT region_sid
				  FROM region
				 START WITH region_sid IN (SELECT column_value FROM TABLE(v_region_root_sids))
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid)
		) -- just stuff the user can see
		ORDER BY start_dtm, name, "Region", "Provider";
END;

PROCEDURE GetReportSubmissionPromptness(
	in_sheet_start_date			IN	DATE,
	in_sheet_end_date			IN	DATE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_app_sid					customer.app_sid%TYPE;
	v_act_id					security_pkg.T_ACT_ID;
	v_first_sheet_action_tbl	T_FIRST_SHEET_ACTION_DTM_TABLE;
BEGIN
	v_act_id	:= SYS_CONTEXT('SECURITY','ACT');
	v_app_sid	:= SYS_CONTEXT('SECURITY','APP');

	IF NOT sqlreport_pkg.CheckAccess('csr.delegation_pkg.GetReportSubmissionPromptness') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied.');
	END IF;

	SELECT T_FIRST_SHEET_ACTION_DTM(app_sid, sheet_id, first_action_dtm)
	  BULK COLLECT INTO v_first_sheet_action_tbl
	  FROM (
		SELECT sv.app_sid, sv.sheet_id, MIN(svc.changed_dtm) first_action_dtm
		  FROM sheet s, sheet_value_change svc, sheet_value sv
		 WHERE svc.app_sid = sv.app_sid AND svc.sheet_value_id = sv.sheet_value_id
		   AND s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
		   AND (in_sheet_start_date IS NULL OR s.end_dtm > in_sheet_start_date)
		   AND (in_sheet_end_date IS NULL OR s.start_dtm < in_sheet_end_date)
		 GROUP BY sv.app_sid, sv.sheet_id
	);

	OPEN out_cur FOR
		SELECT d.period_set_id, d.period_interval_id, sla.start_dtm, sla.end_dtm, d.name, d.description,
			   delegation_pkg.ConcatDelegationRegions(d.delegation_sid) "Region",
			   delegation_pkg.ConcatDelegationUsers(d.delegation_sid) "Users",
			   CASE
			       WHEN sla.last_action_colour IN ('O', 'G') THEN
			           CASE
					       WHEN sh.action_dtm <= sla.submission_dtm THEN 'Submitted on or before time'
				           ELSE 'Submitted past submission deadline'
				       END
				   ELSE
			           CASE
					       WHEN SYSDATE <= sla.submission_dtm THEN 'Open and not yet overdue'
				           ELSE 'Open and now overdue'
				       END
			   END status,
			   fsa.first_action_dtm "Date of first action",
			   sla.submission_dtm submission_deadline,
			   CASE WHEN sla.last_action_colour IN ('O', 'G') THEN sh.action_dtm ELSE NULL END "Submission date",
			   d.delegation_sid, sla.sheet_id, d.start_dtm delegation_start, d.end_dtm delegation_end, sla.start_dtm sheet_start, sla.end_dtm sheet_end
		  FROM sheet_with_last_action sla
		  JOIN v$delegation d ON sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
		  LEFT JOIN (SELECT app_sid, sheet_id, max(action_dtm) action_dtm
					   FROM sheet_history
					  WHERE sheet_action_id in (1, 9)
					  GROUP BY app_sid, sheet_id) sh ON sla.app_sid = sh.app_sid AND sla.sheet_id = sh.sheet_id
		  LEFT JOIN TABLE(v_first_sheet_action_tbl) fsa ON sla.app_sid = fsa.app_sid AND sla.sheet_id = fsa.sheet_id
		 WHERE (in_sheet_start_date IS NULL OR sla.end_dtm > in_sheet_start_date)
		   AND (in_sheet_end_date IS NULL OR sla.start_dtm < in_sheet_end_date)
		 ORDER BY d.start_dtm, sla.start_dtm, d.name, "Region", status;
END;

PROCEDURE GetGridXML(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: no security, moved from inline SQL in the web page, is it needed?
	OPEN out_cur FOR
		SELECT grid_xml
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
END;

PROCEDURE SearchAttachments(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_phrase           IN  VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	ctx_doc.set_key_type('ROWID');

	OPEN out_cur FOR
		WITH sv AS
		(
		   SELECT sv.sheet_value_id, s.sheet_id, d.delegation_sid, sv.note, sv.rowid rid,
			      d.period_set_id, d.period_interval_id, s.end_dtm, s.start_dtm,
			      di.description ind_description, dr.description region_description
			 FROM sheet_value sv, v$delegation_ind di, v$delegation_region dr, sheet s, delegation d
			WHERE sv.sheet_id = s.sheet_id
			  AND s.delegation_sid = d.delegation_sid
			  AND d.delegation_sid = dr.delegation_sid
			  AND d.delegation_sid = di.delegation_sid
			  AND sv.ind_sid = di.ind_sid
			  AND sv.region_sid = dr.region_sid
			  AND d.delegation_sid in (
				SELECT delegation_sid
				  FROM delegation
				 START WITH delegation_sid = in_delegation_sid
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			  )
		)
		SELECT 1 result_type, sv.sheet_value_id, 'text/plain' mime_type, 'Note' as Note, 
			   ctx_doc.snippet('ix_sh_val_note_search', sv.rid, in_phrase) summary,
			   sv.ind_description, sv.region_description, sv.period_set_id,
			   sv.period_interval_id, sv.start_dtm, sv.end_dtm,
			   sv.sheet_id, sv.delegation_sid
		  FROM sv
		 WHERE contains(note, in_phrase, 1) > 0
		 UNION
		SELECT 2 result_type, fu.file_upload_sid, fu.mime_type, fu.filename,
			   ctx_doc.snippet('ix_file_upload_search', fu.rowid, in_phrase) summary,
		       sv.ind_description, sv.region_description, sv.period_set_id,
		       sv.period_interval_id, sv.start_dtm, sv.end_dtm,
		       sv.sheet_id, sv.delegation_sid
		  FROM sv, sheet_value_file svf, file_upload fu
		 WHERE sv.sheet_value_id = svf.sheet_value_id
		   AND svf.file_upload_sid = fu.file_upload_sid
		   AND contains(fu.data, in_phrase, 1) > 0
		 ;
END;

PROCEDURE GetDownloadData(
	in_file_upload_sid	IN	file_upload.file_upload_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	  OPEN out_cur FOR
			SELECT fu.mime_type, fu.filename, fu.data
		 FROM file_upload fu
		WHERE fu.file_upload_sid = in_file_upload_sid
		  AND fu.app_sid = v_app_sid
		  ;
END;

PROCEDURE SaveAmendedValue(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sheet_id						IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid						IN 	security_pkg.T_SID_ID,
	in_region_sid					IN 	security_pkg.T_SID_ID,
	in_val_number					IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id			IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number				IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note							IN	SHEET_VALUE.NOTE%TYPE,
	in_reason						IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_file_count					IN	NUMBER,
	in_flag							IN	SHEET_VALUE.FLAG%TYPE,
	out_val_id						OUT sheet_value.sheet_Value_id%TYPE
)
AS
	v_out_cur					SYS_REFCURSOR;
	v_last_history_id			sheet.last_sheet_history_id%TYPE;
	v_delegation_sid			sheet.delegation_sid%TYPE;
	v_last_action_id			sheet_history.sheet_action_id%TYPE;
	v_last_from_user_sid		sheet_history.from_user_sid%TYPE;
	v_new_from_user_sid			sheet_history.from_user_sid%TYPE;
	v_new_action_id				sheet_history.sheet_action_id%TYPE;
BEGIN
	-- saveValue does permission checks
	SaveValue(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, in_val_number,
		in_entry_conversion_id, in_entry_val_number, in_note, in_reason, csr_data_pkg.SHEET_VALUE_MODIFIED, in_file_count,
		in_flag, 1, v_out_cur, out_val_id);

    -- commented this out. I guess if it was being edited by the owner it might be nice and I suspect that was the intention.
    -- Anyway, I think this is confusing, so I've commented it out, -- previously it was missing the "catch" on ACCESS_DENIED
    -- and so was failing.
    --
	--BEGIN
	--	sheet_Pkg.PropagateValuesToParentSheet(in_act_id, in_sheet_id);
	--EXCEPTION
	--	WHEN csr_data_pkg.NOT_ALLOWED_WRITE OR security_pkg.ACCESS_DENIED THEN NULL; -- ignore (probably they're editing at their own level and we can't write to the parent)
	--END;

	-- is it going to be ACTION_ACCEPTED_WITH_MOD or just ACTION_WAITING_WITH_MOD?
	SELECT last_sheet_history_id, delegation_sid
	  INTO v_last_history_id, v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	SELECT from_user_sid, sheet_action_id
	  INTO v_last_from_user_sid, v_last_action_id
	  FROM sheet_history
	 WHERE sheet_history_id = v_last_history_id;

	IF v_last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD) THEN
		v_new_action_id := csr_data_pkg.ACTION_WAITING_WITH_MOD;
	ELSIF v_last_action_id IN (csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_MERGED_WITH_MOD) THEN
		v_new_action_id := csr_data_pkg.ACTION_MERGED_WITH_MOD;
	ELSIF v_last_action_id IN (csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD) THEN
		v_new_action_id := csr_data_pkg.ACTION_SUBMITTED_WITH_MOD;
	ELSIF v_last_action_id IN (csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD) THEN
		v_new_action_id := csr_data_pkg.ACTION_RETURNED_WITH_MOD;
	ELSE
		v_new_action_id := csr_data_pkg.ACTION_ACCEPTED_WITH_MOD;
	END IF;
	v_new_from_user_sid := security_pkg.GetSID();

	-- Add a new history entry if there isn't one for this action from this user
	IF v_new_action_id != v_last_action_id OR v_new_from_user_sid != v_last_from_user_sid THEN
		sheet_pkg.CreateHistory(in_sheet_id, v_new_action_id, v_new_from_user_sid, v_delegation_sid, '');
	END IF;
END;

PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
)
AS
BEGIN
	SaveValue(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, in_val_number, in_entry_conversion_id, in_entry_val_number,
		in_note, in_reason, in_status, in_file_count, in_flag, in_write_history, 1, -- require a reason
		0, -- check for permission
		0, -- is n/a
		out_cur, out_val_id);
END;

PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
)
AS
	v_cur					SYS_REFCURSOR;
BEGIN
	SaveValue(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, in_val_number, in_entry_conversion_id, in_entry_val_number,
		in_note, in_reason, in_status, in_file_count, in_flag, in_write_history, 0, -- don't require a reason
		0, -- check for permission
		0, -- is n/a
		v_cur, out_val_id);
	CLOSE v_cur;
END;

PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	in_is_na				IN	sheet_value.is_na%TYPE,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
)
AS
	v_cur					SYS_REFCURSOR;
BEGIN
	SaveValue(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, in_val_number, in_entry_conversion_id, in_entry_val_number,
		in_note, in_reason, in_status, in_file_count, in_flag, in_write_history, 0, -- don't require a reason
		0, -- check for permission
		in_is_na,
		v_cur, out_val_id);
	CLOSE v_cur;
END;

PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	in_force_change_reason	IN	NUMBER,
	in_no_check_permission	IN	NUMBER,
	in_is_na				IN	sheet_value.is_na%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
)
AS
BEGIN
	SaveValue(
		in_act_id => in_act_id,
		in_sheet_id => in_sheet_id,
		in_ind_sid => in_ind_sid,
		in_region_sid => in_region_sid,
		in_val_number => in_val_number,
		in_entry_conversion_id => in_entry_conversion_id,
		in_entry_val_number => in_entry_val_number,
		in_note => in_note,
		in_reason => in_reason,
		in_status => in_status,
		in_file_count => in_file_count,
		in_flag => in_flag,
		in_write_history => in_write_history,
		in_force_change_reason => in_force_change_reason,
		in_no_check_permission => in_no_check_permission,
		in_is_na => in_is_na,
		in_apply_percent_ownership => 1,
		out_cur => out_cur,
		out_val_id => out_val_id
	);
END;

PROCEDURE UNSEC_GetSheetHelperInfo(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_ind_validation_rule_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_sids						security.T_SID_TABLE;
	v_region_sids					security.T_SID_TABLE;
BEGIN
	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);

	OPEN out_deleg_cur FOR
		SELECT c.tolerance_checker_req_merged,
			   CASE WHEN d.parent_sid = d.app_sid THEN 1 ELSE 0 END is_top_level,
			   d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id
		  FROM delegation d
		  JOIN customer c ON d.app_sid = c.app_sid
		 WHERE d.delegation_sid = in_delegation_sid;

	OPEN out_ind_cur FOR
		SELECT di.ind_sid, di.allowed_na
		  FROM delegation_ind di
		 WHERE di.ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids))
		   AND di.delegation_sid = in_delegation_sid;
		 
	OPEN out_region_cur FOR
		SELECT dr.region_sid, dr.allowed_na
		  FROM delegation_region dr
		 WHERE dr.region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
		   AND dr.delegation_sid = in_delegation_sid;
		 
	OPEN out_ind_validation_rule_cur FOR
		SELECT ivr.ind_sid, ivr.expr, ivr.message, ivr.type
		  FROM delegation_ind di
		  JOIN ind_validation_rule ivr ON di.ind_sid = ivr.ind_sid
		 WHERE di.delegation_sid = in_delegation_sid
		   AND di.ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids))
		 ORDER BY ivr.ind_sid;
END;

PROCEDURE SaveValue2(
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_ind_sid						IN 	ind.ind_sid%TYPE,
	in_region_sid					IN 	region.region_sid%TYPE,
	in_entry_val_number				IN 	sheet_value.entry_val_number%TYPE,
	in_entry_conversion_id			IN 	sheet_value.entry_measure_conversion_id%TYPE,
	in_note							IN	sheet_value.note%TYPE,
	in_flag							IN	sheet_value.flag%TYPE,
	in_is_na						IN	sheet_value.is_na%TYPE,
	in_var_expl_ids					IN	security_pkg.T_SID_IDS,
	in_var_expl_note				IN	sheet_value.var_expl_note%TYPE,
	out_changed_inds_cur			OUT	SYS_REFCURSOR
)
AS
	v_entry_val_number				sheet_value.entry_val_number%TYPE := in_entry_val_number;
	v_entry_conversion_id			sheet_value.entry_measure_conversion_id%TYPE := in_entry_conversion_id;
	v_sheet_value_id				sheet_value.sheet_value_id%TYPE;
	v_val_number					sheet_value.val_number%TYPE;
	v_ind_type						ind.ind_type%TYPE;
	v_master_ind_sid				ind.ind_sid%TYPE;
	v_sheet_start_dtm				sheet.start_dtm%TYPE;
	v_changed_ind_sids				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT i.ind_type, isgm.master_ind_sid
	  INTO v_ind_type, v_master_ind_sid
	  FROM ind i
	  LEFT JOIN ind_selection_group_member isgm ON i.ind_sid = isgm.ind_sid
	 WHERE i.ind_sid = in_ind_sid;
		
	-- we allow setting notes / variance explanations against a calc to support an
	-- accidental feature where you can set tolerances on calcs, even though this is nutty
	-- and causes loads of issues
	IF v_ind_type != csr_data_pkg.IND_TYPE_NORMAL THEN
		v_val_number := NULL;
		v_entry_val_number := NULL;
		v_entry_conversion_id := NULL;
	-- work out val number from entry val number
	ELSIF in_entry_val_number IS NOT NULL and in_entry_conversion_id IS NOT NULL THEN
		SELECT start_dtm
		  INTO v_sheet_start_dtm
		  FROM sheet
		 WHERE sheet_id = in_sheet_id;

		v_val_number := measure_pkg.UNSEC_GetBaseValue(in_entry_val_number, in_entry_conversion_id,
			v_sheet_start_dtm);
	ELSE
		v_val_number := in_entry_val_number;
	END IF;
	
	-- if we are setting a value for something that's part of a selection group, then we also need
	-- to clear other members of the selection group
	IF v_master_ind_sid IS NOT NULL THEN
		UPDATE sheet_value
		   SET is_na = in_is_na
		 WHERE ind_sid = v_master_ind_sid
		   AND sheet_id = in_sheet_id
		   AND region_sid = in_region_sid;
	END IF;

	FOR r IN (SELECT ind_sid
				FROM ind_selection_group_member
				WHERE master_ind_sid = v_master_ind_sid
					AND ind_sid != in_ind_sid) LOOP
		SaveValue(
			in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_sheet_id				=> in_sheet_id,
			in_ind_sid				=> r.ind_sid,
			in_region_sid			=> in_region_sid,
			in_val_number			=> NULL,
			in_entry_conversion_id	=> NULL,
			in_entry_val_number		=> NULL,
			in_note					=> NULL,
			in_reason				=> NULL,
			in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
			in_file_count			=> 0,
			in_flag					=> NULL,
			in_write_history		=> 1,
			in_is_na				=> 0,
			out_val_id				=> v_sheet_value_id
		);

		v_changed_ind_sids.EXTEND;
		v_changed_ind_sids(v_changed_ind_sids.COUNT) := r.ind_sid;
	END LOOP;

	SaveValue(
		in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_sheet_id				=> in_sheet_id,
		in_ind_sid				=> in_ind_sid,
		in_region_sid			=> in_region_sid,
		in_val_number			=> v_val_number,
		in_entry_conversion_id	=> v_entry_conversion_id,
		in_entry_val_number		=> v_entry_val_number,
		in_note					=> in_note,
		in_reason				=> NULL,
		in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
		in_file_count			=> 0,
		in_flag					=> in_flag,
		in_write_history		=> 1,
		in_is_na				=> in_is_na,
		out_val_id				=> v_sheet_value_id
	);
				     	
	v_changed_ind_sids.EXTEND;
	v_changed_ind_sids(v_changed_ind_sids.COUNT) := in_ind_sid;
	
	sheet_pkg.UNSEC_setVarExpl(v_sheet_value_id, in_var_expl_ids, in_var_expl_note);
	
	OPEN out_changed_inds_cur FOR
		SELECT column_value ind_sid
		  FROM TABLE(v_changed_ind_sids);
END;

-- you should always write the change history unless you
-- really know what you're doing!!!
-- out_val_id can return NULL if nothing has neen saved (i.e. if val_number, note etc are all null and it's an insert)
PROCEDURE SaveValue(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_sheet_id					IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN 	security_pkg.T_SID_ID,
	in_val_number				IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id		IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number			IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note						IN	SHEET_VALUE.NOTE%TYPE,
	in_reason					IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status					IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count				IN	NUMBER,
	in_flag						IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history			IN	NUMBER,
	in_force_change_reason		IN	NUMBER,
	in_no_check_permission		IN	NUMBER,
	in_is_na					IN	sheet_value.is_na%TYPE,
	in_apply_percent_ownership	IN	NUMBER DEFAULT 1,
	out_cur						OUT	SYS_REFCURSOR,
	out_val_id					OUT	sheet_value.sheet_value_id%TYPE
)
AS
	CURSOR c_update(in_v_sheet_val_id IN sheet_value.sheet_value_id%TYPE) IS
		SELECT sv.val_number, m.description measure_description, NVL(i.format_mask, m.format_mask) format_mask,
			   sv.set_by_user_sid, sv.set_dtm, sv.note,
			   sv.entry_measure_conversion_id, NVL(mc.description, m.description) entry_measure_conversion_desc,
			   sv.entry_val_number, flag, sv.status, sv.is_na
		  FROM sheet_value_converted sv, sheet s, sheet_history sh, sheet_action sa, ind i, measure m, measure_conversion mc
		 WHERE sv.sheet_value_id = in_v_sheet_val_id
		   AND sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
		   AND s.app_sid = sh.app_sid AND s.last_sheet_history_id = sh.sheet_history_id
		   AND sh.sheet_action_id = sa.sheet_action_id
		   AND i.ind_sid = in_ind_sid AND i.measure_sid = m.measure_sid(+)
		   AND sv.app_sid = mc.app_sid(+) AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+);
	r_update 				c_update%ROWTYPE;
	v_sheet_val_id 			sheet_value.sheet_value_id%TYPE;
	v_val_id				sheet_value.val_number%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_db_changed			BOOLEAN;
	v_val_change_id			sheet_value.last_sheet_value_change_id%type;
	v_rounded_in_val_number	val.val_number%type;
	v_inherited_count		NUMBER(10);
	v_sheet					T_SHEET_INFO;
	v_changes				T_CHANGES_TABLE := T_CHANGES_TABLE();
	v_from					VARCHAR2(255);
	v_to					VARCHAR2(255);
	v_entry_val_number 		val.entry_val_number%TYPE;
	v_entry_measure_desc	measure.description%TYPE;
	v_entry_conversion_desc	measure_conversion.description%TYPE;
	v_format_mask			ind.format_mask%TYPE;
	v_note_is_new			NUMBER(1) := 0;
	v_last_history_id		sheet.last_sheet_history_id%TYPE;
	v_last_action_id		sheet_action.sheet_action_id%TYPE;
	v_new_action_id			sheet_action.sheet_action_id%TYPE;
	v_delegation_sid		sheet.delegation_sid%TYPE;
	v_last_from_user_sid	csr_user.csr_user_sid%TYPE;
	v_row_exists			boolean;
	v_valid_conversion		NUMBER(10);
	v_lock_prevents_editing NUMBER(1);
	v_lock_end_dtm			DATE;
BEGIN
	-- TODO: check permissions
	user_pkg.getsid (in_act_id, v_user_sid);
	v_sheet := sheet_pkg.getsheetinfo (in_act_id, in_sheet_id);
	
	SELECT c.lock_prevents_editing, c.lock_end_dtm
	  INTO v_lock_prevents_editing, v_lock_end_dtm
	  FROM customer c;
	
	IF
		NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Can edit forms before system lock date') 
		AND v_sheet.start_dtm < v_lock_end_dtm AND v_lock_prevents_editing = 1
	THEN
		RAISE_APPLICATION_ERROR (CSR_DATA_PKG.ERR_NOT_ALLOWED_WRITE,
					'You are not allowed to write to sheet '|| in_sheet_id || ', data locked.');
	END IF;
	
	-- Data can get into an state that breaks the page if changes to an indicators measures are made
	-- while a delegation form that uses those measures is loaded by another user (or even on a different tab)

	-- This checks to make sure that we have a valid entry conversion measure based on the current indicator

	 IF in_entry_conversion_id IS NOT null THEN
		SELECT count(mc.measure_conversion_id) 
		  INTO v_valid_conversion
		  FROM csr.ind i
		  JOIN csr.measure_conversion mc on mc.measure_sid = i.measure_sid 
		 WHERE i.ind_sid = in_ind_sid
		   AND mc.measure_conversion_id = in_entry_conversion_id;

		IF v_valid_conversion = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Indicator measure has been changed after the form was loaded.');
		END IF;
	END IF;

	-- round it as we'll put it in the database
	-- otherwise we might compare 0.1234567891 against 0.12345678912 and conclude they are different
	-- as to whether 10 is sufficient precision... not sure!!
	v_rounded_in_val_number := ROUND(in_val_number, 10); -- * region_pkg.getPctOwnership(in_ind_sid, in_region_sid, v_sheet.start_dtm),10);

	-- if in_entry_conversion_id is null then put our number into v_entry_val_number since this is the number actually entered (we might have modified val_number for pct ownership)
	IF in_entry_conversion_id IS NULL AND in_apply_percent_ownership = 1 THEN
		v_entry_val_number := in_val_number;
	ELSE
		v_entry_val_number := in_entry_val_number;
	END IF;

	-- get some basic information
	v_sheet_val_id := sheet_pkg.getsheetvalueid (in_sheet_id, in_ind_sid, in_region_sid);
	v_db_changed := FALSE;
	v_row_exists := v_sheet_val_id IS NOT NULL;

	IF NOT v_row_exists THEN
		-- this is a brand new sheet_value row
		/*
		-- RK: now always writes values back as we want the id and we can't return NULL to RunSPReturnInt64
		-- leaving old code in commented out for a week or two (currently it's 24 May 2011).
		IF in_val_number IS NOT NULL OR in_note IS NOT NULL
		   OR (in_file_count IS NOT NULL AND in_file_count > 0) THEN
		*/
		-- apply % ownership to the value
		IF in_apply_percent_ownership = 1 THEN
			v_rounded_in_val_number := ROUND(in_val_number * region_pkg.getPctOwnership(in_ind_sid, in_region_sid, v_sheet.start_dtm), 10);
		END IF;

		BEGIN
			-- new value, get a new value ID
			SELECT sheet_value_id_seq.NEXTVAL
				INTO v_sheet_val_id
				FROM DUAL;
			
			INSERT INTO sheet_value (
				sheet_value_id, sheet_id, ind_sid, region_sid,
				val_number, flag, set_by_user_sid, set_dtm,
				note, entry_measure_conversion_id, entry_val_number,
				is_inherited, status, is_na
			) VALUES (
				v_sheet_val_id, in_sheet_id, in_ind_sid, in_region_sid,
				v_rounded_in_val_number, in_flag, v_user_sid, SYSDATE,
				in_note, in_entry_conversion_id, v_entry_val_number,
				0, in_status, in_is_na
			);
			
			IF csr_data_pkg.HasUnmergedScenario THEN
				csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
				MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
				USING (SELECT start_dtm, end_dtm
						FROM sheet
					   WHERE sheet_id = in_sheet_id) s
					ON (svcl.ind_sid = in_ind_sid)
				 WHEN MATCHED THEN
					UPDATE
					   SET svcl.start_dtm = LEAST(svcl.start_dtm, s.start_dtm),
						   svcl.end_dtm = GREATEST(svcl.end_dtm, s.end_dtm)
				 WHEN NOT MATCHED THEN
					INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
					VALUES (in_ind_sid, s.start_dtm, s.end_dtm);
			END IF;

			v_db_changed := TRUE;
		EXCEPTION  -- This is sometimes (rarely) caused by a row being inserted in the time between the initial check and this insert.
			WHEN DUP_VAL_ON_INDEX THEN

		-- get some basic information(again)
			v_sheet_val_id := sheet_pkg.getsheetvalueid (in_sheet_id, in_ind_sid, in_region_sid);
			v_row_exists := TRUE;
		
		END;
	ELSE
		--  there's a row already in SHEET_VALUE then.
		OPEN c_update (v_sheet_val_id);

		FETCH c_update
		 INTO r_update;

		CLOSE c_update;
		-- check that the user really has changed the value or the note or the conversion etc

		-- get the units + format mask for the new value
		SELECT m.description, NVL(i.format_mask, m.format_mask) format_mask
		  INTO v_entry_measure_desc, v_format_mask
		  FROM ind i, measure m
		 WHERE i.ind_sid = in_ind_sid
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+);

		-- Value
		IF null_pkg.ne(v_rounded_in_val_number, r_update.val_number) THEN

			-- value has changed?
			v_changes.EXTEND;
			v_changes(v_changes.COUNT) := t_changes_row(
				csr_data_pkg.CHANGE_TYPE_VALUE,
				r_update.val_number,
				r_update.format_mask,
				r_update.measure_description,
				in_val_number,
				v_format_mask,
				v_entry_measure_desc,
				v_sheet_val_id);
		END IF;

		IF null_pkg.ne(v_entry_val_number, r_update.entry_val_number) OR
		   null_pkg.ne(in_entry_conversion_id, r_update.entry_measure_conversion_id) THEN

			-- Get the units that the value was entered in
			IF in_entry_conversion_id IS NOT NULL THEN
				SELECT description
				  INTO v_entry_conversion_desc
				  FROM measure_conversion
				 WHERE measure_conversion_id = in_entry_conversion_id;
			END IF;

		   	-- entry value has changed
		   	v_changes.EXTEND;
		   	v_changes(v_changes.COUNT) := t_changes_row(
		   		csr_data_pkg.CHANGE_TYPE_ENTERED_VALUE,
				r_update.entry_val_number,
				r_update.format_mask,
				r_update.entry_measure_conversion_desc,
				v_entry_val_number,
				v_format_mask,
				NVL(v_entry_conversion_desc, v_entry_measure_desc),
				v_sheet_val_id);
		END IF;

		-- Flags
		IF null_pkg.ne(in_flag, r_update.flag) THEN
			v_from := 'Nothing';

			IF r_update.flag IS NOT NULL THEN
				SELECT description
				  INTO v_from
				  FROM ind_flag
				 WHERE ind_sid = in_ind_sid
				   AND flag = r_update.flag;
			END IF;

			v_to := 'Nothing';

			IF in_flag IS NOT NULL THEN
				SELECT description
				  INTO v_to
				  FROM ind_flag
				 WHERE ind_sid = in_ind_sid
				   AND flag = in_flag;
			END IF;

			-- flag has changed
			v_changes.EXTEND;
			v_changes(v_changes.COUNT) := t_changes_row(
				csr_data_pkg.CHANGE_TYPE_FLAG,
				r_update.flag,
				NULL,
				v_from,
				in_flag,
				NULL,
				v_to,
				v_sheet_val_id);
		END IF;

		-- File uploads
		-- We can't realistically tell from here what has changed, that
		-- information will be filled in later on by the file upload code.
		-- There is no need to fill in a change if the file uploads have changed.
		-----

		-- this is shagged with crlf in it I think
		-- has the note changed or been removed. Not a "change" if the note was not set before and has been set now
		IF 	(NVL(LENGTH(r_update.note),0) > 0) AND
			((REPLACE(in_note,CHR(13),'') != REPLACE(r_update.note,CHR(13),'')) OR
			(in_note IS NULL AND NVL(LENGTH(r_update.note),0) > 0)) THEN

			-- note has changed (we pass through nulls)
			v_changes.EXTEND;
			v_changes (v_changes.COUNT) := t_changes_row(
				csr_data_pkg.CHANGE_TYPE_NOTE,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				v_sheet_val_id
			);
		END IF;

		-- we do need to flag if the note is new however as we need to save it in the same way
		IF in_note IS NOT NULL AND NVL(LENGTH(r_update.note),0) = 0 THEN
			v_note_is_new := 1;
		END IF;

		-- this has actually changed...
		IF v_changes.COUNT > 0 THEN
			IF in_no_check_permission != 1 AND v_sheet.can_save = 0 AND v_sheet.can_explain = 0 THEN
				-- this person can't write to the sheet in this state
				RAISE_APPLICATION_ERROR (CSR_DATA_PKG.ERR_NOT_ALLOWED_WRITE,
					'You are not allowed to write to sheet '|| in_sheet_id);
			END IF;

			 -- if reason is null and value is currently accepted then return change
			IF in_force_change_reason = 1 AND in_reason IS NULL AND r_update.status NOT IN (csr_data_pkg.SHEET_VALUE_ENTERED) THEN
				OPEN out_cur FOR
					 SELECT change_type, from_value, from_format_mask, from_description,
					 		to_value, to_format_mask, to_description, sheet_value_id
					   FROM TABLE (v_changes);
				RETURN;
			END IF;
		END IF;

		-- apply % ownership to the value
		IF in_apply_percent_ownership = 1 THEN
			v_rounded_in_val_number := ROUND(in_val_number * region_pkg.getPctOwnership(in_ind_sid, in_region_sid, v_sheet.start_dtm), 10);
		END IF;

		-- Is N/a
		IF null_pkg.ne(in_is_na, r_update.is_na) THEN
			-- is_na has changed
			v_changes.EXTEND;
			v_changes(v_changes.COUNT) := t_changes_row(
				csr_data_pkg.CHANGE_TYPE_IS_NA,
				r_update.is_na,
				NULL,
				NULL,
				in_is_na,
				NULL,
				NULL,
				v_sheet_val_id);
		END IF;		

		-- if we've got a change of some sort (inc. a new note) then save
		IF v_note_is_new = 1 OR v_changes.COUNT > 0 THEN
			 SELECT COUNT(*)
			   INTO v_inherited_count
			   FROM sheet_inherited_value
			  WHERE sheet_value_id = v_sheet_val_id;

			 IF v_inherited_count > 0 THEN
				-- clear inherited values since we're breaking the inheritence chain
				DELETE FROM sheet_inherited_value
				 WHERE sheet_value_id = v_sheet_val_id;
			 END IF;

			UPDATE sheet_value
			   SET val_number = v_rounded_in_val_number,
				   set_by_user_sid = v_user_sid,
				   set_dtm = SYSDATE,
				   entry_measure_conversion_id = in_entry_conversion_id,
				   entry_val_number = v_entry_val_number,
				   note = in_note,
				   status = in_status,
				   flag = in_flag,
				   is_inherited = 0, -- mark as not inherited any more
				   is_na = in_is_na
			 WHERE sheet_value_id = v_sheet_val_id;

			IF csr_data_pkg.HasUnmergedScenario THEN
				csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);
				MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
				USING (SELECT start_dtm, end_dtm
				  		 FROM sheet
				  		WHERE sheet_id = in_sheet_id) s
				   ON (svcl.ind_sid = in_ind_sid)
				 WHEN MATCHED THEN
					UPDATE
					   SET svcl.start_dtm = LEAST(svcl.start_dtm, s.start_dtm),
						   svcl.end_dtm = GREATEST(svcl.end_dtm, s.end_dtm)
				 WHEN NOT MATCHED THEN
					INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
					VALUES (in_ind_sid, s.start_dtm, s.end_dtm);
			END IF;

			v_db_changed := TRUE;
		END IF;
	END IF;

	-- if we've actually changed something then write a row to the history table
	-- it is possible to skip this (e.g. the propagation stuff does this in order to write
	-- the first row, and then update it later once we know the total. The first row has to
	-- be written in order to then write rows to the inherited_value table

	-- TODO: track file upload history during the process that saves multi file uploads

	IF v_db_changed AND in_write_history = 1 THEN
		INSERT INTO sheet_value_change
					(sheet_value_change_id, sheet_value_id,
					 ind_sid, region_sid, reason, flag,
					 changed_by_sid, changed_dtm, val_number,
					 entry_val_number, entry_measure_conversion_id, note
					 --,file_upload_sid
					)
			 VALUES (sheet_value_change_id_seq.NEXTVAL, v_sheet_val_id,
					 in_ind_sid, in_region_sid, in_reason, in_flag,
					 v_user_sid, SYSDATE, v_rounded_in_val_number,
					 v_entry_val_number, in_entry_conversion_id, in_note
					)
		RETURNING sheet_value_change_id
			 INTO v_val_change_id;							-- 1 = set value

		UPDATE sheet_value
		   SET last_sheet_value_change_id = v_val_change_id
		 WHERE sheet_value_id = v_sheet_val_id;

		-- do we need to update the sheet history as a result of this change?
		SELECT last_sheet_history_id, delegation_sid
		  INTO v_last_history_id, v_delegation_sid
		  FROM sheet
		 WHERE sheet_id = in_sheet_id;

		SELECT from_user_sid, sheet_action_id
		  INTO v_last_from_user_sid, v_last_action_id
		  FROM sheet_history
		 WHERE sheet_history_id = v_last_history_id;

		IF v_last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD) THEN
			v_new_action_id := csr_data_pkg.ACTION_WAITING_WITH_MOD;
		ELSIF v_last_action_id IN (csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_MERGED_WITH_MOD) THEN
			v_new_action_id := csr_data_pkg.ACTION_MERGED_WITH_MOD;
		ELSIF v_last_action_id IN (csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD) THEN
			v_new_action_id := csr_data_pkg.ACTION_SUBMITTED_WITH_MOD;
		ELSIF v_last_action_id IN (csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD) THEN
			v_new_action_id := csr_data_pkg.ACTION_RETURNED_WITH_MOD;
		ELSE
			v_new_action_id := csr_data_pkg.ACTION_ACCEPTED_WITH_MOD;
		END IF;

		-- Add a new history entry if there isn't one for this action from this user
		IF v_new_action_id != v_last_action_id OR v_user_sid != v_last_from_user_sid THEN
			sheet_pkg.CreateHistory(in_sheet_id, v_new_action_id, v_user_sid, v_delegation_sid, '');
		END IF;
	END IF;

	-- XXX: we could skip this for new sheets code?
	-- always update alerts in case the database has changed
	-- this prevents FB1315, where submitting a fully delegated form
	-- automatically tries to submit the parent, but alerts are only updated
	-- in the parent sheet, and the fields that need notes are not flagged
	-- to the user trying to submit the form
	updateAlerts(in_ind_sid,
				 in_region_sid,
				 in_val_number, -- don't include pct ownership
				 in_sheet_id);

	out_val_id := v_sheet_val_id;

	OPEN out_cur FOR
		SELECT NULL change_type, NULL from_value, NULL from_format_mask, NULL from_description,
			   NULL to_value, NULL to_format_mask, NULL to_description
		  FROM DUAL
		 WHERE 1 = 0;
END;

PROCEDURE HideValue(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_sheet_value_id				sheet_value.sheet_value_id%TYPE;
	v_val_number					sheet_value.val_number%TYPE;
	v_entry_val_number				sheet_value.entry_val_number%TYPE;
	v_entry_measure_conversion_id	sheet_value.entry_measure_conversion_id%TYPE;
	v_note							sheet_value.note%TYPE;
	v_hidden_count					NUMBER;
BEGIN
	v_app_sid	:= SYS_CONTEXT('SECURITY','APP');

	SELECT sheet_value_id, val_number, entry_val_number, entry_measure_conversion_id, note
	  INTO v_sheet_value_id, v_val_number, v_entry_val_number, v_entry_measure_conversion_id, v_note
	  FROM sheet_value
	 WHERE app_sid = v_app_sid AND sheet_id = in_sheet_id
	   AND ind_sid = in_ind_sid AND region_sid = in_region_sid;

	-- Check if the value is already cached
	SELECT COUNT(*)
	  INTO v_hidden_count
	  FROM sheet_value_hidden_cache
	 WHERE app_sid = v_app_sid AND sheet_value_id = v_sheet_value_id;

	IF v_hidden_count = 0 THEN
		INSERT INTO sheet_value_hidden_cache
			(app_sid, sheet_value_id, val_number, entry_val_number, entry_measure_conversion_id, note)
		VALUES
			(v_app_sid, v_sheet_value_id, v_val_number, v_entry_val_number, v_entry_measure_conversion_id, v_note);

		delegation_pkg.SaveValue(
			in_act_id				=> security_pkg.getact,
			in_sheet_id				=> in_sheet_id,
			in_ind_sid				=> in_ind_sid,
			in_region_sid			=> in_region_sid,
			in_val_number			=> null,
			in_entry_conversion_id	=> null,
			in_entry_val_number		=> null,
			in_note					=> null,
			in_reason				=> 'Hidden',
			in_file_count			=> 0,
			in_flag					=> null,
			in_write_history		=> 1,
			out_val_id				=> v_sheet_value_id);
	END IF;
		
	FOR R IN (
		SELECT app_sid, sheet_value_id, file_upload_sid
		  FROM sheet_value_file
		 WHERE sheet_value_id = v_sheet_value_id
	) LOOP
		INSERT INTO sheet_value_file_hidden_cache (app_sid, sheet_value_id, file_upload_sid)
		VALUES (r.app_sid, r.sheet_value_id, r.file_upload_sid);
		
		sheet_pkg.RemoveFileUpload(
			in_act_id 			=> security_pkg.getact,
			in_sheet_value_id	=> r.sheet_value_id,
			in_file_upload_sid	=> r.file_upload_sid);
	END LOOP;
END;

PROCEDURE UnhideValue(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_sheet_value_id		sheet_value.sheet_value_id%TYPE;
	v_hidden_count			NUMBER;
	v_file_count			NUMBER;
	v_val_number			SHEET_VALUE.VAL_NUMBER%TYPE;
	v_entry_conversion_id	SHEET_VALUE.entry_measure_conversion_id%TYPE;
	v_entry_val_number		SHEET_VALUE.entry_val_number%TYPE;
	v_note					SHEET_VALUE.NOTE%TYPE;
BEGIN
	v_app_sid	:= SYS_CONTEXT('SECURITY','APP');

	-- Check that there is a cached value
	SELECT COUNT(*)
	  INTO v_hidden_count
	  FROM sheet_value_hidden_cache svhc
	  JOIN sheet_value sv ON svhc.sheet_value_id = sv.sheet_value_id
	 WHERE sv.app_sid = v_app_sid AND sv.sheet_id = in_sheet_id
	   AND sv.ind_sid = in_ind_sid AND sv.region_sid = in_region_sid;
	
	SELECT COUNT(*)
	  INTO v_file_count
	  FROM sheet_value_file_hidden_cache svfhc
	  JOIN sheet_value sv ON svfhc.sheet_value_id = sv.sheet_value_id
	 WHERE sv.app_sid = v_app_sid AND sv.sheet_id = in_sheet_id
	   AND sv.ind_sid = in_ind_sid AND sv.region_sid = in_region_sid;
	
	IF v_hidden_count = 1 THEN
		SELECT sv.sheet_value_id, svhc.val_number, svhc.entry_val_number,
			   svhc.entry_measure_conversion_id, svhc.note
		  INTO v_sheet_value_id, v_val_number, v_entry_val_number, v_entry_conversion_id, v_note
		  FROM sheet_value sv
		  LEFT JOIN sheet_value_hidden_cache svhc
			ON sv.app_sid = svhc.app_sid AND sv.sheet_value_id = svhc.sheet_value_id
		 WHERE sv.app_sid = v_app_sid AND sv.sheet_id = in_sheet_id
		   AND sv.ind_sid = in_ind_sid AND sv.region_sid = in_region_sid;

		DELETE FROM sheet_value_hidden_cache
		 WHERE app_sid = v_app_sid AND sheet_value_id = v_sheet_value_id;

		delegation_pkg.SaveValue(
			in_act_id				=> security_pkg.getact,
			in_sheet_id				=> in_sheet_id,
			in_ind_sid				=> in_ind_sid,
			in_region_sid			=> in_region_sid,
			in_val_number			=> v_val_number,
			in_entry_conversion_id	=> v_entry_conversion_id,
			in_entry_val_number		=> v_entry_val_number,
			in_note					=> v_note,
			in_reason				=> 'Unhidden',
			in_file_count			=> v_file_count,
			in_flag					=> null,
			in_write_history		=> 1,
			out_val_id				=> v_sheet_value_id);
	ELSE
		SELECT val_number, entry_val_number, entry_measure_conversion_id, note
		  INTO v_val_number, v_entry_val_number, v_entry_conversion_id, v_note
		  FROM dual d
		  LEFT JOIN sheet_value
		    ON app_sid = v_app_sid AND sheet_id = in_sheet_id
		   AND ind_sid = in_ind_sid AND region_sid = in_region_sid;
	END IF;
		
	FOR R IN (
		SELECT app_sid, sheet_value_id, file_upload_sid
		  FROM sheet_value_file_hidden_cache
		 WHERE sheet_value_id = v_sheet_value_id
	) LOOP
		sheet_pkg.AddFileUpload(
			in_act_id 			=> security_pkg.getact,
			in_sheet_value_id	=> r.sheet_value_id,
			in_file_upload_sid	=> r.file_upload_sid);
			
		DELETE FROM sheet_value_file_hidden_cache
		WHERE app_sid = r.app_sid
		  AND sheet_value_id = r.sheet_value_id
		  AND file_upload_sid = r.file_upload_sid; 		
	END LOOP;
	
	OPEN out_cur_files FOR
		SELECT svf.sheet_value_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM sheet_value_file svf, file_upload fu
		 WHERE svf.sheet_value_id = v_sheet_value_id
		   AND fu.file_upload_sid = svf.file_upload_sid;
	
	OPEN out_cur FOR
		SELECT v_val_number AS val_number, v_entry_conversion_id AS entry_conversion_id, v_entry_val_number AS entry_val_number, v_note AS note
		  FROM dual;
		  
END;

-- utility procedure (do not call from your code!) which fixes up the
-- sheet_inherited_value table for a given root delegation

-- NOTE: this will fix up the chain, but won't re-aggregate values
PROCEDURE FixSheetInheritedValues(
	in_delegation_sid	IN	security_pkg.T_SID_ID
)
AS
	v_cnt	NUMBER(10) := 0;
BEGIN
    FOR r IN (
        -- gets sheets AND regions in a hierarchy
        SELECT d.delegation_sid, d.parent_sid, s.sheet_id, prior sheet_id parent_sheet_id,
               s.start_dtm, s.end_dtm, dr.region_sid, dr.aggregate_to_region_sid, level lvl
          FROM delegation d
          JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
          JOIN sheet s ON d.delegation_sid = s.delegation_sid
         	   START WITH d.delegation_sid = in_delegation_sid
       		   CONNECT BY PRIOR d.app_sid = d.app_sid AND PRIOR d.delegation_sid = d.parent_sid
           AND s.start_dtm >= prior s.start_dtm
           AND s.end_dtm <= prior s.end_dtm
           AND prior dr.region_sid = dr.aggregate_to_region_sid
           AND prior dr.delegation_sid = d.parent_sid
         ORDER SIBLINGS BY start_dtm
    )
    LOOP
    	--dbms_output.put_line('processing sheet'||r.sheet_id);
        -- WHERE the numbers match, then it's inherited. Otherwise it's not
        FOR rr IN (
            SELECT pv.ind_sid, pv.sheet_value_id, pv.parent_val_number, cv.aggr_child_val_number,
				   cv.ind_sid child_ind_sid, -- will be null if no child items
				   cv.child_value_ids
              FROM (
                -- get the parent values
                SELECT sv.ind_sid, sv.sheet_value_id, val_number parent_val_number
                  FROM sheet_value sv, ind i
                 WHERE sv.region_sid = r.aggregate_to_region_sid
                   AND sv.sheet_id = r.parent_sheet_id
                   AND sv.ind_sid = i.ind_sid
              )pv, (
                -- get the aggregated child sheet values
                SELECT ind_sid, sum(child_val_number) aggr_child_val_number, stragg(sheet_value_id) child_value_ids
                  FROM (
                    SELECT sv.ind_sid, sv.sheet_value_id,
                        CASE
                            WHEN i.aggregate in ('SUM','FORCE SUM') then val_number -- parent region is aggregate
                            WHEN dr.aggregate_to_region_sid = dr.region_sid then val_number -- no aggregation
                            ELSE null
                        END child_val_number
                      FROM sheet_value sv, sheet s, delegation d, delegation_region dr, ind i
                     WHERE sv.sheet_id = s.sheet_id
                       AND s.delegation_sid = d.delegation_sid
                       AND d.delegation_sid = dr.delegation_sid
                       AND dr.region_sid = sv.region_sid
                       AND sv.ind_sid = i.ind_sid
                       AND dr.aggregate_to_region_sid = r.aggregate_to_region_sid
                       AND sv.sheet_id = r.sheet_id
                  )
                 group by ind_sid
              )cv
            WHERE pv.ind_sid = cv.ind_sid(+) -- something might not have been subdelegated
        )
        LOOP
        	--dbms_output.put_line('processing sheet ' ||r.sheet_id||', ind '||rr.ind_sid);
            DELETE FROM sheet_inherited_value
             WHERE sheet_value_id = rr.sheet_value_id;

            IF rr.child_ind_sid IS NOT NULL -- must be child items present
				AND (
					rr.parent_val_number = rr.aggr_child_val_number
					OR (rr.parent_val_number is null AND rr.aggr_child_val_number is null)
				) THEN
				--dbms_output.put_line('sheet_id='||r.sheet_id||',sheet_value_id='||rr.sheet_value_id||',parent values='||rr.child_value_ids);

                -- write in values as it's inherited
				INSERT INTO sheet_inherited_value (sheet_value_id, inherited_value_id)
					SELECT rr.sheet_value_id, item inherited_value_id
					  FROM TABLE(utils_pkg.SplitString(rr.child_value_ids,','));

                -- mark up parent to say that it was inherited
                UPDATE sheet_value
                   SET is_inherited = 1
                 WHERE sheet_value_id = rr.sheet_value_id;
            ELSE
                -- SET parent value to say that it was NOT inherited (i.e. it was manually overridden)
                UPDATE sheet_value
                   SET is_inherited = 0
                 WHERE sheet_value_id = rr.sheet_value_id;
            END IF;
        END LOOP;
    END LOOP;
END;

-- would this value trigger any alerts?
-- has to be based around previous value? i.e. n% upon
-- previous month / year / week etc
PROCEDURE UpdateAlerts(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_val_number	IN 	VAL.val_number%TYPE,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE
)
AS
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
	v_period						CHAR(1);
	v_this_start_dtm				DATE;
	v_this_end_dtm					DATE;
	v_check_start_dtm				DATE;
	v_check_end_dtm					DATE;
	CURSOR c(in_check_Start_dtm date, in_check_end_dtm date) IS
		SELECT v.val_id, v.val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
		  FROM val_converted v
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid
		   AND period_start_dtm = in_check_start_dtm
		   AND period_end_dtm = in_check_end_dtm;
	r								c%ROWTYPE;
	CURSOR c_win IS
		SELECT upper_bracket, lower_bracket, comparison_offset
		  FROM ind_window
		 WHERE ind_sid = in_ind_sid
		   AND period = v_period;	-- Are we sure we only alerts if period is defined in ind_window?
	CURSOR c_sheet(in_check_Start_dtm date, in_check_end_dtm date) IS
        SELECT sv.sheet_value_id, sv.val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
		  FROM sheet_value_converted sv, sheet s
         WHERE sv.sheet_id = s.sheet_id
           AND sv.ind_sid = in_ind_sid
           AND sv.region_sid = in_region_sid
           AND s.delegation_sid = (SELECT delegation_sid FROM sheet WHERE sheet_id = in_sheet_id)
           AND s.start_dtm = in_check_start_dtm
           AND s.end_dtm = in_check_end_dtm
           AND s.is_visible = 1 -- check visible otherwise it's unfair!
           AND status = csr_data_pkg.SHEET_VALUE_ACCEPTED;
	r_sheet							c_sheet%ROWTYPE;
	-- This cursor will return all the values that has been accepted OR merged
	-- It also relies in the fact that sheet_id(s) at the bottom of the delegation tree will be always higher than those ones above.
	-- (order by sheet_id desc). This should be the case?
	CURSOR c_delegation(in_check_Start_dtm date, in_check_end_dtm date) IS
        SELECT /*+ALL_ROWS*/ sv.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
               sv.sheet_value_id
		  FROM sheet_value_converted sv, sheet s
		 WHERE sv.ind_sid = in_ind_sid
		   AND sv.region_sid = in_region_sid
		   AND s.start_dtm = in_check_start_dtm
		   AND s.end_dtm = in_check_end_dtm
		   AND sv.sheet_id = s.sheet_id
		   AND s.is_visible = 1 -- check visible otherwise it's unfair
		   AND status in (csr_data_pkg.SHEET_VALUE_ACCEPTED, csr_data_pkg.SHEET_VALUE_MERGED)
		 ORDER BY s.sheet_ID;
	v_found BOOLEAN;
BEGIN
	SELECT period_set_id, period_interval_id, s.start_dtm, s.end_dtm
	  INTO v_period_set_id, v_period_interval_id, v_this_start_dtm, v_this_end_dtm
	  FROM delegation d, sheet s
	 WHERE s.sheet_id = in_sheet_id
	   AND d.delegation_sid = s.delegation_sid;

	-- Blank the alert initally. If no alert condition is found then the alert should always be cleared.
	UPDATE sheet_value SET alert=null
		 WHERE ind_sid = in_ind_sid
		 	AND region_sid = in_region_sid
		 	AND sheet_id = in_sheet_id;

	FOR r_win IN c_win LOOP
		-- get previous period into v_check_Start_dtm, v_check_end_Dtm
		val_pkg.GetPeriod(v_this_start_dtm, v_this_end_dtm, r_win.comparison_offset, v_check_start_dtm, v_check_end_dtm);
		-- First we check if there exists a value for the previous period in VAL
		OPEN c(v_check_Start_dtm, v_check_end_dtm);
		FETCH c INTO r;
		v_found := c%FOUND;
		CLOSE c;
		IF v_found THEN
			UPDATE SHEET_VALUE
				 SET alert = CASE
				 		WHEN in_val_number > r.val_number*r_win.upper_bracket THEN
							'Value more than '||(r_win.upper_bracket*100)||'% of previous value ('||r.val_number||')' -- - based on val_id '||r.val_id
						WHEN in_val_number < r.val_number*r_win.lower_bracket THEN
							'Value less than '||(r_win.lower_bracket*100)||'% of previous value ('||r.val_number||')' -- - based on val_id '||r.val_id
					ELSE NULL END
				 WHERE ind_sid = in_ind_sid
					 AND region_sid = in_region_sid
					 AND sheet_id = in_sheet_id;
		ELSE
			-- Secondly, we check if there exists a sheet for the previous period and if it has a value.
			OPEN c_sheet(v_check_Start_dtm, v_check_end_dtm);
			FETCH c_sheet INTO r_sheet;
			v_found := c_sheet%FOUND;
			CLOSE c_sheet;
			IF v_found THEN
				UPDATE SHEET_VALUE
					 SET alert = CASE
					 		WHEN in_val_number > r_sheet.val_number*r_win.upper_bracket THEN
								'Value more than '||(r_win.upper_bracket*100)||'% of previous value ('||r_sheet.val_number||')' -- based on sheet_value_id '||r_sheet.sheet_value_Id
							WHEN in_val_number < r_sheet.val_number*r_win.lower_bracket THEN
								'Value less than '||(r_win.lower_bracket*100)||'% of previous value ('||r_sheet.val_number||')' -- - based on sheet_value_id '||r_sheet.sheet_value_Id
						ELSE NULL END
					 WHERE ind_sid = in_ind_sid
						 AND region_sid = in_region_sid
						 AND sheet_id = in_sheet_id;
			ELSE
				-- Ultimately we check for a value for the previous period from the appropiate TopLevelDelegation down to bottom (delegation tree)
				-- If father has a value, we can compared with that.
				FOR r_delegation IN c_delegation(v_check_Start_dtm, v_check_end_dtm)
				LOOP
					UPDATE SHEET_VALUE
						 SET alert = CASE
						 		WHEN in_val_number > r_delegation.val_number*r_win.upper_bracket THEN
									'Value more than '||(r_win.upper_bracket*100)||'% of previous value ('||r_delegation.val_number||')' -- : based on sheet_value_id '||r_delegation.sheet_value_Id
								WHEN in_val_number < r_delegation.val_number*r_win.lower_bracket THEN
									'Value less than '||(r_win.lower_bracket*100)||'% of previous value ('||r_delegation.val_number||')' -- - based on sheet_value_id '||r_delegation.sheet_value_Id
							ELSE NULL END
						 WHERE ind_sid = in_ind_sid
							 AND region_sid = in_region_sid
							 AND sheet_id = in_sheet_id;
					EXIT;
				END LOOP;
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE GetQuickChartIndRegionDetail(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_ind_sid						IN	delegation_ind.ind_sid%TYPE,
	in_region_sid					IN	delegation_region.region_sid%TYPE,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the delegation with sid '||in_delegation_sid);
	END IF;

	OPEN out_ind_cur FOR
		SELECT di.ind_sid, di.description, nvl(i.format_mask, m.format_mask) format_mask,
			   NVL(i.scale, m.scale) scale, i.period_set_id, i.period_interval_id,
			   i.do_temporal_aggregation, i.calc_description,
			   i.calc_xml,
			   i.measure_sid, i.aggregate, i.active, i.start_month, i.gri, i.target_direction,
			   i.pct_lower_tolerance, i.pct_upper_tolerance, i.tolerance_type,
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize,
			   m.description measure_description, m.option_set_id,
			   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.parent_sid, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp,
			   i.multiplier, extract(i.info_xml,'/').getClobVal() info_xml, i.ind_type,	di.pos, m.custom_field,
			   i.divisibility actual_divisibility,
			   NVL(i.divisibility, m.divisibility) divisibility,
			   CASE WHEN (di.mandatory = 1 AND d.allocate_users_to = 'region') THEN 1 ELSE 0 END mandatory,
			   di.section_key, i.lookup_key
		  FROM v$delegation_ind di, ind i, delegation d, measure m
		 WHERE di.delegation_sid = in_delegation_sid AND di.ind_sid = in_ind_sid
		   AND i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
		   AND di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+);

	OPEN out_region_cur FOR
		SELECT dr.region_sid, dr.description, dr.pos, 1 active, extract(r.info_xml,'/').getClobVal() info_xml,
			   CASE WHEN (dr.mandatory = 1 AND d.allocate_users_to = 'indicator') THEN 1 ELSE 0 END mandatory,
			   r.parent_sid, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id,
			   r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_Ref,
			   dr.aggregate_to_region_sid
		  FROM v$delegation_region dr, region r, delegation d
		 WHERE dr.delegation_sid = in_delegation_sid AND dr.region_sid = in_region_sid
		   AND r.app_sid = dr.app_sid AND r.region_sid = dr.region_sid
		   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.delegation_sid;
END;

PROCEDURE GetMergedValueCount(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_merged				OUT	NUMBER
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the delegation with sid '||in_delegation_sid);
	END IF;

	-- we could check source type IDs but they have a habit of coming unstuck and then this returns 0
    SELECT count(*)
	  INTO out_merged
	  FROM val
	 WHERE (ind_sid, region_sid, period_start_dtm, period_end_dtm, NVL(val_number,-123456789)) in (
		SELECT sv.ind_sid, sv.region_sid, s.start_dtm, s.end_dtm, NVL(sv.val_number,-123456789) -- urr -- can't really see this going too horribly wrong
		  FROM delegation d
			JOIN sheet s ON d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
			JOIN sheet_value sv ON s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
		 WHERE d.delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
			 START WITH delegation_sid = in_delegation_sid
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		 )
	);
END;

PROCEDURE Flip(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the delegation with sid '||in_delegation_sid);
	END IF;

	UPDATE delegation
	    SET group_by = CASE WHEN group_by = 'region,indicator' THEN 'indicator,region' ELSE 'region,indicator' END
	 WHERE delegation_sid = in_delegation_sid;
END;

PROCEDURE GetTerminatedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_DELEG_TERMINATED);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ dta.deleg_terminated_alert_id, dta.notify_user_sid, cuf.full_name terminated_by_full_name,
			   cu.full_name, cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, dta.app_sid,
        	   d.name delegation_name, dd.description delegation_description, cuf.email terminated_by_email, d.delegation_sid,
        	   dta.raised_by_user_sid, 
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM delegation_terminated_alert dta
		  JOIN csr_user cu ON dta.app_sid = cu.app_sid AND dta.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN csr_user cuf ON dta.app_sid = cuf.app_sid AND dta.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON dta.app_sid = d.app_sid AND d.delegation_sid = dta.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		  JOIN customer c ON dta.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_DELEG_TERMINATED
		   AND c.scheduled_tasks_disabled = 0
		 UNION
		SELECT /*+ALL_ROWS*/ dta.deleg_terminated_alert_id, dta.notify_user_sid, cuf.full_name terminated_by_full_name,
			   cu.full_name, cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, dta.app_sid,
        	   d.name delegation_name, ddd.description delegation_description, cuf.email terminated_by_email, d.delegation_sid,
        	   dta.raised_by_user_sid, 0 region_count, null region_names
		  FROM delegation_terminated_alert dta
		  JOIN csr_user cu ON dta.app_sid = cu.app_sid AND dta.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN deleted_delegation d ON dta.app_sid = d.app_sid AND d.delegation_sid = dta.delegation_sid
		  JOIN csr_user cuf ON dta.app_sid = cuf.app_sid AND dta.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid
		  LEFT JOIN deleted_delegation_description ddd ON
			   ddd.app_sid = d.app_sid AND 
			   ddd.delegation_sid = d.delegation_sid AND 
			   ddd.lang = NVL(ut.language, 'en')
		  JOIN customer c on dta.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_DELEG_TERMINATED
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY app_sid, csr_user_sid;
END;

PROCEDURE RecordTerminatedAlertSent(
	in_deleg_terminated_alert_id		IN delegation_terminated_alert.deleg_terminated_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM delegation_terminated_alert
	 WHERE deleg_terminated_alert_id = in_deleg_terminated_alert_id;
END;

PROCEDURE GetNewAlerts(
	in_alert_pivot_dtm				IN DATE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(
		in_std_alert_type_id => csr_data_pkg.ALERT_NEW_DELEGATION, 
		in_alert_pivot_dtm => in_alert_pivot_dtm);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ nda.new_delegation_alert_id, nda.notify_user_sid, cuf.full_name delegator_full_name, cu.full_name,
			   cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, nda.app_sid,
        	   d.name delegation_name, dd.description delegation_description, 
			   s.submission_dtm, cuf.email delegator_email, d.delegation_sid, s.sheet_id, 
        	   d.editing_url||'sheetid='||s.sheet_id sheet_url,
        	   delegation_pkg.ConcatDelegationUsers(d.delegation_sid, 10) deleg_assigned_to,
        	   s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
        	   nda.raised_by_user_sid,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM new_delegation_alert nda
		  JOIN csr_user cu ON nda.app_sid = cu.app_sid AND nda.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet s ON nda.app_sid = s.app_sid AND s.sheet_id = nda.sheet_id
		  JOIN csr_user cuf ON nda.app_sid = cuf.app_sid AND nda.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON nda.app_sid = tabr.app_sid AND nda.notify_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		  JOIN customer c on nda.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_NEW_DELEGATION
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE GetNewAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetNewAlerts(
		in_alert_pivot_dtm => systimestamp,
		out_cur => out_cur
	);
END;

PROCEDURE RecordNewAlertSent(
	in_alert_id		IN	new_delegation_alert.new_delegation_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM new_delegation_alert
	 WHERE new_delegation_alert_id = in_alert_id;
END;

PROCEDURE GetNewPlannedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_NEW_PLANNED_DELEG);

	OPEN out_cur FOR 
		SELECT /*+ALL_ROWS*/ nda.new_planned_deleg_alert_id, nda.notify_user_sid, cuf.full_name delegator_full_name, cu.full_name, 
			   cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, nda.app_sid,
        	   d.name delegation_name, 
			   dd.description delegation_description, 
			   s.submission_dtm, TO_CHAR(s.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, cuf.email delegator_email, 
        	   d.delegation_sid, s.sheet_id, 
        	   d.editing_url||'sheetid='||s.sheet_id sheet_url,
        	   delegation_pkg.ConcatDelegationUsers(d.delegation_sid, 10) deleg_assigned_to,
        	   s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
        	   nda.raised_by_user_sid,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM new_planned_deleg_alert nda
		  JOIN csr_user cu ON nda.app_sid = cu.app_sid AND nda.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet s ON nda.app_sid = s.app_sid AND s.sheet_id = nda.sheet_id
		  JOIN csr_user cuf ON nda.app_sid = cuf.app_sid AND nda.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON nda.app_sid = tabr.app_sid AND nda.notify_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		  JOIN customer c ON nda.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_NEW_PLANNED_DELEG
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;        
END;

PROCEDURE RecordNewPlannedAlertSent(
	in_alert_id		IN	new_planned_deleg_alert.new_planned_deleg_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM new_planned_deleg_alert
	 WHERE new_planned_deleg_alert_id = in_alert_id;
END;

PROCEDURE GetUpdatedPlannedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG);

	OPEN out_cur FOR 
		SELECT /*+ALL_ROWS*/ nda.updated_planned_deleg_alert_id, nda.notify_user_sid, cuf.full_name delegator_full_name, cu.full_name, 
			   cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, nda.app_sid,
        	   d.name delegation_name, 
			   dd.description delegation_description, 
			   s.submission_dtm, TO_CHAR(s.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, cuf.email delegator_email, 
        	   d.delegation_sid, s.sheet_id, 
        	   d.editing_url||'sheetid='||s.sheet_id sheet_url,
        	   delegation_pkg.ConcatDelegationUsers(d.delegation_sid, 10) deleg_assigned_to,
        	   s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
        	   nda.raised_by_user_sid,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM updated_planned_deleg_alert nda
		  JOIN csr_user cu ON nda.app_sid = cu.app_sid AND nda.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet s ON nda.app_sid = s.app_sid AND s.sheet_id = nda.sheet_id
		  JOIN csr_user cuf ON nda.app_sid = cuf.app_sid AND nda.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON nda.app_sid = tabr.app_sid AND nda.notify_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		  JOIN customer c on nda.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE RecordUpdatedPlannedAlertSent(
	in_alert_id		IN	updated_planned_deleg_alert.updated_planned_deleg_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM updated_planned_deleg_alert
	 WHERE updated_planned_deleg_alert_id = in_alert_id;
END;

PROCEDURE GetStateChangeAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ dca.delegation_change_alert_id, dca.notify_user_sid, cu.email, cuf.full_name from_name,
			   cu.full_name full_name, cu.friendly_name,
        	   cu.full_name to_name, cu.email to_email, sa.description, cu.user_name, cu.csr_user_sid, dca.app_sid,
        	   d.name delegation_name, dd.description delegation_description,
			   s.submission_dtm, cuf.email from_email, s.last_action_note note, d.name, s.sheet_id,
               'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
               s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               dca.raised_by_user_sid, sa.sheet_action_id,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM delegation_change_alert dca
		  JOIN csr_user cu ON dca.app_sid = cu.app_sid AND dca.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid 
		  JOIN sheet_with_last_action s ON dca.app_sid = s.app_sid AND dca.sheet_id = s.sheet_id
		  JOIN csr_user cuf ON dca.app_sid = cuf.app_sid AND dca.raised_by_user_sid = cuf.csr_user_sid
		  JOIN sheet_action sa ON sa.sheet_action_id = s.last_action_id
		  JOIN customer c ON dca.app_sid = c.app_sid
		  JOIN customer_alert_type cat ON c.app_sid = cat.app_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		 WHERE cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CHANGED
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE GetStateChangeAlertsBatched(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ dca.delegation_change_alert_id, dca.notify_user_sid, cu.email, cuf.full_name from_name,
			   cu.full_name full_name, cu.friendly_name,
        	   cu.full_name to_name, cu.email to_email, sa.description, cu.user_name, cu.csr_user_sid, dca.app_sid,
        	   d.name delegation_name, dd.description delegation_description,
			   s.submission_dtm, cuf.email from_email, s.last_action_note note, d.name, s.sheet_id,
               'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
               s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               dca.raised_by_user_sid,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM delegation_change_alert dca
		  JOIN csr_user cu ON dca.app_sid = cu.app_sid AND dca.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid 
		  JOIN sheet_with_last_action s ON dca.app_sid = s.app_sid AND dca.sheet_id = s.sheet_id
		  JOIN csr_user cuf ON dca.app_sid = cuf.app_sid AND dca.raised_by_user_sid = cuf.csr_user_sid
		  JOIN sheet_action sa ON sa.sheet_action_id = s.last_action_id
		  JOIN customer c ON dca.app_sid = c.app_sid
		  JOIN temp_alert_batch_run tabr ON dca.app_sid = tabr.app_sid AND dca.notify_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED 
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE RecordStateChangeAlertSent(
	in_delegation_change_alert_id	IN	delegation_change_alert.delegation_change_alert_id%TYPE
)
AS
BEGIN
	DELETE FROM delegation_change_alert
	 WHERE delegation_change_alert_id = in_delegation_change_alert_id;
END;

PROCEDURE GetDataChangeAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ dca.deleg_data_change_alert_id, dca.notify_user_sid, cu.email, cuf.full_name from_name,
			   cu.full_name full_name, cu.friendly_name,
        	   cu.full_name to_name, cu.email to_email, sa.description, cu.user_name, cu.csr_user_sid, dca.app_sid,
        	   d.name delegation_name, dd.description delegation_description, 
			   s.submission_dtm, cuf.email from_email, s.last_action_note note, d.name, s.sheet_id, 
               'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
               s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               dca.raised_by_user_sid, 
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
		  FROM deleg_data_change_alert dca
		  JOIN csr_user cu ON dca.app_sid = cu.app_sid AND dca.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet_with_last_action s ON dca.app_sid = s.app_sid AND dca.sheet_id = s.sheet_id
		  JOIN csr_user cuf ON dca.app_sid = cuf.app_sid AND dca.raised_by_user_sid = cuf.csr_user_sid
		  JOIN sheet_action sa ON sa.sheet_action_id = s.last_action_id
		  JOIN customer c ON dca.app_sid = c.app_sid
		  JOIN customer_alert_type cat ON c.app_sid = cat.app_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		 WHERE cat.std_alert_type_id = csr_data_pkg.ALERT_SUBMITTED_VAL_CHANGED
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid;
END;

/** 
 *  Aggregates translated region descriptions into a delimited string.
 *  @param  in_delegation_sid       The sid of the delegation to get region descriptions for.
 *  @param  in_separator            The separator to use. If ommited, region names are delimited by 
 *                                  commas.
 *  @param  in_list_threshold       The maximum number of regions names to attempt to aggregate. If 
 *                                  the region count exceeds this value a null value is returned. 
 *                                  For consistent results the default value should match the C# constant
 *                                  Credit360.ScheduledTasks.Delegations.ProcessJobs.MaxRegionNames
 */
FUNCTION FormatRegionNames(
	in_delegation_sid           delegation.delegation_sid%TYPE,
    in_separator                VARCHAR2 DEFAULT ', ',
    in_list_threshold           NUMBER DEFAULT 10 
) RETURN VARCHAR2
AS
    v_aggregate_description     VARCHAR2(4000);
BEGIN
    SELECT 
      CASE WHEN COUNT(*) > in_list_threshold
        THEN NULL
        ELSE JoinStrings(
            CAST(COLLECT(NVL(drd.description, rd.description)) AS T_VARCHAR2_TABLE), 
            in_separator)
      END 
      INTO v_aggregate_description
      FROM delegation_region dr
      JOIN region r 
        ON r.app_sid = dr.app_sid 
       AND r.region_sid = dr.region_sid
      LEFT JOIN delegation_region_description drd
        ON drd.app_sid = dr.app_sid
       AND drd.delegation_sid = dr.delegation_sid
       AND drd.region_sid = dr.region_sid
       AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
      LEFT JOIN region_description rd
        ON rd.app_sid = dr.app_sid
       AND rd.region_sid = dr.region_sid
       AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
     WHERE dr.delegation_sid = in_delegation_sid;

    RETURN v_aggregate_description;
END;

PROCEDURE RecordDataChangeAlertSent(
	in_deleg_data_change_alert_id	IN	deleg_data_change_alert.deleg_data_change_alert_id%TYPE,
	out_deleted_count				OUT number
)
AS
BEGIN
	DELETE FROM deleg_data_change_alert
	 WHERE deleg_data_change_alert_id = in_deleg_data_change_alert_id;

	out_deleted_count := SQL%ROWCOUNT;
END;

PROCEDURE GetSheetChangeReqAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR       
	    SELECT /*+ALL_ROWS*/  scra.sheet_change_req_alert_id, cuf.email from_email, cuf.full_name from_name, 
	           cu.full_name full_name, cu.friendly_name, 
	           cu.full_name to_name, cu.email to_email, cu.user_name, cu.csr_user_sid, scra.app_sid,
	           d.name delegation_name, 
			   dd.description delegation_description, 
			   raised_note "COMMENT", scra.raised_by_user_sid,
	           s.submission_dtm,
	           'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
			   'https://'||c.host||d.editing_url||'sheetid='||scr.req_to_change_sheet_id action_sheet_url,
	           s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
	      FROM sheet_change_req_alert scra
	      JOIN sheet_change_req scr ON scra.sheet_change_req_id = scr.sheet_change_req_id AND scra.app_sid = scr.app_sid
	      JOIN csr_user cu ON scra.notify_user_sid = cu.csr_user_sid AND scra.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	      JOIN csr_user cuf ON scra.raised_by_user_sid = cuf.csr_user_sid AND scra.app_sid = cuf.app_sid
	      JOIN sheet s ON scr.active_sheet_id = s.sheet_id AND scr.app_sid = s.app_sid
	      JOIN delegation d ON s.delegation_sid = d.delegation_sid AND s.app_sid = d.app_sid
	      JOIN customer c ON d.app_sid = c.app_sid
	      JOIN customer_alert_type cat ON c.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CHANGE_REQ
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
	     WHERE scra.action_type = 'S'
		   AND c.scheduled_tasks_disabled = 0;
END;

PROCEDURE GetSheetChangeReqApprAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR       
	    SELECT /*+ALL_ROWS*/  scra.sheet_change_req_alert_id, cuf.email from_email, cuf.full_name from_name, 
	           cu.full_name full_name, cu.friendly_name, 
	           cu.full_name to_name, cu.email to_email, cu.user_name, cu.csr_user_sid, scra.app_sid,
	           d.name delegation_name, 
			   dd.description delegation_description, 
			   processed_note "COMMENT", scra.raised_by_user_sid,
	           s.submission_dtm,
	           'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
			   'https://'||c.host||d.editing_url||'sheetid='||scr.req_to_change_sheet_id action_sheet_url,
	           s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
	      FROM sheet_change_req_alert scra
	      JOIN sheet_change_req scr ON scra.sheet_change_req_id = scr.sheet_change_req_id AND scra.app_sid = scr.app_sid
	      JOIN csr_user cu ON scra.notify_user_sid = cu.csr_user_sid AND scra.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	      JOIN csr_user cuf ON scra.raised_by_user_sid = cuf.csr_user_sid AND scra.app_sid = cuf.app_sid
	      JOIN sheet s ON scr.req_to_change_sheet_id = s.sheet_id AND scr.app_sid = s.app_sid
	      JOIN delegation d ON s.delegation_sid = d.delegation_sid AND s.app_sid = d.app_sid
	      JOIN customer c ON d.app_sid = c.app_sid
	      JOIN customer_alert_type cat ON c.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CHANGE_REQ_APPR
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
	     WHERE scra.action_type = 'A'
		   AND c.scheduled_tasks_disabled = 0;
END;

PROCEDURE GetSheetChangeReqRejAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR       
	    SELECT /*+ALL_ROWS*/  scra.sheet_change_req_alert_id, cuf.email from_email, cuf.full_name from_name, 
	           cu.full_name full_name, cu.friendly_name, 
	           cu.full_name to_name, cu.email to_email, cu.user_name, cu.csr_user_sid, scra.app_sid,
	           d.name delegation_name, 
			   dd.description delegation_description, 
			   processed_note "COMMENT", scra.raised_by_user_sid,
	           s.submission_dtm,
	           'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
			   'https://'||c.host||d.editing_url||'sheetid='||scr.req_to_change_sheet_id action_sheet_url,
	           s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               FormatRegionNames(d.delegation_sid) region_names
	      FROM sheet_change_req_alert scra
	      JOIN sheet_change_req scr ON scra.sheet_change_req_id = scr.sheet_change_req_id AND scra.app_sid = scr.app_sid
	      JOIN csr_user cu ON scra.notify_user_sid = cu.csr_user_sid AND scra.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	      JOIN csr_user cuf ON scra.raised_by_user_sid = cuf.csr_user_sid AND scra.app_sid = cuf.app_sid
	      JOIN sheet s ON scr.req_to_change_sheet_id = s.sheet_id AND scr.app_sid = s.app_sid
	      JOIN delegation d ON s.delegation_sid = d.delegation_sid AND s.app_sid = d.app_sid
	      JOIN customer c ON d.app_sid = c.app_sid
	      JOIN customer_alert_type cat ON c.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CHANGE_REQ_REJ
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
	     WHERE scra.action_type = 'R'
		   AND c.scheduled_tasks_disabled = 0;
END;

PROCEDURE RecordSheetChangeReqAlertSent(
	in_sheet_change_req_alert_id	IN	sheet_change_req_alert.sheet_change_req_alert_id%TYPE,
	out_deleted_count				OUT number
)
AS
BEGIN
	DELETE FROM sheet_change_req_alert
	 WHERE sheet_change_req_alert_id = in_sheet_change_req_alert_id;
	
	out_deleted_count := SQL%ROWCOUNT;
END;

PROCEDURE CreateGridIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_path							IN	VARCHAR2,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL,
	in_variance_validation_sp		IN	delegation_grid.variance_validation_sp%TYPE DEFAULT NULL
)
AS
BEGIN
	CreateGridIndicator(
		in_name						=> in_name,
		in_description				=> in_description,
		in_path						=> in_path,
		in_form_sid					=> null,
		in_aggregation_xml				=> in_aggregation_xml,
		in_variance_validation_sp	=> in_variance_validation_sp
	);
END;


PROCEDURE CreateGridIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_path							IN	VARCHAR2,
	in_form_sid						IN	NUMBER,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL,
	in_variance_validation_sp		IN	delegation_grid.variance_validation_sp%TYPE DEFAULT NULL
)
AS
	v_sid							security_pkg.T_SID_ID;
	v_grids_sid						security_pkg.T_SID_ID;
	v_ind_root_sid 					security_pkg.T_SID_ID;
BEGIN
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_grids_sid := securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, v_ind_root_sid, 'Grids');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_ind_root_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> 'Grids',
				in_description		=> 'Grids',
				out_sid_id			=> v_grids_sid
			);
	END;

	BEGIN
		v_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, v_grids_sid, in_name);
		UPDATE delegation_grid
		   SET path = in_path, 
		   form_sid = in_form_sid,
		   variance_validation_sp = in_variance_validation_sp
		 WHERE ind_sid = v_sid;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_grids_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> in_name,
				in_description		=> in_description,
				out_sid_id			=> v_sid
			);
			INSERT INTO delegation_grid (path, form_sid, ind_sid, name, variance_validation_sp)
			VALUES (in_path,in_form_sid, v_sid, in_name, in_variance_validation_sp);
	END;

	SetGridIndAggregationXml(v_sid, in_aggregation_xml);
END;

PROCEDURE SetGridIndAggregationXml(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_aggregation_xml				IN	VARCHAR2
)
AS
	v_parser						dbms_xmlparser.parser;
BEGIN
	v_parser := dbms_xmlparser.newParser;
	dbms_xmlparser.parseBuffer(v_parser, in_aggregation_xml);
	SetGridIndAggregationXml(in_ind_sid, dbms_xmldom.getxmltype(dbms_xmlparser.getDocument(v_parser)));
	dbms_xmlparser.freeParser(v_parser);
END;

PROCEDURE SetGridIndAggregationXml(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL
)
AS
	v_doc							dbms_xmldom.domdocument;
	v_nodes							dbms_xmldom.domnodelist;
	v_lookup_key					varchar2(32767);
	v_aggregate_to_ind_sid			ind.ind_sid%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting the aggregation xml on the grid indicator with sid '||in_ind_sid);
	END IF;

	-- Set the xml
	UPDATE delegation_grid
	   SET aggregation_xml = in_aggregation_xml
	 WHERE ind_sid = in_ind_sid;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Tried to set the aggregation xml on the indicator with sid '||in_ind_sid||', but it doesn''t appear to be a grid indicator');
	END IF;

	-- Clean up any indicators that we aggregate to
	DELETE FROM delegation_grid_aggregate_ind
	 WHERE ind_sid = in_ind_sid;

	-- XXX: consider cleaning the indicator that is aggregated to off delegations that contain it (if hidden)?
	IF in_aggregation_xml IS NOT NULL THEN
		-- Find the indicators involved in aggregation
		v_doc := dbms_xmldom.newdomdocument(in_aggregation_xml);
		v_nodes := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc), '/cms:aggregates/cms:aggregate/cms:map//cms:indicator/@lookup-key', 'xmlns:cms=http://www.credit360.com/XMLSchemas/cms');
		FOR i IN 0 .. dbms_xmldom.getLength(v_nodes) - 1 LOOP
			v_lookup_key := dbms_xmldom.getNodeValue(dbms_xmldom.item(v_nodes, i));

			BEGIN
				SELECT MIN(ind_sid)
				  INTO v_aggregate_to_ind_sid
				  FROM ind
				 WHERE lookup_key = v_lookup_key;
			END;

			-- By selecting MIN, you get NULL if there are no matching records
			IF v_aggregate_to_ind_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The indicator with the lookup key '||v_lookup_key||' could not be found');
			END IF;

			--dbms_output.put_line('finding '||v_lookup_key ||' ind '||v_aggregate_to_ind_sid);
			INSERT INTO delegation_grid_aggregate_ind
				(ind_sid, aggregate_to_ind_sid)
			VALUES
				(in_ind_sid, v_aggregate_to_ind_sid);
		END LOOP;
	END IF;

	-- Add any indicators that are aggregated to to delegations containing the grid indicator if it's missing
	INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility)
		SELECT di.delegation_sid, i.ind_sid, 0, 'HIDE'
		  FROM delegation_ind di, delegation_grid_aggregate_ind dgai, v$ind i
		 WHERE i.app_sid = dgai.app_sid AND i.ind_sid = dgai.aggregate_to_ind_sid
		   AND di.ind_sid = dgai.ind_sid
		   AND dgai.aggregate_to_ind_sid NOT IN (SELECT ind_sid
		   										   FROM delegation_ind
		   										  WHERE delegation_sid = di.delegation_sid);

	-- XXX: should really redo the aggregation, but we can't do that in PL/SQL
END;

PROCEDURE CreatePluginIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_js_class_type				IN	VARCHAR2,
	in_js_include					IN	VARCHAR2
)
AS
	v_sid							security_pkg.T_SID_ID;
	v_plugins_sid					security_pkg.T_SID_ID;
	v_ind_root_sid 					security_pkg.T_SID_ID;
BEGIN
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_plugins_sid := securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, v_ind_root_sid, 'Plugins');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_ind_root_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> 'Plugins',
				in_description		=> 'Plugins',
				out_sid_id			=> v_plugins_sid
			);
	END;

	BEGIN
		v_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, v_plugins_sid, in_name);
		UPDATE	delegation_plugin
		   SET	js_class_type = in_js_class_type,
				js_include = in_js_include
		 WHERE	ind_sid = v_sid;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_plugins_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> in_name,
				in_description		=> in_description,
				out_sid_id			=> v_sid
			);
			INSERT INTO delegation_plugin
				(js_class_type, js_include, ind_sid, name)
			VALUES
				(in_js_class_type, in_js_include, v_sid, in_name);
	END;
END;

PROCEDURE GetCoverage(
	out_cur		OUT		SYS_REFCURSOR
)
AS
    v_outer_select  varchar2(2000) := '';
    v_inner_select  varchar2(2000) := '';
    v_case          varchar2(2000) := '';
BEGIN
    IF NOT sqlreport_pkg.CheckAccess('csr.delegation_pkg.GetCoverage') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    FOR r IN (
        SELECT REPLACE(name,'''','''''')name, rownum rn FROM reporting_period ORDER BY start_dtm
    )
    LOOP
        v_outer_select := v_outer_select||',x.c'||r.rn||' "'||r.name||'"';
        v_inner_select := v_inner_select||',stragg(c'||r.rn||') c'||r.rn;
        v_case := v_case||',case when rp.name='''||r.name||''' then stragg(dr.description) else null end c'||r.rn;
    END LOOP;

	OPEN out_cur FOR
		'select i.ind_sid, replace(i.label,CHR(9),CHR(9)||'' '')label'||v_outer_select||
		 ' from ('||
			 ' select ind_sid'||v_inner_select||
			   ' from ('||
			       ' select di.ind_sid'||v_case||
					 ' from delegation d'||
					   ' join reporting_period rp on d.start_dtm < rp.end_dtm and d.end_dtm > rp.start_dtm'||
					   ' join delegation_ind di on d.delegation_sid = di.delegation_sid'||
					   ' join v$delegation_region dr on d.delegation_sid = dr.delegation_sid'||
					' where d.app_sid = d.parent_sid'||
					--' and (rownum <= 100)' ||
				    ' group by di.ind_sid, rp.start_dtm, rp.name'||
			' )'||
			' group by ind_sid'||
	    ' )x right join ('||
		   ' select ind_sid, lpad(CHR(9), (level-1)*2, CHR(9))||description label, rownum rn'||
			 ' from v$ind ind'||
			' start with parent_sid = ('||
			   ' select ind_root_sid from customer'||
			' )'||
		   ' connect by prior ind_sid = parent_sid'||
		   ' order siblings by ind.description'||
	    ' )i on x.ind_sid = i.ind_sid'||
	    ' order by i.rn';
END;

FUNCTION HasIncompleteChild(
	in_sheet_id			IN	sheet.sheet_id%TYPE
) RETURN NUMBER
AS
	v_delegation_sid		security_pkg.T_SID_ID;
	v_start_dtm				sheet.start_dtm%TYPE;
	v_end_dtm				sheet.start_dtm%TYPE;
	v_bool		NUMBER;
BEGIN
	BEGIN
		SELECT delegation_sid, start_dtm, end_dtm
		  INTO v_delegation_sid, v_start_dtm, v_end_dtm
		  FROM sheet
		 WHERE sheet_id = in_sheet_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The sheet with id '||in_sheet_id||' does not exist');
	END;	
	
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT NVL(MAX(CASE WHEN swla.last_action_id IN (
					csr_data_pkg.ACTION_WAITING,
					csr_data_pkg.ACTION_WAITING_WITH_MOD,
					csr_data_pkg.ACTION_SUBMITTED,
					csr_data_pkg.ACTION_SUBMITTED_WITH_MOD,
					csr_data_pkg.ACTION_RETURNED,
					csr_data_pkg.ACTION_RETURNED_WITH_MOD
				   ) THEN 1 ELSE 0 END), 0)
	  INTO v_bool
	  FROM (SELECT app_sid, delegation_sid
			  FROM delegation
				   START WITH parent_sid = v_delegation_sid
					CONNECT BY PRIOR delegation_sid = parent_sid) d
	  JOIN sheet_with_last_action swla ON d.delegation_sid = swla.delegation_sid AND d.app_sid = swla.app_sid
	 WHERE swla.start_dtm < v_end_dtm
	   AND swla.end_dtm > v_start_dtm;

	RETURN v_bool;
END;

FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
BEGIN
	FOR x IN (SELECT COUNT(*) found
	            FROM dual
			   WHERE EXISTS (SELECT 1
				               FROM delegation_ind
							  WHERE ind_sid = in_ind_sid))
	LOOP
		RETURN x.found = 1;
	END LOOP;
END;

PROCEDURE GetIndicatorTranslations(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	OPEN out_cur FOR
		SELECT di.ind_sid, id.lang, NVL(did.description, id.description) description
		  FROM delegation_ind di
		  JOIN ind_description id ON di.app_sid = id.app_sid AND di.ind_sid = id.ind_sid
		  LEFT JOIN delegation_ind_description did ON di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
		   AND di.ind_sid = did.ind_sid
		   AND id.lang = did.lang
		 WHERE di.delegation_sid = in_delegation_sid;
END;

PROCEDURE GetRegionTranslations(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	OPEN out_cur FOR
		SELECT dr.region_sid, rd.lang, NVL(drd.description, rd.description) description
		  FROM delegation_region dr
		  JOIN region_description rd ON dr.app_sid = rd.app_sid AND dr.region_sid = rd.region_sid
		  LEFT JOIN delegation_region_description drd ON dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
		   AND dr.region_sid = drd.region_sid
		   AND rd.lang = drd.lang
		 WHERE dr.delegation_sid = in_delegation_sid;
END;

-- This is used by Heineken SPM, when delegations are copied and the old inds are swapped
-- for new inds from a different ind group based on the same template
PROCEDURE ReplaceDelegationInds(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_old_ind_sids		IN	security_pkg.T_SID_IDS,
	in_new_ind_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_delegation_ind_cond_id	security_pkg.T_SID_ID;
	v_old_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_old_ind_sids);
	v_new_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_new_ind_sids);
BEGIN

	FOR i IN 1 .. v_old_sids.COUNT LOOP
		-- insert new indicators
		INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na)
			SELECT delegation_sid, v_new_sids(i), mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
			   AND ind_sid = v_old_sids(i);

		-- Copy over User Perf Accuracy info (if any).
		INSERT INTO deleg_meta_role_ind_selection(delegation_sid, ind_sid, lang, description)
			SELECT delegation_sid, v_new_sids(i), lang, description
			  FROM deleg_meta_role_ind_selection
			 WHERE delegation_sid = in_delegation_sid
			   AND ind_sid = v_old_sids(i);

		-- insert new descriptions
		INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
			SELECT delegation_sid, v_new_sids(i), id.lang, id.description
			  FROM delegation_ind_description did
			  JOIN ind_description id ON id.ind_sid = did.ind_sid AND id.lang = did.lang
			 WHERE delegation_sid = in_delegation_sid
			   AND did.ind_sid = v_old_sids(i);

		-- copy over conditional stuff to point to us instead as we're a new root
		INSERT INTO delegation_ind_tag (delegation_sid, ind_sid, tag)
			SELECT delegation_sid, v_new_sids(i), tag
			  FROM delegation_ind_tag
			 WHERE delegation_sid = in_delegation_sid
			   AND ind_sid = v_old_sids(i);

		INSERT INTO deleg_ind_group_member (deleg_ind_group_id, delegation_sid, ind_sid)
			SELECT deleg_ind_group_id, delegation_sid, v_new_sids(i)
			  FROM deleg_ind_group_member
			 WHERE delegation_sid = in_delegation_sid
			   AND ind_sid = v_old_sids(i);

		-- copy over form expressions stuff
		INSERT INTO deleg_ind_form_expr (delegation_sid, ind_sid, form_expr_id)
			SELECT in_delegation_sid, v_new_sids(i), form_expr_id
			  FROM deleg_ind_form_expr
			 WHERE delegation_sid = in_delegation_sid
			   AND ind_sid = v_old_sids(i);

		FOR fe IN (
			SELECT form_expr_id, expr
			  FROM form_expr
			 WHERE delegation_sid = in_delegation_sid
		) LOOP
			UPDATE form_expr
			   SET expr = XMLTYPE(REPLACE(fe.expr.GETSTRINGVAL(), v_old_sids(i), v_new_sids(i)))
			 WHERE form_expr_id = fe.form_expr_id;

			-- this is a pain as the actions are all linked to other ids...
			INSERT INTO delegation_ind_cond (
				delegation_sid, ind_sid, delegation_ind_cond_id, expr
			) VALUES (
				in_delegation_sid, v_new_sids(i), delegation_ind_cond_id_seq.nextval, fe.expr
			) RETURNING delegation_ind_cond_id INTO v_delegation_ind_cond_id;

			INSERT INTO delegation_ind_cond_action (delegation_sid, ind_sid, delegation_ind_cond_id, action, tag)
				SELECT delegation_sid, ind_sid, v_delegation_ind_cond_id, action, tag
				  FROM delegation_ind_cond_action
				 WHERE delegation_sid = in_delegation_sid
				   AND ind_sid = v_old_sids(i);
		END LOOP;
	END LOOP;

	-- remove all the old ind references
	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM delegation_ind_cond
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM delegation_ind_tag
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM deleg_ind_form_expr
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM deleg_ind_group_member
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM delegation_ind_description
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM deleg_meta_role_ind_selection
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );
	DELETE FROM delegation_ind
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid NOT IN (
		SELECT t.column_value
		  FROM TABLE(v_new_sids) t
	   );

	-- remove the old sheets
	FOR s IN (
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = in_delegation_sid
	) LOOP
		sheet_pkg.DeleteSheet(s.sheet_id);
	END LOOP;

	-- insert some sheets
	CreateSheetsForDelegation(in_delegation_sid);
END;

PROCEDURE GetSubdelegChainUsers(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_user_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	OPEN out_cur FOR
		SELECT di.ind_sid, dr.region_sid, d.delegation_sid, d.lvl
		  FROM (
			    SELECT app_sid, delegation_sid, LEVEL lvl
				  FROM delegation
				 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND delegation_sid = in_delegation_sid
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
			   ) d
		  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  JOIN delegation_region dr ON d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
		 ORDER BY di.ind_sid, dr.region_sid, d.lvl;

	OPEN out_user_cur FOR
		SELECT d.delegation_sid, du.user_sid, cu.full_name, ut.account_enabled active
		  FROM (
			SELECT app_sid, delegation_sid
			  FROM delegation
		     START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND delegation_sid = in_delegation_sid
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid
		   ) d
		  JOIN v$delegation_user du ON d.delegation_sid = du.delegation_sid AND d.app_sid = du.app_sid
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id;
END;

PROCEDURE SetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_mandatory_list		IN	VARCHAR2,
	in_propagate_down		IN	NUMBER DEFAULT 1,
	in_allowed_na_list		IN	VARCHAR2
)
AS
	t_allowed_na			T_SPLIT_NUMERIC_TABLE;
BEGIN
	SetIndicators (in_act_id, in_delegation_sid, in_indicators_list, in_mandatory_list, in_propagate_down);

	-- get allowed to be n/a
	t_allowed_na := Utils_Pkg.SplitNumericString(in_allowed_na_list, ',');
					 
	-- clear
	UPDATE delegation_ind 
	   SET allowed_na = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND allowed_na != 0;
	-- set
	UPDATE delegation_ind
	   SET allowed_na = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND ind_sid IN (
			SELECT ITEM FROM TABLE (t_allowed_na)
		)
	   AND allowed_na != 1;
END;

PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2,
	in_allowed_na_list	IN	VARCHAR2
)
AS
	t_allowed_na			T_SPLIT_NUMERIC_TABLE;
BEGIN
	SetRegions(in_act_id, in_delegation_sid, in_regions_list, in_mandatory_list);	

	-- get allowed to be n/a
	t_allowed_na := Utils_Pkg.SplitNumericString(in_allowed_na_list, ',');
	-- clear
	UPDATE delegation_region 
	   SET allowed_na = 0
	 WHERE delegation_sid = in_delegation_sid
	   AND allowed_na != 0;
	-- set
	UPDATE delegation_region 
	   SET allowed_na = 1
	 WHERE delegation_sid = in_delegation_sid
	   AND region_sid IN (SELECT item FROM TABLE (t_allowed_na))
	   AND allowed_na != 1;
END;

PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicator_list	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_indicator_table		security.T_ORDERED_SID_TABLE;
BEGIN
	v_indicator_table := security_pkg.SidArrayToOrderedTable(in_indicator_list);
	OPEN out_cur FOR
		SELECT i.ind_sid, i.name, di.description, i.lookup_key, m.name measure_name,
			   m.description measure_description, m.measure_sid, i.gri, multiplier,
			   NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask,
			   i.active, i.scale actual_scale, i.format_mask actual_format_mask,
			   i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.start_month,
			   CASE
				   WHEN i.measure_sid IS NULL THEN 'Category'
				   WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
				   WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
				   ELSE 'Indicator'
			   END node_type, ind_type,
			   i.target_direction, i.last_modified_dtm,
			   EXTRACT(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, di.pos
		  FROM v$delegation_ind di, ind i, measure m, TABLE(v_indicator_table) l
		 WHERE i.measure_sid = m.measure_sid(+)
		   AND l.sid_id = i.ind_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.sid_id, security_pkg.PERMISSION_READ)=1
		   AND di.ind_sid = i.ind_sid
		   AND di.delegation_sid = in_delegation_sid
		 ORDER BY l.pos;
END;

PROCEDURE GetRegionsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_region_list		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_region_table		security.T_ORDERED_SID_TABLE;
BEGIN
	v_region_table := security_pkg.SidArrayToOrderedTable(in_region_list);
	OPEN out_cur FOR
		SELECT r.region_sid, name, dr.description, active, r.pos, 'Region' node_type, aggregate_to_region_sid,
			   r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM TABLE(v_region_table) l, region r, v$delegation_region dr
		 WHERE l.sid_id = r.region_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.sid_id, security_pkg.PERMISSION_READ) = 1
		   AND dr.region_sid = r.region_sid
		   AND dr.delegation_sid = in_delegation_sid
		 ORDER BY l.POS;
END;

FUNCTION GetChildrenCount(
	in_delegation_sid	IN	security.security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count			NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation
	 WHERE parent_sid = in_delegation_sid;

	 RETURN v_count;
END;

FUNCTION CountMergedDataValues(
	in_top_level_del_sid		IN	delegation.delegation_sid%TYPE,
	in_item_sids				IN	VARCHAR2,
	in_use_ind					IN	NUMBER
) RETURN NUMBER
AS
	v_result		NUMBER(10,0);
	t_items			T_SPLIT_TABLE;				
BEGIN	
	t_items := Utils_Pkg.splitString(in_item_sids, ',');

	SELECT COUNT(*)
	  INTO v_result
	  FROM val v
	  JOIN TABLE(t_items) i 
		ON (in_use_ind = 1 AND i.item = v.ind_sid)
		OR (in_use_ind = 0 AND i.item = v.region_sid)
	  JOIN sheet_value sv ON sv.sheet_value_id = v.source_id
	  JOIN sheet s ON s.sheet_Id = sv.sheet_id
	  -- For values entered via a sub-delegation, sheet_value uses the
	  -- sub-delegation ID, not the top-level delegation ID, so we need to
	  -- search for data merged from any sub-delegations as well as the
	  -- the top-level delegation.
	  JOIN (
		    SELECT parent_sid,  delegation_sid
		      FROM delegation
		START WITH delegation_sid = in_top_level_del_sid
		CONNECT BY parent_sid = PRIOR delegation_sid
	  ) children ON children.delegation_sid = s.delegation_sid
	 WHERE v.source_type_id = 1; -- delegation form
	 
	 RETURN v_result;
END;

-- Get indicators with pending explanations for region.
PROCEDURE GetGridVarianceInds(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Check permissions.
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting variance indicators for the delegation with sid: '||in_delegation_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM delegation_grid
		 WHERE ind_sid IN (
			  SELECT ind_sid
				FROM delegation_ind
			   WHERE delegation_sid = in_delegation_sid)
		   AND variance_validation_sp IS NOT NULL;
END;

PROCEDURE GetPendingVariances(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,	-- <- used just for permissions check...
	in_root_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_region_sid			IN	region.region_sid%TYPE,
	in_start_dtm			IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm				IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid			IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Check permissions.
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting pending variances for the delegation with sid: '||in_delegation_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ id, root_delegation_sid, region_sid, start_dtm, end_dtm, grid_ind_sid, variance, explanation, active
		  FROM deleg_grid_variance
		 WHERE root_delegation_sid = in_root_delegation_sid
		   AND region_sid = in_region_sid
		   AND start_dtm = in_start_dtm
		   AND end_dtm = in_end_dtm
		   AND grid_ind_sid = in_grid_ind_sid
		   AND (explanation IS NULL OR LENGTH(TRIM(explanation)) = 0)
		   AND active = 1;
END;

PROCEDURE GetVariances(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,		-- <- used for permissions check.
	in_root_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_region_sid			IN	region.region_sid%TYPE,
	in_start_dtm			IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm				IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid			IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Check permissions.
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting variances for the delegation with sid: '||in_delegation_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ id, root_delegation_sid, region_sid,
			   start_dtm, end_dtm, grid_ind_sid, variance, explanation,
			   active, label, curr_value, prev_value
		  FROM deleg_grid_variance
		 WHERE root_delegation_sid = in_root_delegation_sid
		   AND region_sid = in_region_sid
		   AND start_dtm = in_start_dtm
		   AND end_dtm = in_end_dtm
		   AND grid_ind_sid = in_grid_ind_sid
		   AND active = 1;
END;

-- This basically:
-- Runs the grid variance validation SP (delegation_grid.variance_validation_sp),
-- inserts rows returned into deleg_grid_variance, updates any that already
-- exist and marks existing rows (in deleg_grid_variance) as inactive if they
-- weren't returned in the variance validation SP.
PROCEDURE UpsertVariances(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	in_root_deleg_sid		IN	deleg_grid_variance.root_delegation_sid%TYPE,
	in_region_sid			IN	deleg_grid_variance.region_sid%TYPE,
	in_start_dtm			IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm				IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid			IN	ind.ind_sid%TYPE
)
AS
	v_sp					VARCHAR2(255);
	v_variances_cur			SYS_REFCURSOR;
	v_id					deleg_grid_variance.id%TYPE;
	v_label					deleg_grid_variance.label%TYPE;
	v_variance				deleg_grid_variance.variance%TYPE;
	v_curr_value			NUMBER;
	v_prev_value			NUMBER;
BEGIN
	-- Check permissions.
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied upserting variances for the delegation with sid: '||in_delegation_sid);
	END IF;
	
	-- Get variance SP.
	-- Safe to assume there SHOULD be one row returned.
	SELECT variance_validation_sp
	  INTO v_sp
	  FROM delegation_grid
	 WHERE ind_sid = in_grid_ind_sid;
	
	-- Exec customer SP, returning the variances into a table.
	-- Assume the SP exists -> we want to know about it if it doesn't.
	-- Pass the variance SP the root delegation sid (will need this if the delegation
	-- is split in yearly sheets. Won't need it if the delegation itself is yearly).
	EXECUTE IMMEDIATE 'BEGIN '||v_sp||'(:1, :2, :3, :4, :5); END;'
	  USING in_root_deleg_sid, in_region_sid, in_start_dtm, in_end_dtm, v_variances_cur;
	
	-- Now mark the variances not listed in the result set
	-- from the variance SP as inactive for this region/deleg.
	UPDATE deleg_grid_variance
	   SET active = 0
	 WHERE root_delegation_sid = in_root_deleg_sid
	   AND start_dtm = in_start_dtm
	   AND end_dtm = in_end_dtm
	   AND region_sid = in_region_sid
	   AND grid_ind_sid = in_grid_ind_sid;
	
	LOOP
		FETCH v_variances_cur INTO v_id, v_label, v_variance, v_curr_value, v_prev_value;
		EXIT WHEN v_variances_cur%NOTFOUND;
		
		BEGIN
			INSERT INTO deleg_grid_variance (id, root_delegation_sid, region_sid, start_dtm, end_dtm, grid_ind_sid, label, variance, explanation, curr_value, prev_value)
			VALUES (v_id, in_root_deleg_sid, in_region_sid, in_start_dtm, in_end_dtm, in_grid_ind_sid, v_label, v_variance, NULL, v_curr_value, v_prev_value);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- Update the label and variance labels too - just in case.
				UPDATE deleg_grid_variance
				   SET label = v_label,
				       variance = v_variance,
				       active = 1,	-- <- will be active.
				       curr_value = v_curr_value,
				       prev_value = v_prev_value
				 WHERE id = v_id
				   AND root_delegation_sid = in_root_deleg_sid
				   AND start_dtm = in_start_dtm
				   AND end_dtm = in_end_dtm
				   AND region_sid = in_region_sid
				   AND grid_ind_sid = in_grid_ind_sid;
		END;
	END LOOP;
END;

PROCEDURE SaveVarianceExplanation(
	in_id				IN	deleg_grid_variance.id%TYPE,
	in_delegation_sid	IN	delegation.delegation_sid%TYPE,		-- <- only used for permissions check.
	in_root_deleg_sid	IN	deleg_grid_variance.root_delegation_sid%TYPE,
	in_region_sid		IN	region.region_sid%TYPE,
	in_start_dtm		IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm			IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid		IN	ind.ind_sid%TYPE,
	in_explanation		IN	deleg_grid_variance.explanation%TYPE
)
AS
BEGIN
	-- Check permissions.
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving explanation on the delegation with sid: '||in_delegation_sid);
	END IF;
	
	UPDATE deleg_grid_variance
	   SET explanation = in_explanation
	 WHERE id = in_id
	   AND root_delegation_sid = in_root_deleg_sid
	   AND start_dtm = in_start_dtm
	   AND end_dtm = in_end_dtm
	   AND grid_ind_sid = in_grid_ind_sid
	   AND region_sid = in_region_sid;
END;

PROCEDURE CreateLayoutTemplate(
    in_xml              IN	delegation_layout.layout_xhtml%TYPE,
    in_name             IN  delegation_layout.name%TYPE DEFAULT NULL,
    out_id				OUT	delegation_layout.layout_id%TYPE
)
AS
    v_name                  delegation_layout.name%TYPE DEFAULT NULL;
BEGIN
	SELECT delegation_layout_id_seq.NEXTVAL INTO out_id FROM dual;

    v_name := in_name;
    IF v_name IS NULL THEN
        v_name := 'New layout';
    END IF;

	INSERT INTO delegation_layout (layout_id, name, layout_xhtml)
	VALUES (out_id, v_name, in_xml);
END;

PROCEDURE UpdateLayoutTemplate(
    in_id				IN	delegation_layout.layout_id%TYPE,
    in_xml              IN	delegation_layout.layout_xhtml%TYPE,
    in_name             IN  delegation_layout.name%TYPE DEFAULT NULL,
	in_valid			IN	delegation_layout.valid%TYPE DEFAULT 0
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the System management capability which is required to edit layouts');
	END IF;

    IF in_name IS NULL THEN
        UPDATE delegation_layout
           SET layout_xhtml = in_xml,
		       valid = in_valid
         WHERE layout_id = in_id;
    ELSE
        UPDATE delegation_layout
           SET layout_xhtml = in_xml,
               name = in_name,
		       valid = in_valid
         WHERE layout_id = in_id;
    END IF;
END;

PROCEDURE GetLayoutTemplate(
    in_id				IN	delegation_layout.layout_id%TYPE,
    out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT layout_xhtml
		  FROM delegation_layout
		 WHERE layout_id = in_id;
END;

PROCEDURE SetLayoutTemplate(
	in_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_layout_id		IN	delegation_layout.layout_id%TYPE
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security_pkg.GetAct, in_delegation_sid, DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
		   	'Access denied updating layout template for the delegation with sid: ' || in_delegation_sid);
	END IF;

	UPDATE delegation
	   SET layout_id = in_layout_id
	 WHERE delegation_sid = in_delegation_sid;
END;

PROCEDURE GetLayoutDelegationSids(
    in_layout_id		IN	delegation_layout.layout_id%TYPE,
    out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT delegation_sid
		  FROM delegation
		 WHERE layout_id = in_layout_id;
END;

-- Procedures for creating and reading batch jobs for
-- calculating delegation completeness

-- This creates a new Delegation Completeness calculation batch job, and puts it on the queue.
PROCEDURE SetBatchJob(
	in_delegation_sid	IN	batch_job_delegation_comp.delegation_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
)
AS
	v_currently_queued	NUMBER(1);
BEGIN
	-- If there is a calculation already queued that has not yet started running then we do not need to queue another
	-- Note that the body of the query selects at most one row.
	SELECT COUNT(bj.batch_job_id) INTO v_currently_queued
		FROM batch_job bj, batch_job_delegation_comp bjdc
		WHERE bj.batch_job_type_id = batch_job_pkg.JT_DELEGATION_COMPLETENESS
		  AND bj.started_dtm IS NULL
		  AND bjdc.delegation_sid = in_delegation_sid
		  AND bj.batch_job_id = bjdc.batch_job_id
		  AND ROWNUM <= 1;

	IF v_currently_queued = 0 THEN
		batch_job_pkg.Enqueue(
			in_batch_job_type_id => batch_job_pkg.JT_DELEGATION_COMPLETENESS,
			out_batch_job_id => out_batch_job_id);

		INSERT INTO batch_job_delegation_comp
		  (batch_job_id, delegation_sid)
		VALUES
		  (out_batch_job_id, in_delegation_sid);
	END IF;
END;

-- This gets a Delegation Completeness calculation batch job by id.
PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT delegation_sid
			FROM batch_job_delegation_comp
			WHERE batch_job_id = in_batch_job_id;
END;

-- Indicates whether the Delegation Completeness data is currently up-to-date
-- i.e. no calculations pending or in-progress
PROCEDURE IsCompletenessUpToDate(
	in_delegation_sids	IN	VARCHAR2,
	out_up_to_date		OUT	NUMBER
)
AS
	t_delegation_sids	T_SPLIT_TABLE;
BEGIN
	t_delegation_sids 	:= Utils_Pkg.splitString(in_delegation_sids,',');

	-- If there is a calculation pending and/or running the current "completeness" figures may be incorrect
	-- Returns 1 if up-to-date, otherwise returns 0. Note that the body of the query selects at most one row.
	SELECT 1 - COUNT(bj.batch_job_id)
	  INTO out_up_to_date
	  FROM batch_job bj, batch_job_delegation_comp bjdc
	 WHERE bj.batch_job_type_id = batch_job_pkg.JT_DELEGATION_COMPLETENESS
	   AND bj.completed_dtm IS NULL
	   AND bjdc.delegation_sid IN (SELECT TO_NUMBER(item) FROM TABLE(t_delegation_sids))
	   AND bj.batch_job_id = bjdc.batch_job_id
	   AND ROWNUM <= 1;
END;

-- return the roles that the current user is in for regions in the given delegation
-- security on the delegation only -- a user can see which roles they are in
-- with a given set of regions
PROCEDURE GetUserRolesForDelegRegions(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the delegation with sid: '||in_delegation_sid);
	END IF;

	OPEN out_cur FOR
		SELECT ro.role_sid, ro.name, ro.lookup_key, ro.region_permission_set,
			   ro.is_metering, ro.is_property_manager, ro.is_delegation,
			   ro.is_supplier, ro.is_hidden
		  FROM role ro
		 WHERE ro.role_sid IN (
				SELECT rrm.role_sid
				  FROM region_role_member rrm, delegation_region dr
				 WHERE rrm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				   AND rrm.app_sid = dr.app_sid
				   AND rrm.region_sid = dr.region_sid
				   AND dr.delegation_sid = in_delegation_sid
				);
END;

PROCEDURE GetIndRegionMatrixTags(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_tag_group_id				tag_group.tag_group_id%TYPE;
BEGIN
	SELECT tag_visibility_matrix_group_id
	  INTO v_tag_group_id
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_cur FOR
		SELECT tgm.tag_id, it.ind_sid, rt.region_sid
		  FROM tag_group_member tgm
		  JOIN tag t ON tgm.tag_id = t.tag_id
	 LEFT JOIN ind_tag it ON it.tag_id = tgm.tag_id
	 LEFT JOIN region_tag rt ON rt.tag_id = tgm.tag_id
		 WHERE tgm.tag_group_id = v_tag_group_id
		   AND ind_sid IN (SELECT ind_sid FROM delegation_ind WHERE delegation_sid = in_delegation_sid AND visibility != 'HIDE')
		   AND region_sid IN (SELECT region_sid FROM delegation_region WHERE delegation_sid = in_delegation_sid AND visibility != 'HIDE');
END;

FUNCTION IsCellVisibleInTagMatrix(
	in_sheet_id			IN	NUMBER,
	in_region_sid		IN	NUMBER,
	in_ind_sid			IN	NUMBER
) RETURN NUMBER
AS
	v_tag_group_id				tag_group.tag_group_id%TYPE;
	v_ind_tag_count				NUMBER;
	v_region_tag_count			NUMBER;
	v_matching_tag_count		NUMBER;
BEGIN
	SELECT tag_visibility_matrix_group_id
	  INTO v_tag_group_id
	  FROM delegation d
	  JOIN sheet s ON s.delegation_sid = d.delegation_sid
	 WHERE sheet_id = in_sheet_id
	   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF v_tag_group_id IS NULL THEN
		RETURN 1;
	END IF;

	-- Has a tag. Does the cell match it?
	SELECT COUNT(ind_sid)
	  INTO v_ind_tag_count
	  FROM ind_tag
	 WHERE ind_sid = in_ind_sid
	   AND tag_id IN (SELECT tag_id FROM tag_group_member WHERE tag_group_id = v_tag_group_id);
	
	SELECT COUNT(region_sid)
	  INTO v_region_tag_count
	  FROM region_tag
	 WHERE region_sid = in_region_sid
	   AND tag_id IN (SELECT tag_id FROM tag_group_member WHERE tag_group_id = v_tag_group_id);
	
	-- If the ind or the region (or both) are not tagged with this group at all, the question is visible
	IF v_ind_tag_count = 0 OR v_region_tag_count = 0 THEN
		RETURN 1;
	END IF;
	
	-- Both the ind and region are tagged with the selected group, so we need to check if they have a matching tag member
	SELECT COUNT(tag_id)
	  INTO v_matching_tag_count
	  FROM ind_tag
	 WHERE ind_sid = in_ind_sid
	   AND tag_id IN (SELECT tag_id FROM tag_group_member WHERE tag_group_id = v_tag_group_id)
	   AND tag_id IN (SELECT tag_id FROM region_tag WHERE region_sid = in_region_sid);
	
	RETURN CASE WHEN v_matching_tag_count > 0 THEN 1 ELSE 0 END;
END;

PROCEDURE GetDelegsForGridReg (
	in_region_sid			IN	region.region_sid%TYPE,
	in_grid_ind_sid			IN	delegation_grid.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.delegation_sid, s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
		  FROM delegation_ind di
		  JOIN sheet s ON di.delegation_sid = s.delegation_sid
		  JOIN delegation_region dr ON di.delegation_sid = dr.delegation_sid
		  JOIN delegation d ON di.delegation_sid = d.delegation_sid
		 WHERE di.ind_sid = in_grid_ind_sid
		   AND dr.region_sid = in_region_sid
		   AND d.parent_sid = d.app_sid
		 ORDER BY start_dtm ASC;
END;

PROCEDURE GetAllTranslations(
	in_region_sids			IN 	security_pkg.T_SID_IDS,
	in_ind_sids				IN 	security_pkg.T_SID_IDS,
	in_validation_lang		IN	delegation_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_regions					security.T_SID_TABLE;
	t_inds						security.T_SID_TABLE;
BEGIN
	t_regions := security_pkg.SidArrayToTable(in_region_sids);
	t_inds := security_pkg.SidArrayToTable(in_ind_sids);

	OPEN out_cur FOR
		WITH deleg AS (
			SELECT app_sid, delegation_sid, start_dtm, end_dtm, period_set_id, period_interval_id, from_plan, lvl, ROWNUM rn
			  FROM (
				SELECT d.app_sid, d.delegation_sid, d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id, CASE WHEN d.master_delegation_sid IS NULL THEN 0 ELSE 1 END from_plan, LEVEL lvl
				  FROM delegation d
				  JOIN (
					SELECT app_sid, delegation_sid, description
					  FROM delegation_description
					 WHERE app_sid = v_app_sid
					   AND lang = NVL(in_validation_lang, 'en')
				)dd ON d.app_sid = dd.app_sid AND d.delegation_sid = dd.delegation_sid
				 WHERE d.app_sid = v_app_sid
				   AND d.delegation_sid IN (
						SELECT DISTINCT delegation_sid 
						  FROM delegation_ind 
						 WHERE ind_sid IN(
							SELECT ind_sid
							  FROM ind
							 START WITH ind_sid IN (SELECT column_value FROM TABLE(t_inds))
						   CONNECT BY PRIOR ind_sid = parent_sid
						  )
						   AND delegation_sid IN (
								SELECT delegation_sid 
								  FROM delegation_region 
								 WHERE region_sid IN(
									SELECT NVL(link_to_region_sid, region_sid)
									  FROM region
									 START WITH region_sid IN (SELECT column_value FROM TABLE(t_regions))
								   CONNECT BY PRIOR region_sid = parent_sid)
						 )
				   )
				 START WITH d.parent_sid = v_app_sid
			   CONNECT BY PRIOR d.delegation_sid = d.parent_sid
				 ORDER SIBLINGS BY 
					   REGEXP_SUBSTR(LOWER(dd.description), '^\D*') NULLS FIRST, 
					   TO_NUMBER(REGEXP_SUBSTR(LOWER(dd.description), '[0-9]+')) NULLS FIRST, 
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(dd.description), '[0-9]+', 1, 2))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(dd.description), '[0-9]+', 1, 3))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(dd.description), '[0-9]+', 1, 4))) NULLS FIRST,
					   LOWER(dd.description), d.delegation_sid
			)
		)
		SELECT d.delegation_sid sid, dd.description, dd.lang, d.start_dtm, d.end_dtm, d.period_set_id, d.period_interval_id, d.from_plan, d.lvl so_level,
			   CASE WHEN dd.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM deleg d
		  JOIN aspen2.translation_set ts ON d.app_sid = ts.application_sid
		  LEFT JOIN delegation_description dd ON d.app_sid = dd.app_sid AND d.delegation_sid = dd.delegation_sid AND ts.lang = dd.lang
		 ORDER BY rn,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTranslations(
	in_delegation_sids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	delegation_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_deleg_sid_desc_tbl		T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_delegation_sids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of delegation sids do not match number of descriptions.');
	END IF;
	
	IF in_delegation_sids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_deleg_sid_desc_tbl.EXTEND(in_delegation_sids.COUNT);

	FOR i IN 1..in_delegation_sids.COUNT
	LOOP
		v_deleg_sid_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_delegation_sids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT dd.delegation_sid sid,
			   CASE dd.description WHEN ddt.description THEN 0 ELSE 1 END has_changed,
			   SQL_CheckDelegationPermission(v_act, dd.delegation_sid, DELEG_PERMISSION_WRITE) can_write
		  FROM delegation_description dd
		  JOIN TABLE(v_deleg_sid_desc_tbl) ddt ON dd.delegation_sid = ddt.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE SheetsWithSkippedAlerts(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_num_sheets_skipped_alerts	OUT	NUMBER
)
AS
	v_num_reminders		NUMBER(10) := 0;
	v_num_overdue		NUMBER(10) := 0;
BEGIN
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_REMINDER_SHEET) THEN
		SELECT COUNT(*)
		  INTO v_num_reminders
		  FROM sheet_with_last_action sla
		  JOIN v$delegation_user du ON sla.delegation_sid = du.delegation_sid
		  JOIN v$csr_user cu ON cu.csr_user_sid = du.user_sid
	 LEFT JOIN sheet_alert sa ON sla.sheet_id = sa.sheet_id
		 WHERE sla.delegation_sid = in_delegation_sid
		   AND sla.reminder_dtm < SYSDATE-Delegation_pkg.DELEG_ALERT_IGNORE_SHEETS_OLDER_THAN
		   AND sa.reminder_sent_dtm is null
		   AND sla.is_visible = 1
		   AND cu.active = 1
		   AND cu.send_alerts = 1
		   AND sla.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_OVERDUE_SHEET) THEN
		SELECT COUNT(*)
		  INTO v_num_overdue
		  FROM sheet_with_last_action sla
		  JOIN v$delegation_user du ON sla.delegation_sid = du.delegation_sid
		  JOIN v$csr_user cu ON cu.csr_user_sid = du.user_sid
	 LEFT JOIN sheet_alert sa ON sla.sheet_id = sa.sheet_id
		 WHERE sla.delegation_sid = in_delegation_sid
		   AND sla.submission_dtm < SYSDATE-Delegation_pkg.DELEG_ALERT_IGNORE_SHEETS_OLDER_THAN
		   AND sa.overdue_sent_dtm is null
		   AND sla.is_visible = 1
		   AND cu.active = 1
		   AND cu.send_alerts = 1
		   AND sla.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	out_num_sheets_skipped_alerts := v_num_reminders + v_num_overdue;
END;

PROCEDURE GetGridIndSidFromPath(
	in_path				IN	csr.delegation_grid.path%TYPE,
	out_ind_sid			OUT	csr.delegation_grid.ind_sid%TYPE
)
AS
BEGIN

	SELECT ind_sid 
	  INTO out_ind_sid
	  FROM csr.delegation_grid 
	 WHERE LOWER(PATH) = LOWER(in_path)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetObjectCountsForSheet(
	in_sheet_id				IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid		csr.sheet.delegation_sid%TYPE;
	v_region_count			NUMBER;
	v_ind_count				NUMBER;
	v_user_count			NUMBER;
BEGIN

	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM csr.sheet
	 WHERE sheet_id = in_sheet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT count(*)
	  INTO v_region_count
	  FROM csr.delegation_region
	 WHERE delegation_sid = v_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT count(*)
	  INTO v_ind_count
	  FROM csr.delegation_ind
	 WHERE delegation_sid = v_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT count(*)
	  INTO v_user_count
	  FROM csr.v$delegation_user
	 WHERE delegation_sid = v_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_cur FOR
		SELECT v_region_count regions, v_ind_count inds, v_user_count users
		  FROM DUAL;

END;

END;
/
