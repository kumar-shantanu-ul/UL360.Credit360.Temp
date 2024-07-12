CREATE OR REPLACE PACKAGE BODY csr.test_finding_permission_pkg AS

v_site_name					VARCHAR(50) := 'finding-permission-test.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_user_act_id				security.security_Pkg.T_ACT_ID;
v_workflow_sid				security.security_pkg.T_SID_ID;
v_flow_state_id 			csr.flow_state.flow_state_id%TYPE;
v_audit_type_name			csr.internal_audit_type.label%TYPE;


-- NOTE: Objects with the following ids will be deleted after each test in the TearDown procedure
-- to prevent tests affecting each other in undesirable and unpredictable ways.

v_audit_sid					security.security_pkg.T_SID_ID;
v_audit_sid1				security.security_pkg.T_SID_ID;
v_audit_sid1_1				security.security_pkg.T_SID_ID;
v_audit_sid1_2				security.security_pkg.T_SID_ID;
v_audit_sid2				security.security_pkg.T_SID_ID;
v_audit_sid3				security.security_pkg.T_SID_ID;
v_audit_sid4				security.security_pkg.T_SID_ID;
v_audit_sid5_1				security.security_pkg.T_SID_ID;
v_audit_sid5_2				security.security_pkg.T_SID_ID;

v_capability_id				NUMBER;
v_capability_id1			NUMBER;
v_capability_id2			NUMBER;
v_capability_id3			NUMBER;
v_capability_id4			NUMBER;
v_capability_id5			NUMBER;

v_finding_id 				NUMBER;
v_finding_id1 				NUMBER;
v_finding_id2 				NUMBER;
v_finding_id2_1				NUMBER;
v_finding_id3 				NUMBER;
v_finding_id4 				NUMBER;

v_finding_Type_id 			NUMBER;
v_finding_Type_id1			NUMBER;
v_finding_Type_id2			NUMBER;
v_finding_Type_id3			NUMBER;
v_finding_Type_id4			NUMBER;
v_finding_Type_id5			NUMBER;

v_region_sid				security.security_pkg.T_SID_ID;

v_role_sid					security.security_pkg.T_SID_ID;
v_role_sid1					security.security_pkg.T_SID_ID;
v_role_sid2					security.security_pkg.T_SID_ID;
v_role_sid3					security.security_pkg.T_SID_ID;

v_user_sids					security_pkg.T_SID_IDS;


-----------------------------------------
-- ASSERTS
-----------------------------------------
PROCEDURE AssertAccessDenied(
	user_id			NUMBER,
	finding_id		NUMBER,
	has_access		BOOLEAN
)
AS
BEGIN
	csr.unit_test_pkg.AssertIsFalse(has_access, 'User with id ' || user_id || ' cannot access finding with id ' || finding_id);
END;

PROCEDURE AssertAccessAllowed(
	user_id			NUMBER,
	finding_id		NUMBER,
	has_access		BOOLEAN
)
AS
BEGIN
	csr.unit_test_pkg.AssertIsTrue(has_access, 'User with id ' || user_id || ' should be able to access finding with id ' || finding_id);
END;

FUNCTION GetCustomCapabilityId(
	in_finding_type_id					NUMBER,
	in_base_flow_capability_id			VARCHAR2
) RETURN NUMBER
AS
	v_capability_id		NUMBER;
BEGIN
	SELECT flow_capability_id
	  INTO v_capability_id
	  FROM csr.non_compliance_type_flow_cap
	 WHERE non_compliance_type_id = in_finding_type_id
	   AND base_flow_capability_id = in_base_flow_capability_id;

	RETURN v_capability_id;
END;

-----------------------------------------
-- TESTS
-----------------------------------------

-- Scenario: User trying to access a finding which does not exist
PROCEDURE UserCannotAccessNonExistingFinding
AS
	v_non_existing_finding_id 	NUMBER := 9999999999999;
	v_has_permission			BOOLEAN;
