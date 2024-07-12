CREATE OR REPLACE PACKAGE BODY csr.test_audit_migration_pkg AS

v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_audit_so_sid				security.security_pkg.T_SID_ID;
v_reg_users_group_sid		security.security_pkg.T_SID_ID;
v_non_flow_at_id			internal_audit_type.internal_audit_type_id%TYPE;

-- Test specific variables
v_test_audit_sid			security.security_pkg.T_SID_ID;
v_test_group_sid			security.security_pkg.T_SID_ID;
v_test_role_sid				security.security_pkg.T_SID_ID;
v_csr_cap_sid				security.security_pkg.T_SID_ID;
v_close_audit_cap_sid		security.security_pkg.T_SID_ID;
v_import_nc_cap_sid			security.security_pkg.T_SID_ID;
v_user_sid					security.security_pkg.T_SID_ID;
v_user_act_id				security.security_pkg.T_ACT_ID;
v_ability_t					T_AUDIT_ABILITY_TABLE;
v_test_flow_sid				security.security_pkg.T_SID_ID;

-- Migration audit types/audits
v_at_no_roles_1				internal_audit_type.internal_audit_type_id%TYPE;
v_at_no_roles_2				internal_audit_type.internal_audit_type_id%TYPE;
v_at_auditor_role_1			internal_audit_type.internal_audit_type_id%TYPE;
v_at_auditor_role_2			internal_audit_type.internal_audit_type_id%TYPE;
v_at_aud_con_role_1			internal_audit_type.internal_audit_type_id%TYPE;
v_at_aud_con_role_2			internal_audit_type.internal_audit_type_id%TYPE;

v_audit_no_roles_1			internal_audit.internal_audit_sid%TYPE;
v_audit_no_roles_2			internal_audit.internal_audit_sid%TYPE;
v_audit_auditor_role_1		internal_audit.internal_audit_sid%TYPE;
v_audit_auditor_role_2		internal_audit.internal_audit_sid%TYPE;
v_audit_aud_con_role_1		internal_audit.internal_audit_sid%TYPE;
v_audit_aud_con_role_2		internal_audit.internal_audit_sid%TYPE;

/* End setup */

PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
	csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	security.user_pkg.LogonAdmin;
END;

PROCEDURE SetUpFixture
AS
BEGIN
	security.user_pkg.LogonAdmin;
	
	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' ||'audit-migration-test.credit360.com');
		TearDownFixture;
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	csr_app_pkg.CreateApp('audit-migration-test.credit360.com', '/standardbranding/styles', 1, v_app_sid);
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
	unit_test_pkg.EnableAudits;
	enable_pkg.EnableWorkflow;
	unit_test_pkg.CreateAuditsNoWf;
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_audit_so_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	SELECT internal_audit_type_id
	  INTO v_non_flow_at_id 
	  FROM internal_audit_type
	 WHERE label = 'Non WF audit';
END;

PROCEDURE SetUp
AS
	v_groups_sid 			security.security_pkg.T_SID_ID;
	v_admins_sid 			security.security_pkg.T_SID_ID;
	v_auditors_sid 			security.security_pkg.T_SID_ID;
	v_auditor_admins_sid	security.security_pkg.T_SID_ID;
	v_audit_dacl_id			security.security_pkg.T_ACL_ID;
