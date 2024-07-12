CREATE OR REPLACE PACKAGE BODY csr.audit_migration_pkg AS

PROCEDURE LogError(
	in_valid_type_id	IN NUMBER,
	in_object_sid		IN NUMBER,
	in_grantee_sid		IN NUMBER,
	in_message			IN VARCHAR
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	INSERT INTO audit_migration_failure (audit_migration_failure_id, object_sid, grantee_sid, validation_type_id, message)
	VALUES(audit_migration_fail_seq.nextval, in_object_sid, in_grantee_sid, in_valid_type_id, in_message);
	
	COMMIT;
END;

PROCEDURE ClearLog(
	in_valid_type_id	IN NUMBER DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	DELETE FROM audit_migration_failure 
	 WHERE app_sid = security_pkg.getapp
	   AND (in_valid_type_id IS NULL OR validation_type_id = in_valid_type_id);

	COMMIT;
END;

FUNCTION NonWFAuditsExist
RETURN BOOLEAN
AS
	v_non_flow_aud_type_cnt	NUMBER;
	v_non_flow_audit_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_non_flow_aud_type_cnt
	  FROM internal_audit_type
	 WHERE flow_sid IS NULL;

	SELECT COUNT(*)
	  INTO v_non_flow_audit_cnt
	  FROM internal_audit ia
	  JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
	 WHERE ia.flow_item_id IS NULL
	   AND ia.deleted = 0;
	
	RETURN (v_non_flow_aud_type_cnt + v_non_flow_audit_cnt) > 0;
END;

FUNCTION DoAuditDaclsMatchAuditNode
RETURN BOOLEAN
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_audits_sid	security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Audits');
	v_audits_dacl	security.acl.acl_id%TYPE := acl_pkg.GetDACLIDForSID(v_audits_sid);
	v_pass			BOOLEAN := TRUE;
	v_audits_perm_t	security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE ();
BEGIN
	ClearLog(MIGR_VALID_DACL_DIFF);

	SELECT SECURITY.T_ORDERED_SID_ROW(sid_id => sid_id, pos => bitoragg(permission_set))
	  BULK COLLECT INTO v_audits_perm_t
	  FROM security.acl
	 WHERE acl_id = v_audits_dacl
	 GROUP BY sid_id; 
	
	-- check if a sid has been given TAKE_OWNERSHIP but not read or write (no cases found on live, still just to be safe...)
	FOR d IN (
		SELECT sid_id, bitand(pos, security_pkg.PERMISSION_STANDARD_ALL) permission_set
		  FROM TABLE(v_audits_perm_t)
	)
	LOOP
		IF bitand(d.permission_set, security_pkg.PERMISSION_TAKE_OWNERSHIP) = security_pkg.PERMISSION_TAKE_OWNERSHIP 
			AND (bitand(d.permission_set, security_pkg.PERMISSION_READ) != security_pkg.PERMISSION_READ 
				OR bitand(d.permission_set, security_pkg.PERMISSION_WRITE) != security_pkg.PERMISSION_WRITE) 
		THEN
			v_pass := FALSE;
			LogError(in_valid_type_id => MIGR_VALID_DACL_DIFF, in_object_sid => v_audits_sid, 
				in_grantee_sid => d.sid_id, in_message => 'Permission set contains "Take ownership" but not Read or Write');
		END IF;
	END LOOP;

	FOR r IN (
		SELECT dacl_id, ia.internal_audit_sid
		  FROM security.securable_object so
		  JOIN csr.internal_audit ia ON so.sid_id = ia.internal_audit_sid
		 WHERE so.parent_sid_id = v_audits_sid
		   AND ia.flow_item_id IS NULL
		   AND ia.deleted = 0
	)
	LOOP
		-- permission set that exists only on root node
		FOR d IN (
			SELECT sid_id, bitand(pos, security_pkg.PERMISSION_STANDARD_ALL) permission_set
			  FROM TABLE(v_audits_perm_t)
			 MINUS
			SELECT sid_id, bitand(bitoragg(permission_set), security_pkg.PERMISSION_STANDARD_ALL) permission_set
			  FROM security.acl
			 WHERE acl_id = r.dacl_id
			 GROUP BY sid_id
		
		)
		LOOP
			v_pass := FALSE;
			LogError(in_valid_type_id => MIGR_VALID_DACL_DIFF, in_object_sid => r.internal_audit_sid, 
				in_grantee_sid => d.sid_id, in_message => 'Permission set exists only in the root node');
		END LOOP;

		-- permission set that exists only on a child audit
		FOR d IN (
			SELECT sid_id, bitand(bitoragg(permission_set), security_pkg.PERMISSION_STANDARD_ALL) permission_set
			  FROM security.acl
			 WHERE acl_id = r.dacl_id
			 GROUP BY sid_id
			 MINUS
			SELECT sid_id, bitand(pos, security_pkg.PERMISSION_STANDARD_ALL) permission_set
			  FROM TABLE(v_audits_perm_t)
		)
		LOOP
			v_pass := FALSE;
			LogError(in_valid_type_id => MIGR_VALID_DACL_DIFF, in_object_sid => r.internal_audit_sid, 
				in_grantee_sid => d.sid_id, in_message => 'Permission set exists only in the child SO');
		END LOOP;
	END LOOP;

	RETURN v_pass;
END;

FUNCTION CheckAllDaclsAreAllow
RETURN BOOLEAN
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_audits_sid	security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Audits');
	v_pass			BOOLEAN := TRUE;
BEGIN
	ClearLog(MIGR_VALID_DENY_GRANT);
	-- first check parent Audit's SO
	FOR r IN (
		SELECT acl.sid_id
		  FROM security.acl
		 WHERE acl.acl_id = acl_pkg.GetDACLIDForSID(v_audits_sid)
		   AND acl.ace_type = security_pkg.ACE_TYPE_DENY
	)
	LOOP
		LogError(in_valid_type_id => MIGR_VALID_DENY_GRANT, in_object_sid => v_audits_sid, 
			in_grantee_sid => r.sid_id, in_message => 'Deny grant(s) found on the root node');
		v_pass := FALSE;
	END LOOP;

	-- ...now the child SOs 
	FOR r IN (
		SELECT ia.internal_audit_sid, acl.sid_id
		  FROM security.acl acl
		  JOIN security.securable_object so ON so.dacl_id = acl.acl_id 
		  JOIN csr.internal_audit ia ON so.sid_id = ia.internal_audit_sid
		 WHERE so.parent_sid_id = v_audits_sid
		   AND acl.ace_type = security_pkg.ACE_TYPE_DENY
		   AND ia.flow_item_id IS NULL
		   AND ia.deleted = 0
	)
	LOOP
		LogError(in_valid_type_id => MIGR_VALID_DENY_GRANT, in_object_sid => r.internal_audit_sid, 
			in_grantee_sid => r.sid_id, in_message => 'Deny grant(s) found on the child audit node');
		v_pass := FALSE;
	END LOOP;

	RETURN v_pass;
END;

FUNCTION CheckSOGrantsOnlyGroups(
	in_sid_id			security_pkg.T_SID_ID,
	in_valid_type_id	NUMBER
)
RETURN BOOLEAN
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_groups_sid	security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_ucd_sid		security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
	v_pass			BOOLEAN := TRUE;
BEGIN
	ClearLog(in_valid_type_id);

	FOR r IN (
		SELECT acl.sid_id
		  FROM security.securable_object so
		  JOIN security.acl ON so.dacl_id = acl.acl_id
		  JOIN security.securable_object so_grantee ON acl.sid_id = so_grantee.sid_id
		 WHERE so.sid_id = in_sid_id
		   AND so_grantee.sid_id NOT IN (
				security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 
				security.security_pkg.SID_BUILTIN_ADMINISTRATORS,
				v_ucd_sid
			)
		   AND so_grantee.parent_sid_id != v_groups_sid
	)
	LOOP
		LogError(in_valid_type_id => in_valid_type_id, in_object_sid => in_sid_id, 
			in_grantee_sid => r.sid_id, in_message => 'Non-supported granted SO found');
		v_pass := FALSE;
	END LOOP;

	RETURN v_pass;
END;

FUNCTION CheckAuditNodeOnlyGroups
RETURN BOOLEAN
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_audits_sid	security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Audits');
BEGIN
	RETURN CheckSOGrantsOnlyGroups(v_audits_sid, MIGR_VALID_NODE_NON_SUP_SO);
END;

FUNCTION CheckCSRCapability(
	in_cap_name		capability.name%TYPE
)
RETURN BOOLEAN
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_csr_cap_sid	security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities');
	v_cap_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, in_cap_name);
 		RETURN CheckSOGrantsOnlyGroups(v_cap_sid, MIGR_VALID_CSR_CAP);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RETURN TRUE;
	END;
END;

FUNCTION CheckCSRCapabilities
RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCSRCapability('Close audits') AND CheckCSRCapability('Can import audit non-compliances');
END;

FUNCTION ValidateSiteMigration
RETURN T_VALIDATION_RESULT
AS
	v_app_sid			security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_result			T_VALIDATION_RESULT := VALID_SUCCESS;
BEGIN
	ClearLog;

	IF v_app_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'ValidateSiteMigration must be run for a specific site context');
	END IF;
	
	IF NOT audit_migration_pkg.NonWFAuditsExist THEN
		RETURN NO_NON_WF_AUDITS_FOUND; -- no need to check anything else
	END IF;
	
	IF NOT audit_migration_pkg.DoAuditDaclsMatchAuditNode THEN
		v_result := bitwise_pkg.bitor(v_result, FAIL_AUDIT_DACL_MATCH);
	END IF;

	IF NOT audit_migration_pkg.CheckAuditNodeOnlyGroups THEN
		v_result := bitwise_pkg.bitor(v_result, FAIL_AUDIT_SUPPORT_SO);
	END IF;

	IF NOT audit_migration_pkg.CheckAllDaclsAreAllow THEN
		v_result := bitwise_pkg.bitor(v_result, FAIL_DENY_ACL);
	END IF;

	IF NOT audit_migration_pkg.CheckCSRCapabilities THEN
		v_result := bitwise_pkg.bitor(v_result, FAIL_CSR_CAPABILITY);
	END IF;

	RETURN v_result;