BEGIN
	-- Given a non existing finding

	-- When the user tries to access the finding
	csr.audit_pkg.CheckNonComplianceAccess(
		in_non_compliance_id	=> v_non_existing_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);

	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;
		WHEN OTHERS THEN
			v_has_permission := TRUE;

	-- Then the user cannot access the finding
	AssertAccessDenied(-1, v_non_existing_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding for an audit which does not have a workflow
PROCEDURE UserCannotAccessFinding
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with no workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When a normal user tries to access the finding 
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	csr.audit_pkg.CheckNonComplianceAccess(
		in_non_compliance_id	=>  v_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);
	
	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;
		WHEN OTHERS THEN
			v_has_permission := TRUE;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: Built-in administrator trying to access a finding for an audit which does not have a workflow
PROCEDURE AdminCanAccessFinding
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with no workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When the built-in administrator tries to access the finding 
	security.user_pkg.LogonAdmin(v_site_name);

	csr.audit_pkg.CheckNonComplianceAccess(
		in_non_compliance_id	=>  v_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);

	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;

	-- Then the buit-in administrator can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding for an audit which has a workflow
PROCEDURE UserCannotAccessFindingWithWorkflow
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When a normal user tries to access the finding 
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: Built-in administrator trying to access a finding for an audit which has a workflow
PROCEDURE AdminCanAccessFindingWithWorkFlow
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When the built-in administrator tries to access the finding 
	security.user_pkg.LogonAdmin(v_site_name);

	BEGIN
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the buit-in administrator can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding without any capability for an audit which has a workflow
PROCEDURE UserCannotAccessFindingWithoutCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	-- And no capability has been set
	-- When a normal user tries to access the finding 
	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;


-- Scenario: User trying to access a finding with the wrong capability for an audit which has a workflow
PROCEDURE UserCantAccessFindingWithWrongCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid					=> v_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sid
	);

	-- And the wrong capability has been set
	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> csr_data_pkg.FLOW_CAP_AUDIT_VIEW_USERS,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT7',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
	-- When a normal user tries to access the finding 
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding with the right capability for an audit which has a workflow
PROCEDURE UserCanAccessFindingWithRightCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid			=> v_role_sid,
		in_user_sid			=> v_user_sid,
		in_region_sids		=> v_region_sid
	);

	-- And the right capability has been set
	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT5',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When a normal user tries to access the finding 
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User denied access to a finding with an associated custom capability due to no permissions set against it
PROCEDURE UsrCantAccessFindingWithCustomCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability
	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- And a standard user belonging to a role which has not been assigned permissions through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding
		csr.audit_pkg.CheckNonComplianceAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User allowed access to a finding with an associated custom capability due to no read permissions set against it
PROCEDURE UserCantAccessFindingWithoutPermission
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability
	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User denied access to a finding with an associated custom capability due to a wrong permission set against it