BEGIN
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
	v_test_audit_sid := NULL;
	v_test_group_sid := NULL;
	v_user_sid := NULL;

	v_reg_users_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
	v_csr_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities');

	-- reset dacl for Audits SO
	v_groups_sid 		 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 		 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_auditors_sid 		 := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit users');
	v_auditor_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit administrators');
	v_audit_dacl_id		 := security.acl_pkg.GetDACLIDForSID(v_audit_so_sid);
	
	security.acl_pkg.DeleteAllACEs(v_act_id, v_audit_dacl_id);
	security.acl_pkg.AddACE(v_act_id, v_audit_dacl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, v_audit_dacl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_auditors_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_ADD_CONTENTS);
	security.acl_pkg.AddACE(v_act_id, v_audit_dacl_id, -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
				v_auditor_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
END;

PROCEDURE TearDown
AS
	v_migration_flow_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
	IF v_test_audit_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_test_audit_sid);
	END IF;
	
	-- Clean up data created by the migration, if any
	BEGIN
		v_migration_flow_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Workflows/' || audit_migration_pkg.MIGRATION_WORKFLOW_NAME);
		UPDATE internal_audit
		   SET flow_item_id = NULL
		 WHERE flow_item_id IN (
			SELECT flow_item_id
			  FROM flow_item
			 WHERE flow_sid = v_migration_flow_sid
		 );
		
		UPDATE internal_audit_type
		   SET flow_sid = NULL
		 WHERE flow_sid = v_migration_flow_sid;
		
		security.securableobject_pkg.DeleteSO(v_act_id, v_migration_flow_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	IF v_test_group_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_test_group_sid);
	END IF;
	IF v_user_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_user_sid);
	END IF;
	
	IF v_audit_no_roles_1 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_no_roles_1);
	END IF;
	
	IF v_audit_no_roles_2 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_no_roles_2);
	END IF;
	
	IF v_audit_auditor_role_1 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_auditor_role_1);
	END IF;
	
	IF v_audit_auditor_role_2 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_auditor_role_2);
	END IF;
	
	IF v_audit_aud_con_role_1 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_aud_con_role_1);
	END IF;
	
	IF v_audit_aud_con_role_2 IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_audit_aud_con_role_2);
	END IF;
	
	DELETE FROM internal_audit_type
	 WHERE internal_audit_type_id IN (
		v_at_no_roles_1, v_at_no_roles_2, v_at_auditor_role_1, v_at_auditor_role_2,
		v_at_aud_con_role_1, v_at_aud_con_role_2
	);
	
	IF v_test_role_sid IS NOT NULL THEN
		UPDATE internal_audit_type
		   SET auditor_role_sid = NULL
		 WHERE auditor_role_sid = v_test_role_sid;
		 
		UPDATE internal_audit_type
		   SET audit_contact_role_sid = NULL
		 WHERE audit_contact_role_sid = v_test_role_sid;
		 
		security.securableobject_pkg.DeleteSO(v_act_id, v_test_role_sid);
	END IF;
	
	FOR r IN (
		SELECT flow_state_id
		  FROM flow_state
		 WHERE lookup_key LIKE audit_migration_pkg.MIGRATION_STATE_LOOKUP_KEY || '%'
	)
	LOOP
		UPDATE internal_audit
		   SET flow_item_id = NULL
		 WHERE flow_item_id IN (
			SELECT flow_item_id
			  FROM flow_item
			 WHERE current_state_id = r.flow_state_id
		 );
		
		flow_pkg.DeleteState(in_flow_state_id => r.flow_state_id);
	END LOOP;
	
	IF v_test_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_test_flow_sid);
	END IF;
END;

/* Helpers */
PROCEDURE AssertFlowItem(
	in_audit_sid		security.security_pkg.T_SID_ID,
	in_expect_exists	BOOLEAN := TRUE
)
AS
	v_flow_item_id	NUMBER;
BEGIN
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM internal_audit
	 WHERE internal_audit_sid = in_audit_sid;

	IF in_expect_exists THEN
		unit_test_pkg.AssertIsTrue(v_flow_item_id IS NOT NULL, 'Expected a flow item for the audit');
	ELSE
		unit_test_pkg.AssertIsTrue(v_flow_item_id IS NULL, 'Didn''t expect a flow item for the audit');
	END IF;
END;

PROCEDURE AssertAbility(
	in_ability_t		T_AUDIT_ABILITY_TABLE,
	in_ability_id		NUMBER,
	in_expected_perm	security.security_pkg.T_PERMISSION
)
AS
	v_perm				security.security_pkg.T_PERMISSION;
BEGIN
	SELECT NVL(MAX(permission_set), 0)
	  INTO v_perm
	  FROM TABLE(in_ability_t)
	 WHERE flow_capability_id =in_ability_id;

	unit_test_pkg.AssertAreEqual(in_expected_perm, v_perm, 'Permission set is not the expected one for capability with id:'||in_ability_id);