END;

PROCEDURE GetValidationFailures(
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	in_valid_type_id		IN NUMBER,
	out_total_rows			OUT NUMBER,
	out_cur 				OUT SYS_REFCURSOR
)
AS
	v_act_id	security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_so_app_length	NUMBER := LENGTH(security.securableobject_pkg.getPathFromSid(v_act_id, v_app_sid));
BEGIN
	IF NOT (security_pkg.IsAdmin(v_act_id) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetValidationErrors can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM (
		SELECT audit_migration_failure_id, object_sid, grantee_sid, validation_type_id,
			ROW_NUMBER() OVER (PARTITION BY object_sid, grantee_sid, validation_type_id ORDER BY audit_migration_failure_id) rn 
		  FROM audit_migration_failure amf
		 WHERE validation_type_id = in_valid_type_id OR in_valid_type_id IS NULL
		 ORDER BY audit_migration_failure_id
	 	)x
	 WHERE x.rn = 1;
	  
	OPEN out_cur FOR 
		SELECT x.audit_migration_failure_id, x.object_sid, x.grantee_sid, x.message,
			DECODE(grantee_sid, NULL, '', SUBSTR(security.securableobject_pkg.getPathFromSid(v_act_id, grantee_sid), v_so_app_length + 2)) grantee_so_name,
			CASE validation_type_id
				WHEN 1 THEN 'Differences in SO permissions'
				WHEN 2 THEN 'Non-supported granted SO'
				WHEN 3 THEN 'ACL type (allow/ deny)'
				WHEN 4 THEN 'CSR capabilities'
				WHEN 5 THEN 'Some audit types have roles set'
				ELSE '' 
			END validation_type_desc 
		  FROM(
			SELECT audit_migration_failure_id, object_sid, grantee_sid, message, validation_type_id
			  FROM (
				  SELECT audit_migration_failure_id, object_sid, grantee_sid, validation_type_id, message
				    FROM (
					SELECT audit_migration_failure_id, object_sid, grantee_sid, validation_type_id, message,
						ROW_NUMBER() OVER (PARTITION BY object_sid, grantee_sid, validation_type_id ORDER BY audit_migration_failure_id) rn 
		  			  FROM audit_migration_failure amf
					 WHERE validation_type_id = in_valid_type_id OR in_valid_type_id IS NULL
		 			 ORDER BY audit_migration_failure_id
					)m
				   WHERE m.rn = 1
			  )
			)x
		 WHERE ROWNUM > in_start AND ROWNUM <= (in_start + in_page_size);
	
END;

/* Migration */

FUNCTION CreateWorkflow (
	in_label						IN	flow.label%TYPE
)
RETURN flow.flow_sid%TYPE
AS
	v_flow_sid				flow.flow_sid%TYPE;
	v_workflows_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	BEGIN
		v_flow_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), v_workflows_sid, in_label);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			flow_pkg.CreateFlow(
				in_label			=> in_label,
				in_parent_sid		=> v_workflows_sid,
				in_flow_alert_class	=> 'audit',
				out_flow_sid		=> v_flow_sid
			);
	END;
	
	RETURN v_flow_sid;