PROCEDURE UserCantAccessFindingWithWrongPermission
AS
	v_has_permission		BOOLEAN;
	v_wrong_capability_id	NUMBER;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability

	v_finding_Type_id1 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 1');
	v_finding_Type_id2 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 2');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id1,
		in_name						=> 'FINDING'
	);

	v_capability_id := GetCustomCapabilityId(v_finding_Type_id1, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_wrong_capability_id := GetCustomCapabilityId(v_finding_Type_id2, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_wrong_capability_id,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User allowed access to a finding with an associated custom capability
PROCEDURE UserCanAccessFindingWithCustomCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability

	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	v_capability_id := GetCustomCapabilityId(v_finding_Type_id, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User allowed access to findings with associated custom capabilities and related to a given audit
PROCEDURE UserCanAccessPermittedFindingsForAudit
AS
	v_has_permission		BOOLEAN;
	v_perm_ids			 	security.T_SID_TABLE;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	-- Given an audit with associated workflow and with some related findings
	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_type_name => v_audit_type_name,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	-- some of which linked to a custom capability with read access 
	v_finding_Type_id1 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 1');
	v_finding_Type_id2:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 2');


	 v_finding_id1 := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id1,
		in_name						=> 'FINDING1'
	);

	 v_finding_id2 := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id2,
		in_name						=> 'FINDING2'
	);

	 v_finding_id2_1 := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id2,
		in_name						=> 'FINDING2.1'
	);

	v_capability_id1 := GetCustomCapabilityId(v_finding_Type_id1, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id1,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	v_capability_id2 := GetCustomCapabilityId(v_finding_Type_id2, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id2,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	-- some of which linked to a custom capability without readaccess
	v_finding_Type_id3 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 3');

	 v_finding_id3 := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id3,
		in_name						=> 'FINDING3'
	);

	-- some of which linked to a standard capability with read access
	v_finding_Type_id4 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 4', 0);

	 v_finding_id4 := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id4,
		in_name						=> 'FINDING4'
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	-- And a standard user belonging to a role which has been given read access through some of the capabilities above
	role_pkg.SetRoleMembersForUser(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid			=> v_role_sid,
		in_user_sid			=> v_user_sid,
		in_region_sids		=> v_region_sid
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the findings in the audit 
		v_perm_ids := csr.audit_pkg.GetPermissibleNCTypeIds(
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		if v_perm_ids.COUNT = 3 AND v_perm_ids(1) = v_finding_Type_id1 AND v_perm_ids(2) = v_finding_Type_id2 AND v_perm_ids(3) = v_finding_Type_id4 THEN
			v_has_permission := TRUE;
		ELSE
			csr.unit_test_pkg.AssertAreEqual(3, v_perm_ids.COUNT,
				'GetPermissibleNCTypeIds should return ' || v_finding_Type_id1 || ', ' || v_finding_Type_id2 || ', ' || v_finding_Type_id4);
		END IF;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can only access the findings which have been given read accesss through a standard or custom capability
	AssertAccessAllowed(v_user_sid,  v_audit_sid, v_has_permission);
END;

-- Scenario: User denied access to a finding type which belongs to another user and for which the first user has not been given read permission
PROCEDURE UserCannotAccessOtherUsersFindingTypes
AS
	v_has_permission				BOOLEAN;
	v_audits_by_custom_cap			csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;
	v_permitted_finding_type_ids	security.T_SID_TABLE;
	v_user_sid1						security.security_pkg.T_SID_ID;
	v_user_sid2						security.security_pkg.T_SID_ID;
BEGIN
	-- Given two users, each with their own distinct role, audit, finding type and custom capability

	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid1 := unit_test_pkg.GetOrCreateRole('ROLE1');
	v_role_sid2 := unit_test_pkg.GetOrCreateRole('ROLE2');

	v_finding_Type_id1 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 1');
	v_finding_Type_id2:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 2');

	v_user_sid1 := csr.unit_test_pkg.GetOrCreateUser('USER1');
	v_user_sid2 := csr.unit_test_pkg.GetOrCreateUser('USER2');
	v_user_sids(1) := v_user_sid1;
	v_user_sids(2) := v_user_sid2;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid1,
		in_user_sid		=> v_user_sid1,
		in_region_sids	=> v_region_sid
	);

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid2,
		in_user_sid		=> v_user_sid2,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid1 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT1',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid1,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid2 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT2',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid2,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_capability_id1 := GetCustomCapabilityId(v_finding_Type_id1, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_capability_id2 := GetCustomCapabilityId(v_finding_Type_id2, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id1,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid1,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id2,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid2,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid1, 60, v_user_act_id);

	BEGIN
		-- When a developer wants to determine which finding types a user has access to for any audit linked to the workflow

		v_audits_by_custom_cap := csr.audit_pkg.GetCustomPermissibleAuditNCTs(
			in_access => SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		SELECT DISTINCT non_compliance_type_id
		  BULK COLLECT INTO v_permitted_finding_type_ids
		  FROM TABLE(v_audits_by_custom_cap); 

		-- Then each user can only access finding types which related to them 

		IF v_permitted_finding_type_ids.COUNT = 1 AND v_permitted_finding_type_ids(1) = v_finding_Type_id1 THEN
			v_has_permission := TRUE;
		ELSE
			csr.unit_test_pkg.AssertAreEqual(1, v_audits_by_custom_cap.COUNT,
				'GetCustomPermissibleAuditNCTs should only return audits against finding type id: ' || v_finding_Type_id1);
		END IF;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	AssertAccessAllowed(v_user_sid1,  v_audit_sid1, v_has_permission);
END;



-- Scenario: User is only allowed access to findings for which a read permission has been granted
PROCEDURE UserCanOnlyAccessPermittedFindings
AS
	v_has_permission				BOOLEAN;
	v_audits_by_custom_cap			csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;
	v_permitted_finding_type_ids	security.T_SID_TABLE;
	v_user_sid1						security.security_pkg.T_SID_ID;
	v_user_sid2						security.security_pkg.T_SID_ID;
	v_user_sid3						security.security_pkg.T_SID_ID;
	v_user_sid4						security.security_pkg.T_SID_ID;
	v_user_sid5						security.security_pkg.T_SID_ID;
BEGIN
	-- Given a user having access to some findings with related custom or standard capabilities
	-- And other findings which the user has not access to related to other users, roles, audits, workflows, finding types, custom and standard capabilities
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid1 := unit_test_pkg.GetOrCreateRole('ROLE1');
	v_role_sid2 := unit_test_pkg.GetOrCreateRole('ROLE2');
	v_role_sid3 := unit_test_pkg.GetOrCreateRole('ROLE3');

	v_finding_Type_id1 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 1');
	v_finding_Type_id2:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 2');
	v_finding_Type_id3:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 3');
	v_finding_Type_id4:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 4');
	v_finding_Type_id5:= unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 5');

	v_user_sid1 := csr.unit_test_pkg.GetOrCreateUser('USER1');
	v_user_sid2 := csr.unit_test_pkg.GetOrCreateUser('USER2');
	v_user_sid3 := csr.unit_test_pkg.GetOrCreateUser('USER3');
	v_user_sid4 := csr.unit_test_pkg.GetOrCreateUser('USER4');
	v_user_sid5 := csr.unit_test_pkg.GetOrCreateUser('USER5');
	v_user_sids(1) := v_user_sid1;
	v_user_sids(2) := v_user_sid2;
	v_user_sids(3) := v_user_sid3;
	v_user_sids(4) := v_user_sid4;
	v_user_sids(5) := v_user_sid5;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid1,
		in_user_sid		=> v_user_sid1,
		in_region_sids	=> v_region_sid
	);

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid2,
		in_user_sid		=> v_user_sid2,
		in_region_sids	=> v_region_sid
	);

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid2,
		in_user_sid		=> v_user_sid3,
		in_region_sids	=> v_region_sid
	);

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid2,
		in_user_sid		=> v_user_sid4,
		in_region_sids	=> v_region_sid
	);

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid3,
		in_user_sid		=> v_user_sid5,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid1_1 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT1.1',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid1,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid1_2 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT1.2',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid1,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid2 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT2',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid2,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid3 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT3',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid3,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid4 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT4',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid4,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid5_1 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT5.1',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid5,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_audit_sid5_2 := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT5.2',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid5,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	v_capability_id1 := GetCustomCapabilityId(v_finding_Type_id1, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_capability_id2 := GetCustomCapabilityId(v_finding_Type_id2, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_capability_id3 := GetCustomCapabilityId(v_finding_Type_id3, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_capability_id4 := GetCustomCapabilityId(v_finding_Type_id4, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);
	v_capability_id5 := GetCustomCapabilityId(v_finding_Type_id5, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id1,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid1,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id3,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid1,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id4,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid1,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id1,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid2,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id3,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid2,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id3,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid3,
		in_group_sid		=> NULL
	);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id4,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid3,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid1, 60, v_user_act_id);

	BEGIN
		-- When one user tries to access all existing findings
		v_audits_by_custom_cap := csr.audit_pkg.GetCustomPermissibleAuditNCTs(
			in_access => SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		SELECT DISTINCT non_compliance_type_id
		  BULK COLLECT INTO v_permitted_finding_type_ids
		  FROM TABLE(v_audits_by_custom_cap); 

		-- Then the user can only access findings where read permissions has been granted through standard or custom capabilities
		IF v_permitted_finding_type_ids.COUNT = 3
			AND v_permitted_finding_type_ids(1) = v_finding_Type_id1 
			AND v_permitted_finding_type_ids(2) = v_finding_Type_id3 
			AND v_permitted_finding_type_ids(3) = v_finding_Type_id4
		THEN
			v_has_permission := TRUE;
		ELSE
			csr.unit_test_pkg.AssertAreEqual(3, v_permitted_finding_type_ids.COUNT,
				'GetCustomPermissibleAuditNCTs should only return audits against these finding types: ' 
				|| v_finding_Type_id1 || ', ' || v_finding_Type_id3 || ', ' || v_finding_Type_id4);
		END IF;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	AssertAccessAllowed(v_user_sid1,  v_audit_sid1_1, v_has_permission);
END;

-- Scenario: User trying to access a finding which does not exists tags
PROCEDURE UserCannotAccessNonExistingFindingsTags
AS
	v_non_existing_finding_id 	NUMBER := 9999999999999;
	v_has_permission			BOOLEAN;
BEGIN
	-- Given a non existing finding

	-- When the user tries to access the finding
	csr.audit_pkg.CheckNonComplianceTagAccess(
		in_non_compliance_id	=> v_non_existing_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);

	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;
		WHEN OTHERS THEN
			v_has_permission := TRUE;

	-- Then the user cannot access the finding
	AssertAccessDenied(-1, v_non_existing_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding for an audit which does not have a workflow
PROCEDURE UserCannotAccessFindingsTags
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with no workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When a normal user tries to access the finding 
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	csr.audit_pkg.CheckNonComplianceTagAccess(
		in_non_compliance_id	=>  v_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);
	
	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;
		WHEN OTHERS THEN
			v_has_permission := TRUE;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: Built-in administrator trying to access a finding for an audit which does not have a workflow
PROCEDURE AdminCanAccessFindingsTags
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with no workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	v_audit_sid := unit_test_pkg.GetOrCreateAudit(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When the built-in administrator tries to access the finding 
	security.user_pkg.LogonAdmin(v_site_name);

	csr.audit_pkg.CheckNonComplianceTagAccess(
		in_non_compliance_id	=>  v_finding_id,
		in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
	);

	v_has_permission := TRUE;

	EXCEPTION
		WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
			v_has_permission := FALSE;

	-- Then the buit-in administrator can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding for an audit which has a workflow
PROCEDURE UserCannotAccessFindingsTagsWithWorkflow
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When a normal user tries to access the finding 
	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: Built-in administrator trying to access a finding for an audit which has a workflow
PROCEDURE AdminCanAccessFindingsTagsWithWorkFlow
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	-- When the built-in administrator tries to access the finding 
	security.user_pkg.LogonAdmin(v_site_name);

	BEGIN
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the buit-in administrator can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding without any capability for an audit which has a workflow
PROCEDURE UserCannotAccessFindingsTagsWithoutCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	-- And no capability has been set
	-- When a normal user tries to access the finding 
	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;


-- Scenario: User trying to access a finding with the wrong capability for an audit which has a workflow
PROCEDURE UserCantAccessFindingsTagsWithWrongCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid					=> v_role_sid,
		in_user_sid					=> v_user_sid,
		in_region_sids				=> v_region_sid
	);

	-- And the wrong capability has been set
	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> csr_data_pkg.FLOW_CAP_AUDIT_VIEW_USERS,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT7',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
	-- When a normal user tries to access the finding 
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User trying to access a finding with the right capability for an audit which has a workflow
PROCEDURE UserCanAccessFindingsTagsWithRightCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid			=> v_role_sid,
		in_user_sid			=> v_user_sid,
		in_region_sids		=> v_region_sid
	);

	-- And the right capability has been set
	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> csr_data_pkg.FLOW_CAP_AUDIT_NC_TAGS,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT5',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid	=> v_audit_sid,
		in_name			=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When a normal user tries to access the finding 
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User denied access to a finding with an associated custom capability due to no permissions set against it
PROCEDURE UsrCantAccessFindingsTagsWithCustomCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability
	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- And a standard user belonging to a role which has not been assigned permissions through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;
	COMMIT; -- need to commit before logging as this user

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding
		csr.audit_pkg.CheckNonComplianceTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);
		v_has_permission := TRUE;

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User not allowed access to a finding with an associated custom capability due to no read permissions set against it
PROCEDURE UserCantAccessFindingsTagsWithoutPermission
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability
	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User denied access to a finding with an associated custom capability due to a wrong permission set against it