END;

PROCEDURE AssertWriteAbilities(
	in_ability_t		T_AUDIT_ABILITY_TABLE
)
AS
	v_full_perm		security_pkg.T_PERMISSION := security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE;
BEGIN
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DL_REPORT, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG, in_expected_perm => 2);
	-- Test FLOW_CAP_AUDIT_CLOSURE separately as it depends on CSR capability
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_COPY, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_SCORE, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DRAFT_ISSUES, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_VIEW_USERS, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_FINDING_TYPE, in_expected_perm => v_full_perm);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, in_expected_perm => v_full_perm);
END;

PROCEDURE AssertReadAbilities(
	in_ability_t		T_AUDIT_ABILITY_TABLE
)
AS
BEGIN
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DL_REPORT, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_COPY, in_expected_perm => 2);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DELETE, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_SCORE, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DRAFT_ISSUES, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_VIEW_USERS, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_FINDING_TYPE, in_expected_perm => security_pkg.PERMISSION_READ);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY, in_expected_perm => 0);
	AssertAbility(in_ability_t => in_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, in_expected_perm => security_pkg.PERMISSION_READ);
END;

PROCEDURE ValidateFlowStateGroups
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_state_role_capability
	 WHERE group_sid IS NULL
	    OR EXISTS(
			SELECT 1 FROM role WHERE role_sid = group_sid 
		)
		OR group_sid = v_reg_users_group_sid; 

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected only applicable groups in flow_state_role_capability table');
END;

PROCEDURE AssertAuditTypeWorkflow(
	in_audit_type_id				IN internal_audit_type.internal_audit_type_id%TYPE,
	in_expected_flow_name			IN flow.label%TYPE,
	in_expected_leg_closed_def		IN internal_audit_type.use_legacy_closed_definition%TYPE DEFAULT 0
)
AS
	v_flow_name						flow.label%TYPE;
	v_audit_type_name				internal_audit_type.label%TYPE;
	v_use_legacy_close_def			NUMBER;
	v_use_leg_assert_msg			VARCHAR2(1000);
		
