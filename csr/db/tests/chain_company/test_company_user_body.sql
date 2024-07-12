CREATE OR REPLACE PACKAGE BODY chain.test_company_user_pkg AS

v_site_name			VARCHAR2(50) := 'company-role-test.credit360.com';
v_role_sid 			NUMBER;
v_user_sid_1	 	NUMBER;
v_user_sid_2	 	NUMBER;
v_top_company_sid	NUMBER;

FUNCTION AppExists
RETURN BOOLEAN
IS
	out_app_exists			NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;

	SELECT COUNT(host)
	  INTO out_app_exists
	  FROM csr.customer
	 WHERE host = v_site_name;

	RETURN out_app_exists != 0;
END;

PROCEDURE SetUpFixture
AS
	v_app_sid				security.security_pkg.T_SID_ID;
	v_region_sid			security.security_pkg.T_SID_ID;
	v_cur					SYS_REFCURSOR;
BEGIN
	security.user_pkg.LogonAdmin;
	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);

	security.user_pkg.LogonAdmin(v_site_name);

	-- this also sets up two tier 
	csr.unit_test_pkg.EnableChain;

	v_top_company_sid := chain.helper_pkg.GetTopCompanySid;

	v_user_sid_1 := test_chain_utils_pkg.SetupUITest_AddTopCompUser(
		in_user_name	=> 'user1',
		in_email		=> 'user1@cr360.com',
		in_pwd			=> '12345678'
	);
	
	v_user_sid_2 := test_chain_utils_pkg.SetupUITest_AddTopCompUser(
		in_user_name	=> 'user2',
		in_email		=> 'user2@cr360.com',
		in_pwd			=> '12345678'
	);
	
	COMMIT; -- Logging on uses it's own transaction so need to commit users before logon
	
	company_type_pkg.SetCompanyTypeRole (
		in_company_type_id		=> company_type_pkg.GetCompanyTypeId('TOP'),
		in_role_name			=> 'Promote role',
		in_mandatory			=> 0,
		in_cascade_to_supplier	=> 0,
		out_cur					=> v_cur
	);
	
	SELECT role_sid
	  INTO v_role_sid
	  FROM csr.role
	 WHERE name = 'Promote role';
	
	SELECT region_sid
	  INTO v_region_sid
	  FROM v$company
	 WHERE company_sid = v_top_company_sid;
	
	csr.role_pkg.AddRoleMemberForRegion(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_role_sid						=> v_role_sid,
		in_user_sid						=> v_user_sid_1,
		in_region_sid					=> v_region_sid,
		in_force_alter_system_managed 	=> 1
	);
	
	chain.type_capability_pkg.SetPermissionToRole (
		in_primary_company_type		=> 'TOP',
		in_capability				=> chain_pkg.PROMOTE_USER,
		in_role_name				=> 'Promote role'
	);
	
END;

PROCEDURE TearDownFixture
AS
	v_app_exists			NUMBER;
BEGIN
	IF AppExists THEN
		security.user_pkg.LogonAdmin(v_site_name);

		test_chain_utils_pkg.TearDownTwoTier;
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	END IF;
END;

PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TearDown
AS
BEGIN
	IF AppExists THEN
		security.user_pkg.LogonAdmin(v_site_name);
	END IF;
END;

-- tests
PROCEDURE TestUserWithPromoteUserCanAddRoles
AS
	v_roles						helper_pkg.T_NUMBER_ARRAY;
	v_user_act_id		security.security_pkg.T_ACT_ID;
BEGIN
	v_roles(1) := v_role_sid;
	
	security.user_pkg.LogonAuthenticated(v_user_sid_1, 60, v_user_act_id);
	
	company_pkg.SetCompany(v_top_company_sid);
	
	company_user_pkg.SetCompanyTypeRoles(
		in_company_sid					=> v_top_company_sid,
		in_user_sid						=> v_user_sid_2,
		in_role_sids					=> v_roles
	);	
END;

PROCEDURE TestUserWithPromoteUserCanRemoveRoles
AS
	v_roles						helper_pkg.T_NUMBER_ARRAY;
	v_user_act_id				security.security_pkg.T_ACT_ID;
BEGIN
	TestUserWithPromoteUserCanAddRoles;
	
	security.user_pkg.LogonAuthenticated(v_user_sid_1, 60, v_user_act_id);
	
	company_pkg.SetCompany(v_top_company_sid);
	
	company_user_pkg.SetCompanyTypeRoles(
		in_company_sid					=> v_top_company_sid,
		in_user_sid						=> v_user_sid_2,
		in_role_sids					=> v_roles
	);	
END;

PROCEDURE TestUserWithoutPromoteUserCannotAddRoles
AS
	v_roles						helper_pkg.T_NUMBER_ARRAY;
	v_user_act_id		security.security_pkg.T_ACT_ID;
BEGIN
	v_roles(1) := v_role_sid;
	
	security.user_pkg.LogonAuthenticated(v_user_sid_2, 60, v_user_act_id);
	
	company_pkg.SetCompany(v_top_company_sid);
	
	BEGIN
		company_user_pkg.SetCompanyTypeRoles(
			in_company_sid					=> v_top_company_sid,
			in_user_sid						=> v_user_sid_2,
			in_role_sids					=> v_roles
		);
	EXCEPTION
		WHEN OTHERS THEN
			csr.unit_test_pkg.AssertAreEqual(security.security_pkg.ERR_ACCESS_DENIED, SQLCODE, 'Didn''t throw access denied');
	END;	
END;

PROCEDURE TestUserWithoutPromoteUserCannotRemoveRoles
AS
	v_roles						helper_pkg.T_NUMBER_ARRAY;
	v_user_act_id				security.security_pkg.T_ACT_ID;
BEGIN
	TestUserWithPromoteUserCanAddRoles;
	
	security.user_pkg.LogonAuthenticated(v_user_sid_2, 60, v_user_act_id);
	
	company_pkg.SetCompany(v_top_company_sid);
	
	BEGIN
		company_user_pkg.SetCompanyTypeRoles(
			in_company_sid					=> v_top_company_sid,
			in_user_sid						=> v_user_sid_2,
			in_role_sids					=> v_roles
		);
	EXCEPTION
		WHEN OTHERS THEN
			csr.unit_test_pkg.AssertAreEqual(security.security_pkg.ERR_ACCESS_DENIED, SQLCODE, 'Didn''t throw access denied');
	END;
END;

PROCEDURE TestAdminCanAddRoles
AS
BEGIN
	company_user_pkg.AddCompanyTypeRoleToUser(
		in_company_sid					=> v_top_company_sid,
		in_user_sid						=> v_user_sid_2,
		in_role_sid						=> v_role_sid	
	);	
END;

PROCEDURE TestAdminCanRemoveRoles
AS
BEGIN
	TestAdminCanAddRoles;
	
	company_user_pkg.RemoveCompanyTypeRoleFromUser(
		in_company_sid					=> v_top_company_sid,
		in_user_sid						=> v_user_sid_2,
		in_role_sid						=> v_role_sid	
	);	
END;

END;
/