PROCEDURE UserCantAccessFindingsTagsWithWrongPermission
AS
	v_has_permission		BOOLEAN;
	v_wrong_capability_id	NUMBER;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability

	v_finding_Type_id1 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 1');
	v_finding_Type_id2 := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE 2');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id1,
		in_name						=> 'FINDING'
	);

	v_capability_id := GetCustomCapabilityId(v_finding_Type_id1, csr_data_pkg.FLOW_CAP_AUDIT_NC_TAGS);
	v_wrong_capability_id := GetCustomCapabilityId(v_finding_Type_id2, csr_data_pkg.FLOW_CAP_AUDIT_NC_TAGS);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_wrong_capability_id,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user cannot access the finding
	AssertAccessDenied(v_user_sid,  v_finding_id, v_has_permission);
END;

-- Scenario: User allowed access to a finding with an associated custom capability
PROCEDURE UserCanAccessFindingsTagsWithCustomCapability
AS
	v_has_permission		BOOLEAN;
	v_user_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_region_sid := csr.unit_test_pkg.GetOrCreateRegion('REGION');
	v_role_sid := unit_test_pkg.GetOrCreateRole('ROLE');

	-- Given a finding related to an audit with a workflow
	-- And linked to a finding type with associated custom capability

	v_finding_Type_id := unit_test_pkg.GetOrCreateNonComplianceTypeId('FINDING TYPE');

	-- And a standard user belonging to a role which has been given read access through the custom capability
	v_user_sid := csr.unit_test_pkg.GetOrCreateUser('USER');
	v_user_sids(1) := v_user_sid;

	role_pkg.SetRoleMembersForUser(
		in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid		=> v_role_sid,
		in_user_sid		=> v_user_sid,
		in_region_sids	=> v_region_sid
	);

	v_audit_sid := unit_test_pkg.GetOrCreateAuditWithFlow(
		in_name			=> 'AUDIT',
		in_region_sid	=> 	v_region_sid,
		in_user_sid		=> 	v_user_sid,
		in_flow_sid		=>  v_workflow_sid,
		in_audit_dtm	=>	ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -24)
	);

	 v_finding_id := unit_test_pkg.GetOrCreateNonComplianceId(
		in_audit_sid				=> v_audit_sid,
		in_non_compliance_type_id	=> v_finding_Type_id,
		in_name						=> 'FINDING'
	);

	v_capability_id := GetCustomCapabilityId(v_finding_Type_id, csr_data_pkg.FLOW_CAP_AUDIT_NC_TAGS);

	csr.unit_test_pkg.SetFlowCapability(
		in_flow_capability	=> v_capability_id,
		in_flow_state_id 	=> v_flow_state_id,
		in_permission_set	=> SECURITY.SECURITY_PKG.PERMISSION_READ,
		in_role_sid			=> v_role_sid,
		in_group_sid		=> NULL
	);

	COMMIT; -- need to commit before logging as this user

	security.user_pkg.LogonAuthenticated(v_user_sid, 60, v_user_act_id);

	BEGIN
		-- When the user tries to access the finding 
		v_has_permission := csr.audit_pkg.HasFlowAuditNonComplTagAccess(
			in_non_compliance_id	=>  v_finding_id,
			in_audit_sid			=> v_audit_sid,
			in_access				=> SECURITY.SECURITY_PKG.PERMISSION_READ
		);

		EXCEPTION
			WHEN SECURITY.security_pkg.ACCESS_DENIED THEN
				v_has_permission := FALSE;
	END;

	-- Then the user can access the finding
	AssertAccessAllowed(v_user_sid,  v_finding_id, v_has_permission);