BEGIN
	SELECT label, use_legacy_closed_definition, 
		CASE
			WHEN in_expected_leg_closed_def = 1 THEN
				'Expected audit type ''' || label || ''' to use legacy definition of audit closure'
			ELSE
				'Expected audit type ''' || label || ''' to use standard workflow definition of audit closure'
		END
	  INTO v_audit_type_name, v_use_legacy_close_def, v_use_leg_assert_msg
	  FROM internal_audit_type
	 WHERE internal_audit_type_id = in_audit_type_id;
	
	unit_test_pkg.AssertAreEqual(in_expected_leg_closed_def, v_use_legacy_close_def, v_use_leg_assert_msg);

	SELECT f.label
	  INTO v_flow_name
	  FROM internal_audit_type iat
	  JOIN flow f ON f.flow_sid = iat.flow_sid
	 WHERE internal_audit_type_id = in_audit_type_id;
	
	unit_test_pkg.AssertAreEqual(in_expected_flow_name, v_flow_name, 'Audit type ''' || v_audit_type_name || ''' has incorrect workflow');
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		-- Assume this isn't because the audit type wasn't found - that's just a test setup issue
		unit_test_pkg.TestFail('Audit type ''' || v_audit_type_name || ''' does not have a workflow');
END;

PROCEDURE AssertAuditWorkflow(
	in_audit_sid					IN internal_audit.internal_audit_sid%TYPE,
	in_expected_flow_name			IN flow.label%TYPE,
	in_expected_flow_state			IN flow_state.label%TYPE,
	in_expected_role_sid			IN flow_state_role.role_sid%TYPE DEFAULT NULL
)
AS
	v_audit_label					internal_audit.label%TYPE;
	v_flow_name						flow.label%TYPE;
	v_flow_state_name				flow_state.label%TYPE;
	v_flow_state_id					flow_state.flow_state_id%TYPE;
	v_flow_state_role_count			NUMBER;
BEGIN
	SELECT label
	  INTO v_audit_label
	  FROM internal_audit
	 WHERE internal_audit_sid = in_audit_sid;
	
	BEGIN
		SELECT f.label
		  INTO v_flow_name
		  FROM internal_audit ia
		  JOIN flow_item fi ON fi.flow_item_id = ia.flow_item_id
		  JOIN flow f ON f.flow_sid = fi.flow_sid
		 WHERE ia.internal_audit_sid = in_audit_sid;
		
		unit_test_pkg.AssertAreEqual(in_expected_flow_name, v_flow_name, 'Audit ''' || v_audit_label || ''' is not in the expected workflow');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			unit_test_pkg.TestFail('Audit ''' || v_audit_label || ''' expected to be in workflow');
	END;
	
	SELECT fs.label, fs.flow_state_id
	  INTO v_flow_state_name, v_flow_state_id
	  FROM internal_audit ia
	  JOIN flow_item fi ON fi.flow_item_id = ia.flow_item_id
	  JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id
	 WHERE ia.internal_audit_sid = in_audit_sid;
	
	unit_test_pkg.AssertAreEqual(in_expected_flow_state, v_flow_state_name, 'Audit ''' || v_audit_label || ''' is not in the expected workflow state');
	
	IF in_expected_role_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_flow_state_role_count
		  FROM flow_state_role
		 WHERE flow_state_id = v_flow_state_id
		   AND role_sid = in_expected_role_sid;
		
		IF v_flow_state_role_count = 0 THEN
			unit_test_pkg.TestFail('Workflow state ''' || in_expected_flow_state || ''' is missing an expected role');
		END IF;
	END IF;
END;

/* Tests */
PROCEDURE IdenticalPermissions_Pass
AS
BEGIN
	unit_test_pkg.AssertIsTrue(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to be possible');
END;

PROCEDURE AuditWithExtraGroup_Fail
AS
BEGIN
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_test_audit_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE AuditWithMissingGroups_Fail
AS
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_test_audit_sid));
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE AuditWithExtraPerm_Fail
AS
	v_test_audit_acl_id					security.security_pkg.T_ACL_ID;
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	v_test_audit_acl_id := security.acl_pkg.GetDACLIDForSID(v_test_audit_sid);
	UPDATE security.acl
	   SET permission_set = security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE
	 WHERE acl_id = v_test_audit_acl_id
	   AND sid_id = v_test_group_sid;
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE AuditWithMissingPerm_Fail
AS
	v_test_audit_acl_id					security.security_pkg.T_ACL_ID;
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	v_test_audit_acl_id := security.acl_pkg.GetDACLIDForSID(v_test_audit_sid);
	UPDATE security.acl
	   SET permission_set = security.security_pkg.PERMISSION_READ
	 WHERE acl_id = v_test_audit_acl_id
	   AND sid_id = v_test_group_sid;
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE AggPermissionMatch_Pass
AS
	v_test_audit_acl_id					security.security_pkg.T_ACL_ID;
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	v_test_audit_acl_id := security.acl_pkg.GetDACLIDForSID(v_test_audit_sid);
	UPDATE security.acl
	   SET permission_set = security.security_pkg.PERMISSION_READ
	 WHERE acl_id = v_test_audit_acl_id
	   AND sid_id = v_test_group_sid;
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_test_audit_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 2,
		v_test_group_sid, security.security_pkg.PERMISSION_WRITE);
	unit_test_pkg.AssertIsTrue(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to be possible');
END;

PROCEDURE AggPermissionMismatch_Fail
AS
	v_test_audit_acl_id					security.security_pkg.T_ACL_ID;
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	v_test_audit_acl_id := security.acl_pkg.GetDACLIDForSID(v_test_audit_sid);
	UPDATE security.acl
	   SET permission_set = security.security_pkg.PERMISSION_READ
	 WHERE acl_id = v_test_audit_acl_id
	   AND sid_id = v_test_group_sid;
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_test_audit_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 2,
		v_test_group_sid, security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE NonCsrGroupPermission_Fail
AS
	v_auditor_user_sid					security.security_pkg.T_SID_ID := unit_test_pkg.GetOrCreateUser('audit_coordinator');
BEGIN
	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_auditor_user_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);
	
	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE CloseAudWithUserPerm_Fail
AS
BEGIN
	v_csr_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities');
	v_close_audit_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Close audits');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_user_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to not be possible');
END;

PROCEDURE CloseAudWithGroup_Pass
AS
BEGIN
	v_csr_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Capabilities');
	v_close_audit_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Close audits');
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	unit_test_pkg.AssertIsTrue(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to be possible');
END;

PROCEDURE ImportFindWithNonGroup_Fail
AS
BEGIN
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_csr_cap_sid, security.security_pkg.SO_CONTAINER, 'Can import audit non-compliances', v_import_nc_cap_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_import_nc_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Can import audit non-compliances');
	END;

	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_user_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration not to be possible');
END;

PROCEDURE AllowPermSet_Pass
AS
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);

	unit_test_pkg.AssertIsTrue(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration to be possible');
END;

PROCEDURE DenyPermSet_Fail
AS
BEGIN
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_DENY, 3,
	 	v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	
	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid);

	unit_test_pkg.AssertIsFalse(audit_migration_pkg.ValidateSiteMigration = audit_migration_pkg.VALID_SUCCESS, 'Expected migration not to be possible');
END;

/* Migration */

PROCEDURE MigrateAudit_NoWorfklow
AS
BEGIN
	/* Setup audit types and audits */
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT no roles 1',
		out_audit_type_id => v_at_no_roles_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit no roles 1',
		in_audit_type_id => v_at_no_roles_1,
		out_sid => v_audit_no_roles_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT no roles 2',
		out_audit_type_id => v_at_no_roles_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit no roles 2',
		in_audit_type_id => v_at_no_roles_2,
		out_sid => v_audit_no_roles_2
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 1',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with audit contact role 1',
		in_audit_type_id => v_at_aud_con_role_1,
		out_sid => v_audit_aud_con_role_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 2',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with audit contact role 2',
		in_audit_type_id => v_at_aud_con_role_2,
		out_sid => v_audit_aud_con_role_2
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 1',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with auditor role 1',
		in_audit_type_id => v_at_auditor_role_1,
		out_sid => v_audit_auditor_role_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 2',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with auditor role 2',
		in_audit_type_id => v_at_auditor_role_2,
		out_sid => v_audit_auditor_role_2
	);
	
	/* Run migration */
	audit_migration_pkg.MigrateAudits;
	
	/* TEST: migrated audits with no auditor/audit contact roles share the same workflow */
	AssertAuditTypeWorkflow(v_at_no_roles_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME, 1);
	AssertAuditTypeWorkflow(v_at_no_roles_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME, 1);
	
	AssertAuditWorkflow(v_audit_no_roles_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME, audit_migration_pkg.MIGRATION_STATE_NAME);
	AssertAuditWorkflow(v_audit_no_roles_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME, audit_migration_pkg.MIGRATION_STATE_NAME);
	
	/* TEST: migrated audit types with audit contact roles each have their own workflow */
	AssertAuditTypeWorkflow(v_at_aud_con_role_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with audit contact role 1', 1);
	AssertAuditTypeWorkflow(v_at_aud_con_role_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with audit contact role 2', 1);
	
	AssertAuditWorkflow(v_audit_aud_con_role_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with audit contact role 1',
		audit_migration_pkg.MIGRATION_STATE_NAME, v_test_role_sid);
	AssertAuditWorkflow(v_audit_aud_con_role_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with audit contact role 2',
		audit_migration_pkg.MIGRATION_STATE_NAME, v_test_role_sid);
	
	/* TEST: migrated audit types with auditor roles each have their own workflow */
	AssertAuditTypeWorkflow(v_at_auditor_role_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with auditor role 1', 1);
	AssertAuditTypeWorkflow(v_at_auditor_role_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with auditor role 2', 1);
	
	AssertAuditWorkflow(v_audit_auditor_role_1, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with auditor role 1',
		audit_migration_pkg.MIGRATION_STATE_NAME, v_test_role_sid);
	AssertAuditWorkflow(v_audit_auditor_role_2, audit_migration_pkg.MIGRATION_WORKFLOW_NAME || ': AT with auditor role 2',
		audit_migration_pkg.MIGRATION_STATE_NAME, v_test_role_sid);
END;

PROCEDURE MigrateAudit_Workflow
AS
	v_workflow_name					VARCHAR2(255) := 'TEST_FLOW';
	v_default_state_id				flow_state.flow_state_id%TYPE;
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	
	/* Setup workflow */
	unit_test_pkg.GetOrCreateWorkflow(
		in_label					=> v_workflow_name,
		in_flow_alert_class			=> 'audit',
		out_sid						=> v_test_flow_sid
	);
	-- Don't really need this, but whatever
	unit_test_pkg.GetOrCreateWorkflowState(
		in_flow_sid					=> v_test_flow_sid,
		in_state_label				=> 'Default',
		in_state_lookup_key			=> 'DEFAULT',
		out_flow_state_id			=> v_default_state_id
	);
	
	/* Setup audit types and audits sharing the same workflow */
	unit_test_pkg.CreateAuditType(
		in_label => 'AT no roles 1',
		out_audit_type_id => v_at_no_roles_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit no roles 1',
		in_audit_type_id => v_at_no_roles_1,
		out_sid => v_audit_no_roles_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT no roles 2',
		out_audit_type_id => v_at_no_roles_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit no roles 2',
		in_audit_type_id => v_at_no_roles_2,
		out_sid => v_audit_no_roles_2
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 1',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with audit contact role 1',
		in_audit_type_id => v_at_aud_con_role_1,
		out_sid => v_audit_aud_con_role_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 2',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with audit contact role 2',
		in_audit_type_id => v_at_aud_con_role_2,
		out_sid => v_audit_aud_con_role_2
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 1',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_1
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with auditor role 1',
		in_audit_type_id => v_at_auditor_role_1,
		out_sid => v_audit_auditor_role_1
	);
	
	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 2',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_2
	);
	unit_test_pkg.CreateAudit(
		in_label => 'Audit with auditor role 2',
		in_audit_type_id => v_at_auditor_role_2,
		out_sid => v_audit_auditor_role_2
	);
	UPDATE internal_audit_type
	   SET flow_sid = v_test_flow_sid
	 WHERE internal_audit_type_id IN (
		v_at_aud_con_role_1, v_at_aud_con_role_2, v_at_auditor_role_1, v_at_auditor_role_2,
		v_at_no_roles_1, v_at_no_roles_2
	 );
	
	/* Run migration */
	audit_migration_pkg.MigrateAudits;
	
	/* TEST: migrated audits with no auditor/audit contact roles share the same workflow state */
	AssertAuditTypeWorkflow(v_at_no_roles_1, v_workflow_name);
	AssertAuditTypeWorkflow(v_at_no_roles_2, v_workflow_name);
	
	AssertAuditWorkflow(v_audit_no_roles_1, v_workflow_name, audit_migration_pkg.MIGRATION_STATE_NAME);
	AssertAuditWorkflow(v_audit_no_roles_2, v_workflow_name, audit_migration_pkg.MIGRATION_STATE_NAME);
	
	/* TEST: migrated audit types with audit contact roles each have their own workflow state */
	AssertAuditTypeWorkflow(v_at_aud_con_role_1, v_workflow_name);
	AssertAuditTypeWorkflow(v_at_aud_con_role_2, v_workflow_name);
	
	AssertAuditWorkflow(v_audit_aud_con_role_1, v_workflow_name,
		audit_migration_pkg.MIGRATION_STATE_NAME || ': AT with audit contact role 1', v_test_role_sid);
	AssertAuditWorkflow(v_audit_aud_con_role_2, v_workflow_name,
		audit_migration_pkg.MIGRATION_STATE_NAME || ': AT with audit contact role 2', v_test_role_sid);
	
	/* TEST: migrated audit types with auditor roles each have their own workflow state */
	AssertAuditTypeWorkflow(v_at_auditor_role_1, v_workflow_name);
	AssertAuditTypeWorkflow(v_at_auditor_role_2, v_workflow_name);
	
	AssertAuditWorkflow(v_audit_auditor_role_1, v_workflow_name,
		audit_migration_pkg.MIGRATION_STATE_NAME || ': AT with auditor role 1', v_test_role_sid);
	AssertAuditWorkflow(v_audit_auditor_role_2, v_workflow_name,
		audit_migration_pkg.MIGRATION_STATE_NAME || ': AT with auditor role 2', v_test_role_sid);
END;

PROCEDURE MigratedAudit_Write
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit; -- need to commit before logging for this user

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	unit_test_pkg.AssertIsTrue(audit_pkg.HasWriteAccess(v_test_audit_sid), 'Expected write access on the migrated audit');
	unit_test_pkg.AssertIsTrue(audit_pkg.HasReadAccess(v_test_audit_sid), 'Expected read access on the migrated audit');
	unit_test_pkg.AssertIsFalse(audit_pkg.HasDeleteAccess(v_test_audit_sid), 'Didn''t expect delete access on the migrated audit');

	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

PROCEDURE MigratedAudit_Read
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);

	-- act
	audit_migration_pkg.MigrateAudits;
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	unit_test_pkg.AssertIsFalse(audit_pkg.HasWriteAccess(v_test_audit_sid), 'Didn''t expect write access on the migrated audit');
	unit_test_pkg.AssertIsTrue(audit_pkg.HasReadAccess(v_test_audit_sid), 'Expected read access on the migrated audit');

	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

PROCEDURE MigratedAudit_Write_Delete
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');
	
	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	unit_test_pkg.AssertIsTrue(audit_pkg.HasWriteAccess(v_test_audit_sid), 'Expected write access on the migrated audit');
	unit_test_pkg.AssertIsTrue(audit_pkg.HasDeleteAccess(v_test_audit_sid), 'Expected delete access on the migrated audit');

	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

PROCEDURE MigratedAudit_Read_Abilities
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
	v_ability_t		T_AUDIT_ABILITY_TABLE;
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	AssertReadAbilities(v_ability_t);
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security_pkg.PERMISSION_READ);

	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

PROCEDURE MigratedAudit_Write_Abilities
AS
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	ValidateFlowStateGroups;

	AssertWriteAbilities(v_ability_t);

	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DELETE, in_expected_perm => 0);
	-- read only (from SO) because CSR capability is missing
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security.security_pkg.PERMISSION_READ);
	
	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

-- old audit permission model was a bit strange, delete was write + delete.
PROCEDURE MigratedAudit_Wr_Del_Abilities
AS
BEGIN
	-- arrange
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);

	ValidateFlowStateGroups;

	AssertWriteAbilities(v_ability_t);
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DELETE, in_expected_perm => 2);
	-- read missing because it's not on the SO and write missing because we don't have the CSR capability
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => 0);
	-- logonadmin
	security.user_pkg.LogonAdmin('audit-migration-test.credit360.com');
END;

PROCEDURE MigratedAudit_RegUserToGroup
AS
BEGIN
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_reg_users_group_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_reg_users_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;
	commit;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
	
	ValidateFlowStateGroups;

	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT, in_expected_perm => security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
END;

PROCEDURE MigratedAudit_RoleToGroup
AS
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_role_sid);
	commit;

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_role_sid, security.security_pkg.PERMISSION_READ);

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;
	commit; -- so new group membership will become effective

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
	
	ValidateFlowStateGroups;

	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT, in_expected_perm => security_pkg.PERMISSION_READ);
END;

PROCEDURE MigratedAudit_Close
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
	v_ability_t		T_AUDIT_ABILITY_TABLE;
BEGIN
	-- arrange
	v_close_audit_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Close audits');
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;
	commit; -- so new group membership will become effective

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
		
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => 3);
END;


PROCEDURE MigratedAudit_ImportNC
AS
	v_user_act_id	security.security_pkg.T_ACT_ID;
	v_ability_t		T_AUDIT_ABILITY_TABLE;
BEGIN
	-- arrange
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_csr_cap_sid, security.security_pkg.SO_CONTAINER, 'Can import audit non-compliances', v_import_nc_cap_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_import_nc_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Can import audit non-compliances');
	END;
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_import_nc_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.AddAce(v_act_id, security.acl_pkg.GetDACLIDForSID(v_audit_so_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_test_group_sid, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);

	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid, v_test_group_sid);
	commit;

	security.acl_pkg.ResetDescendantACLs(v_act_id, v_audit_so_sid); 

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_non_flow_at_id, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit

	-- act
	audit_migration_pkg.MigrateAudits;
	commit; -- so new group membership will become effective

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
		
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC, in_expected_perm => 2);
END;

PROCEDURE MigrateAudit_AuditorRole
AS
	v_region_sids				security.security_pkg.T_SID_IDS;
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 1',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_1
	);

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_at_auditor_role_1, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM internal_audit
	 WHERE internal_audit_sid = v_test_audit_sid;
	
	role_pkg.SetRoleMembersForUser(
		in_act_id					=> security.security_pkg.GetAct,
		in_role_sid					=> v_test_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sids
	);
	
	COMMIT;

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
	AssertWriteAbilities(v_ability_t);
	-- Check the auditor role doesn't also get delete
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_DELETE, in_expected_perm => 0);
	-- Closure is only read because it also requires the Close Audits capability
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security.security_pkg.PERMISSION_READ);
END;

PROCEDURE MigrateAudit_AuditContactRole
AS
	v_region_sids				security.security_pkg.T_SID_IDS;
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');

	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 1',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_1
	);

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_at_aud_con_role_1, v_test_audit_sid);
	AssertFlowItem(v_test_audit_sid, FALSE); -- make sure that's a non-wf audit
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM internal_audit
	 WHERE internal_audit_sid = v_test_audit_sid;
	
	role_pkg.SetRoleMembersForUser(
		in_act_id					=> security.security_pkg.GetAct,
		in_role_sid					=> v_test_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sids
	);
	
	COMMIT;

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);

	-- assert 
	AssertFlowItem(v_test_audit_sid);
	AssertReadAbilities(v_ability_t);
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security.security_pkg.PERMISSION_READ);
END;

PROCEDURE MigrateAudit_AR_With_Closure
AS
	v_region_sids				security.security_pkg.T_SID_IDS;
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');
	
	v_close_audit_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Close audits');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	unit_test_pkg.CreateAuditType(
		in_label => 'AT with auditor role 1',
		in_auditor_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_auditor_role_1
	);

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_at_auditor_role_1, v_test_audit_sid);
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM internal_audit
	 WHERE internal_audit_sid = v_test_audit_sid;
	
	role_pkg.SetRoleMembersForUser(
		in_act_id					=> security.security_pkg.GetAct,
		in_role_sid					=> v_test_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sids
	);
	
	COMMIT;

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);
	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
END;


PROCEDURE MigrateAudit_ACR_With_Closure
AS
	v_region_sids				security.security_pkg.T_SID_IDS;
BEGIN
	v_test_role_sid := unit_test_pkg.GetOrCreateRole('TEST_ROLE');
	v_user_sid := unit_test_pkg.GetOrCreateUser('random.user');
	
	v_close_audit_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_cap_sid, 'Close audits');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_close_audit_cap_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
	 	v_test_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	unit_test_pkg.CreateAuditType(
		in_label => 'AT with audit contact role 1',
		in_audit_contact_role_sid => v_test_role_sid,
		out_audit_type_id => v_at_aud_con_role_1
	);

	unit_test_pkg.CreateAudit('TEST_AUDIT', v_at_aud_con_role_1, v_test_audit_sid);
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM internal_audit
	 WHERE internal_audit_sid = v_test_audit_sid;
	
	role_pkg.SetRoleMembersForUser(
		in_act_id					=> security.security_pkg.GetAct,
		in_role_sid					=> v_test_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sids
	);
	
	COMMIT;

	-- act
	audit_migration_pkg.MigrateAudits;

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);
	v_ability_t := audit_pkg.GetAbilities(in_audit_sid => v_test_audit_sid, in_include_all => 1);
	AssertAbility(in_ability_t => v_ability_t, in_ability_id => csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, in_expected_perm => security.security_pkg.PERMISSION_READ);
END;

END;
/