END;

-- Basically a copy from flow_pkg with the option to provide an initial
-- state. We don't want the flow item to get created in the default state
-- in case any logic hangs off that, and having this as an overload in
-- flow_pkg seems unnecessary.
PROCEDURE AddFlowItem(
	in_flow_sid					IN	flow.flow_sid%TYPE,
	in_flow_state_id			IN	flow_state.flow_state_id%TYPE,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
)
AS
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN
	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(flow_item_id_seq.NEXTVAL, in_flow_sid, in_flow_state_id)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => out_flow_item_id);
END;

FUNCTION GetStandardSpecificPermSet (
	in_permission_set				IN	security.acl.permission_set%TYPE
)
RETURN flow_state_role_capability.permission_set%TYPE
AS
BEGIN
	IF bitand(in_permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE THEN 
		RETURN security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE; -- Read and write (mimics how AuditAbilities are created in C# when there is no workflow)
	ELSIF bitand(in_permission_set, security.security_pkg.PERMISSION_READ) = security.security_pkg.PERMISSION_READ THEN 
		RETURN security.security_pkg.PERMISSION_READ;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION GetBooleanPermSet (
	in_permission_set				IN	security.acl.permission_set%TYPE,
	in_check						IN	security.acl.permission_set%TYPE DEFAULT security.security_pkg.PERMISSION_WRITE
)
RETURN flow_state_role_capability.permission_set%TYPE
AS
BEGIN
	RETURN CASE WHEN bitand(in_permission_set, in_check) > 0 THEN security.security_pkg.PERMISSION_WRITE ELSE 0 END;
END;

FUNCTION GetCapabilityPermissionSet (
	in_cap_name						IN	security.securable_object.name%TYPE,
	in_group_sid					IN	security.security_pkg.T_SID_ID
)
RETURN flow_state_role_capability.permission_set%TYPE
AS
	v_capabilities_sid				security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities');
	v_acl_permission_set			security.acl.permission_set%TYPE;
BEGIN
	BEGIN
		SELECT bitoragg(acl.permission_set) permission_set
		  INTO v_acl_permission_set
		  FROM security.securable_object so 
		  JOIN security.acl acl ON acl.acl_id = so.dacl_id
		 WHERE so.name = in_cap_name
		   AND so.parent_sid_id = v_capabilities_sid
		   AND acl.sid_id = in_group_sid
		 GROUP BY acl.sid_id;

		RETURN v_acl_permission_set;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;
END;

FUNCTION GetFlowCapPermSetFromSO(
	in_group_sid					security.security_pkg.T_SID_ID,
	in_permission_set				security.acl.permission_set%TYPE,
	in_flow_capability_id			flow_capability.flow_capability_id%TYPE,
	in_is_role						NUMBER DEFAULT 0
)
RETURN flow_state_role_capability.permission_set%TYPE
IS 
BEGIN
	RETURN
		CASE 
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_SURVEY THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION THEN GetBooleanPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_DL_REPORT THEN GetBooleanPermSet(in_permission_set, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG THEN GetBooleanPermSet(in_permission_set, security.security_pkg.PERMISSION_WRITE)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE THEN GetStandardSpecificPermSet(bitand(in_permission_set, security.bitwise_pkg.bitor(security.security_pkg.PERMISSION_READ, GetCapabilityPermissionSet('Close audits', in_group_sid))))
			/* N.B. copy also requires ADD_CONTENTS on audits SO (as long as audits have SOs) */
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_COPY THEN GetBooleanPermSet(in_permission_set, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE)
			/* N.B. delete also requires ADD_CONTENTS on trash */
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_DELETE THEN GetBooleanPermSet(in_permission_set, security.security_pkg.PERMISSION_DELETE)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC AND in_is_role = 0 THEN GetBooleanPermSet(GetCapabilityPermissionSet('Can import audit non-compliances', in_group_sid), security_pkg.PERMISSION_WRITE)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC AND in_is_role = 1 THEN 0
			/* No permissions on documents for SO audits */
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS THEN 0
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_SCORE THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY THEN GetStandardSpecificPermSet(in_permission_set)
			/* Not used */
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_DRAFT_ISSUES THEN 0
			-- Never set in auditAbilities when there's no flow item, so try to keep this consistent
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_VIEW_USERS THEN 0
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_FINDING_TYPE THEN GetStandardSpecificPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS THEN GetBooleanPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY THEN GetBooleanPermSet(in_permission_set)
			WHEN in_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE THEN GetStandardSpecificPermSet(in_permission_set)
			ELSE 0
		END;
END;

FUNCTION GetOrCreateApplicableGroup(
	in_sid					IN security.security_pkg.T_SID_ID,
	io_migrated_group_map_t IN OUT T_AUDIT_MIGRATED_GROUP_MAP
)
RETURN security.security_pkg.T_SID_ID
AS
	v_act_id		security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_groups_sid 	security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups');
	v_group_sid		security.security_pkg.T_SID_ID;
	v_role_count	NUMBER;
	v_new_so_name	security.securable_object.name%TYPE := security.securableobject_pkg.GetName(v_act_id, in_sid)||' - Audit Migration';
BEGIN	
	-- try to find it in the lookup table
	BEGIN
		SELECT new_group_sid
		  INTO v_group_sid
		  FROM TABLE(io_migrated_group_map_t)
		 WHERE original_sid = in_sid;

		RETURN v_group_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- create a new group for roles or registered users
	SELECT COUNT(*)
	  INTO v_role_count
	  FROM csr.role
	 WHERE role_sid = in_sid;

	IF v_role_count > 0 OR in_sid = securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers') THEN
		 -- create new group
		BEGIN
			v_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, v_new_so_name);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
					v_new_so_name, security.class_pkg.GetClassId('CSRUserGroup'), v_group_sid);
		END;
		 -- add member
		security.group_pkg.AddMember(v_act_id, in_sid, v_group_sid);

		io_migrated_group_map_t.extend;
		io_migrated_group_map_t(io_migrated_group_map_t.COUNT) := T_AUDIT_MIGRATED_GROUP(in_sid, v_group_sid);
	ELSE 
		v_group_sid := in_sid; -- original group is fine
	END IF;

	RETURN v_group_sid;
END;

PROCEDURE SetFlowStateRoleCapability(
	in_flow_state_id		IN flow_state.flow_state_id%TYPE,
	in_group_sid			IN security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_capability_id	IN flow_capability.flow_capability_id%TYPE,
	in_permission_set		IN security_pkg.T_PERMISSION,
	in_is_role				IN NUMBER DEFAULT 0
)
AS
	v_group_sid				security_pkg.T_SID_ID := CASE WHEN in_is_role = 0 THEN in_group_sid ELSE NULL END;
	v_role_sid				security_pkg.T_SID_ID := CASE WHEN in_is_role <> 0 THEN in_group_sid ELSE NULL END;
BEGIN
	INSERT INTO flow_state_role_capability(flow_state_rl_cap_id, flow_state_id, group_sid, role_sid,
			flow_capability_id, permission_set)
		VALUES (flow_state_rl_cap_id_seq.NEXTVAL, in_flow_state_id, v_group_sid, v_role_sid, in_flow_capability_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.flow_state_role_capability
			   SET permission_set = in_permission_set
			 WHERE flow_state_id = in_flow_state_id
			   AND flow_capability_id = in_flow_capability_id
			   AND (group_sid = v_group_sid OR role_sid = v_role_sid);
	
END;

PROCEDURE SetFlowStatePermissions (
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_group_sid			IN	flow_state_role.group_sid%TYPE DEFAULT NULL,
	in_is_role				IN	NUMBER DEFAULT 0,
	in_permission_set		IN	flow_state_role_capability.permission_set%TYPE
)
AS
	v_permission_set		flow_state_role_capability.permission_set%TYPE;
	v_group_sid				security_pkg.T_SID_ID := CASE WHEN in_is_role = 0 THEN in_group_sid ELSE NULL END;
	v_role_sid				security_pkg.T_SID_ID := CASE WHEN in_is_role <> 0 THEN in_group_sid ELSE NULL END;
BEGIN

	BEGIN
		INSERT INTO flow_state_role (flow_state_id, role_sid, group_sid)
		VALUES (in_flow_state_id, v_role_sid, v_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR fc IN (
		SELECT flow_capability_id
		  FROM flow_capability
		 WHERE flow_alert_class = 'audit'
	)
	LOOP
		v_permission_set := GetFlowCapPermSetFromSO(in_group_sid, in_permission_set, fc.flow_capability_id, in_is_role);
		
		SetFlowStateRoleCapability (
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> in_group_sid,
			in_is_role				=> in_is_role,
			in_flow_capability_id	=> fc.flow_capability_id,
			in_permission_set		=> v_permission_set
		);
	END LOOP;
	
	FOR cfc IN (
		SELECT survey_capability_id, change_survey_capability_id
		  FROM internal_audit_type_survey iats
		  JOIN ia_type_survey_group itsg on iats.ia_type_survey_group_id = itsg.ia_type_survey_group_id
		  JOIN internal_audit_type iat on iat.internal_audit_type_id = iats.internal_audit_type_id
		 WHERE iat.app_sid = security_pkg.GetApp
		   AND iat.flow_sid = (
				SELECT flow_sid
				  FROM flow_state
				 WHERE flow_state_id = in_flow_state_id
			)
	)
	LOOP
		SetFlowStateRoleCapability (
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> in_group_sid,
			in_flow_capability_id	=> cfc.survey_capability_id,
			in_permission_set		=> GetStandardSpecificPermSet(in_permission_set),
			in_is_role				=> in_is_role
		);

		SetFlowStateRoleCapability (
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> in_group_sid,
			in_flow_capability_id	=> cfc.change_survey_capability_id,
			in_permission_set		=> GetBooleanPermSet(in_permission_set),
			in_is_role				=> in_is_role
		);
	END LOOP;
END;

PROCEDURE MigratePermissions (
	in_flow_state_id				IN	flow_state.flow_state_id%TYPE,
	in_audit_contact_role_sid		IN	internal_audit_type.audit_contact_role_sid%TYPE DEFAULT NULL,
	in_auditor_role_sid				IN	internal_audit_type.auditor_role_sid%TYPE DEFAULT NULL
)
AS
	v_group_sid				security.security_pkg.T_SID_ID;
	v_group_map				T_AUDIT_MIGRATED_GROUP_MAP := T_AUDIT_MIGRATED_GROUP_MAP();
BEGIN
	FOR r IN (
		SELECT acl.sid_id group_sid, bitoragg(acl.permission_set) permission_set
		  FROM security.securable_object so 
		  JOIN security.acl acl ON acl.acl_id = so.dacl_id
		  JOIN security.securable_object group_so ON group_so.sid_id = acl.sid_id
		 WHERE so.name = 'Audits'
		   AND so.parent_sid_id = security.security_pkg.getApp
		   AND group_so.sid_id NOT IN (security.security_pkg.SID_BUILTIN_ADMINISTRATOR, security.security_pkg.SID_BUILTIN_ADMINISTRATORS,
				security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Users/UserCreatorDaemon'))
		   AND group_so.parent_sid_id = security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Groups')
		   AND acl.ace_type != security_pkg.ACE_TYPE_DENY
		 GROUP BY acl.sid_id
	)
	LOOP
		v_group_sid := GetOrCreateApplicableGroup(r.group_sid, v_group_map);
		
		SetFlowStatePermissions(
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> v_group_sid,
			in_permission_set		=> r.permission_set
		);
	END LOOP;
	
	IF in_auditor_role_sid IS NOT NULL THEN
		SetFlowStatePermissions(
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> in_auditor_role_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE,
			in_is_role				=> 1
		);
	END IF;
	
	IF in_audit_contact_role_sid IS NOT NULL THEN
		SetFlowStatePermissions(
			in_flow_state_id		=> in_flow_state_id,
			in_group_sid			=> in_audit_contact_role_sid,
			in_permission_set		=> security.security_pkg.PERMISSION_READ,
			in_is_role				=> 1
		);
	END IF;
END;

FUNCTION CreateMigrationState (
	in_flow_sid						IN	flow.flow_sid%TYPE,
	in_state_label					IN	flow_state.label%TYPE,
	in_state_lookup_key				IN	flow_state.lookup_key%TYPE,
	in_audit_contact_role_sid		IN	internal_audit_type.audit_contact_role_sid%TYPE DEFAULT NULL,
	in_auditor_role_sid				IN	internal_audit_type.auditor_role_sid%TYPE DEFAULT NULL
)
RETURN flow_state.flow_state_id%TYPE
AS
	v_new_state_id			flow_state.flow_state_id%TYPE;
BEGIN
	v_new_state_id := flow_pkg.GetStateId(
		in_flow_sid				=> in_flow_sid,
		in_lookup_key			=> in_state_lookup_key
	);
	
	IF v_new_state_id IS NULL OR v_new_state_id = 0 THEN
		flow_pkg.CreateState(
			in_flow_sid				=> in_flow_sid,
			in_label				=> in_state_label,
			in_lookup_key			=> in_state_lookup_key,
			in_flow_state_nature_id	=> NULL,
			out_flow_state_id		=> v_new_state_id
		);
	END IF;
	-- and then set the permissions...
	MigratePermissions(
		in_flow_state_id			=> v_new_state_id,
		in_audit_contact_role_sid	=> in_audit_contact_role_sid,
		in_auditor_role_sid			=> in_auditor_role_sid
	);
	RETURN v_new_state_id;
END;

PROCEDURE MigrateAudits(
	in_force				IN	NUMBER DEFAULT 0
)
AS
	v_flow_sid				flow.flow_sid%TYPE;
	v_new_state_id			flow_state.flow_state_id%TYPE;
	v_state_ids				csr_data_pkg.T_NUMBER_ARRAY;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	
	v_count					NUMBER;
BEGIN
	IF ValidateSiteMigration = NO_NON_WF_AUDITS_FOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'No non-WF audits found. Nothing to migrate');
	END IF;

	IF in_force = 0 AND ValidateSiteMigration != VALID_SUCCESS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Site cannot be migrated');
	END IF;
	
	BEGIN
		INSERT INTO customer_flow_alert_class (flow_alert_class)
		VALUES ('audit');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- Make sure workflows have been enabled. Expect this to be re-runnable
	enable_pkg.EnableWorkflow;
	
	-- First deal with audit types that already have workflows but have audits missing a flow item.
	
	-- Audit types that have the same workflow and no audit type roles can share the same migration
	-- state (which needs to be added to the existing workflow) ...
	FOR r IN (
		SELECT DISTINCT flow_sid
		  FROM internal_audit_type
		 WHERE internal_audit_type_id IN (
			SELECT internal_audit_type_id
			  FROM internal_audit
			 WHERE flow_item_id IS NULL
			   AND deleted = 0
			)
		   AND auditor_role_sid IS NULL
		   AND audit_contact_role_sid IS NULL
		   AND flow_sid IS NOT NULL
	)
	LOOP
		v_new_state_id := CreateMigrationState(
			in_flow_sid				=> r.flow_sid,
			in_state_label			=> MIGRATION_STATE_NAME,
			in_state_lookup_key		=> MIGRATION_STATE_LOOKUP_KEY
		);
		
		FOR a IN (
			SELECT internal_audit_type_id
			  FROM internal_audit_type
			 WHERE internal_audit_type_id IN (
				SELECT internal_audit_type_id
				  FROM internal_audit
				 WHERE flow_item_id IS NULL
				   AND deleted = 0
				)
			   AND auditor_role_sid IS NULL
			   AND audit_contact_role_sid IS NULL
			   AND flow_sid = r.flow_sid
		)
		LOOP
			v_state_ids(a.internal_audit_type_id) := v_new_state_id;
		END LOOP;
	END LOOP;
	
	-- ... while audit types that have audit type roles need a migration state each, which will include permissions
	-- that reflect the audit type roles.
	FOR r IN (
		SELECT internal_audit_type_id, label, flow_sid, audit_contact_role_sid, auditor_role_sid
		  FROM internal_audit_type
		 WHERE internal_audit_type_id IN (
			SELECT internal_audit_type_id
			  FROM internal_audit
			 WHERE flow_item_id IS NULL
			   AND deleted = 0
			)
		   AND (auditor_role_sid IS NOT NULL OR audit_contact_role_sid IS NOT NULL)
		   AND flow_sid IS NOT NULL
	)
	LOOP
		v_new_state_id := CreateMigrationState(
			in_flow_sid					=> r.flow_sid,
			in_state_label				=> MIGRATION_STATE_NAME || ': ' || r.label,
			in_state_lookup_key			=> MIGRATION_STATE_LOOKUP_KEY || '_' || r.internal_audit_type_id,
			in_audit_contact_role_sid	=> r.audit_contact_role_sid,
			in_auditor_role_sid			=> r.auditor_role_sid
		);
		
		v_state_ids(r.internal_audit_type_id) := v_new_state_id;
	END LOOP;
	
	-- On to audit types that don't have a workflow:
	
	-- Again, audit types that don't have audit type roles can share the same workflow ...
	SELECT COUNT(*)
	  INTO v_count
	  FROM internal_audit_type
	 WHERE flow_sid IS NULL
	   AND audit_contact_role_sid IS NULL
	   AND auditor_role_sid IS NULL;
	
	IF v_count > 0 THEN
		v_flow_sid := CreateWorkflow(
			in_label				=> MIGRATION_WORKFLOW_NAME
		);
		
		v_new_state_id := CreateMigrationState(
			in_flow_sid				=> v_flow_sid,
			in_state_label			=> MIGRATION_STATE_NAME,
			in_state_lookup_key		=> MIGRATION_STATE_LOOKUP_KEY
		);
		
		FOR r IN (
			SELECT internal_audit_type_id
			  FROM internal_audit_type
			 WHERE flow_sid IS NULL
			   AND audit_contact_role_sid IS NULL
			   AND auditor_role_sid IS NULL
		)
		LOOP
			UPDATE internal_audit_type
			   SET flow_sid = v_flow_sid,
			       use_legacy_closed_definition = 1
			 WHERE internal_audit_type_id = r.internal_audit_type_id;
			
			v_state_ids(r.internal_audit_type_id) := v_new_state_id;
		END LOOP;
	END IF;
	
	-- ... and audit types with audit type roles require a workflow per type, with the
	-- default set reflecting the audit type role permissions.
	FOR r IN (
		SELECT internal_audit_type_id, label, audit_contact_role_sid, auditor_role_sid
		  FROM internal_audit_type
		 WHERE flow_sid IS NULL
		   AND (auditor_role_sid IS NOT NULL OR audit_contact_role_sid IS NOT NULL)
	)
	LOOP
		v_flow_sid := CreateWorkflow(
			in_label				=> MIGRATION_WORKFLOW_NAME || ': ' || r.label
		);
		
		v_new_state_id := CreateMigrationState(
			in_flow_sid					=> v_flow_sid,
			in_state_label				=> MIGRATION_STATE_NAME,
			in_state_lookup_key			=> MIGRATION_STATE_LOOKUP_KEY,
			in_audit_contact_role_sid	=> r.audit_contact_role_sid,
			in_auditor_role_sid			=> r.auditor_role_sid
		);
		
		UPDATE internal_audit_type
		   SET flow_sid = v_flow_sid,
			   use_legacy_closed_definition = 1
		 WHERE internal_audit_type_id = r.internal_audit_type_id;
		
		v_state_ids(r.internal_audit_type_id) := v_new_state_id;
	END LOOP;
	
	FOR r IN (
		SELECT ia.internal_audit_sid, iat.flow_sid, iat.internal_audit_type_id
		  FROM internal_audit ia
		  JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
		 WHERE ia.flow_item_id IS NULL
		   AND ia.deleted = 0
	)
	LOOP
		AddFlowItem(
			in_flow_sid				=> r.flow_sid,
			in_flow_state_id		=> v_state_ids(r.internal_audit_type_id),
			out_flow_item_id		=> v_flow_item_id
		);
		
		UPDATE internal_audit
		   SET flow_item_id = v_flow_item_id
		 WHERE internal_audit_sid = r.internal_audit_sid;
		
		BEGIN
			INSERT INTO migrated_audit (internal_audit_sid)
			VALUES (r.internal_audit_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE migrated_audit
				   SET migrated_dtm = SYSDATE
				 WHERE internal_audit_sid = r.internal_audit_sid;
		END;
	END LOOP;
END;

END;
/