END;

------------------------------------
-- HELPER SPROCS
------------------------------------

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin;

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
END;


PROCEDURE CreateWorkflow
AS
BEGIN
	csr.unit_test_pkg.GetOrCreateWorkflow(
		in_label				=> 'Audit workflow for finding permission database tests',
		in_flow_alert_class		=> 'audit',
		out_sid					=> v_workflow_sid);

	csr.unit_test_pkg.GetOrCreateWorkflowState(
		in_flow_sid				=> v_workflow_sid,
		in_state_label			=> 'Default state',
		in_state_lookup_key		=> 'DEFAULT',
		out_flow_state_id		=> v_flow_state_id);
END;

PROCEDURE AddAuditType(
	in_label	IN	csr.internal_audit_type.label%TYPE
)
AS
	v_empty_sids	security.security_pkg.T_SID_IDS;
	v_type_sids		security.security_pkg.T_SID_IDS;
	v_out_cur		SYS_REFCURSOR;
BEGIN
	csr.audit_pkg.SaveInternalAuditType(
		in_internal_audit_type_id		=> null,
		in_label						=> in_label,
		in_every_n_months				=> null,
		in_auditor_role_sid				=> null,
		in_audit_contact_role_sid		=> null,
		in_default_survey_sid			=> null,
		in_default_auditor_org			=> null,
		in_override_issue_dtm			=> 0,
		in_assign_issues_to_role		=> 0,
		in_involve_auditor_in_issues	=> 0,
		in_auditor_can_take_ownership	=> 0,
		in_add_nc_per_question			=> 0,
		in_nc_audit_child_region		=> 0,
		in_flow_sid						=> v_workflow_sid,
		in_internal_audit_source_id		=> 1,
		in_summary_survey_sid			=> null,
		in_send_auditor_expiry_alerts	=> 0,
		in_expiry_alert_roles			=> v_empty_sids,
		in_validity_months				=> null,
		in_audit_c_role_or_group_sid	=> null,
		in_tab_sid						=> null,
		in_form_path					=> null,
		in_form_sid						=> null,
		in_ia_type_group_id				=> null,
		in_nc_score_type_id				=> null,
		in_active						=> 1,
		in_show_primary_survey_in_hdr	=> 0,
		in_use_legacy_closed_def		=> 0,
		out_cur							=> v_out_cur);
END;

------------------------------------
-- SETUP and TEARDOWN
------------------------------------

PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
	act_id	security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	act_id := security_pkg.getact;

	DELETE FROM csr.audit_non_compliance WHERE app_sid = v_app_sid;
	DELETE FROM csr.non_compliance WHERE app_sid = v_app_sid;

	FOR r IN (
		SELECT non_compliance_type_id
		  FROM csr.non_compliance_type
		 WHERE app_sid = v_app_sid
	) LOOP
		csr.audit_pkg.DeleteNonComplianceType(r.non_compliance_type_id);
	END LOOP;

	FOR r IN (
		SELECT internal_audit_sid
		  FROM csr.internal_audit
		 WHERE app_sid = v_app_sid
	) LOOP
		security.securableobject_pkg.deleteso(act_id, r.internal_audit_sid);
	END LOOP;

	IF v_user_sids.COUNT > 0 THEN
		FOR i IN v_user_sids.FIRST..v_user_sids.LAST LOOP
			IF (v_user_sids(i)) IS NOT NULL THEN
				security.securableobject_pkg.deleteso(act_id, v_user_sids(i));
				v_user_sids(i) := NULL;
			END IF;
		END LOOP;
	END IF;

	FOR r IN (
		SELECT role_sid
		  FROM csr.role
		 WHERE app_sid = v_app_sid
	) LOOP
		security.securableobject_pkg.deleteso(act_id, r.role_sid);
	END LOOP;

	security.securableobject_pkg.deleteso(act_id, v_region_sid);

	COMMIT;
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
BEGIN
	CreateSite;

	security.user_pkg.LogonAdmin(v_site_name);

	csr.unit_test_pkg.EnableAudits;
	csr.enable_pkg.EnableWorkflow;

	CreateWorkflow;
	v_audit_type_name := 'AUDIT TYPE 1';
	AddAuditType(v_audit_type_name);
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;

END;
/
