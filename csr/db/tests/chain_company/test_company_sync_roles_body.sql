CREATE OR REPLACE PACKAGE BODY chain.test_company_sync_roles_pkg AS

v_site_name			VARCHAR2(50) := 'company-sync-role-test.credit360.com';
v_user_role_sid 	NUMBER;
v_user_sid_1	 	NUMBER;
v_vendor_sid_1 		NUMBER;
v_vendor_sid_2 		NUMBER;
v_vendor_ct_id 		NUMBER;
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
BEGIN
	security.user_pkg.LogonAdmin;
	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);

	security.user_pkg.LogonAdmin(v_site_name);

	-- this also sets up two tier 
	csr.unit_test_pkg.EnableChain;

	-- enable use-user-roles
	test_chain_utils_pkg.EnableRoleForCompanyType('TOP');
	test_chain_utils_pkg.EnableCascadeRoleForCTR('TOP', 'VENDOR');

	SELECT user_role_sid
	  INTO v_user_role_sid 
	  FROM company_type
	 WHERE lookup_key = 'TOP';

	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');

	v_top_company_sid := chain.helper_pkg.GetTopCompanySid;

	v_user_sid_1 := test_chain_utils_pkg.SetupUITest_AddTopCompUser(
		in_user_name	=> 'user1',
		in_email		=> 'user1@cr360.com',
		in_pwd			=> '12345678'
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
		test_chain_utils_pkg.DeleteFullyCompaniesOfType('SITE');
		test_chain_utils_pkg.DeleteFullyCompaniesOfType('VENDOR');
	END IF;
END;

FUNCTION GetRRMCount(
	in_vendor_sid	NUMBER,
	in_role_sid		NUMBER,
	in_user_sid		NUMBER	
) RETURN NUMBER
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_role_member
	 WHERE region_sid = csr.supplier_pkg.GetRegionSid(in_vendor_sid)
	   AND role_sid = in_role_sid
	   AND user_sid = in_user_sid;

	RETURN v_count;
END;

PROCEDURE AssertRRM(
	in_vendor_sid		NUMBER,
	in_user_sid			NUMBER,
	in_role_sid			NUMBER,
	in_expected_count	NUMBER
)
AS
	v_rrm_count	NUMBER;
BEGIN
	v_rrm_count := GetRRMCount(in_vendor_sid, in_role_sid, in_user_sid); 
	csr.unit_test_pkg.AssertAreEqual(in_expected_count, v_rrm_count, 'The number of RRM records isn''t the expected one');
END;

-- tests
PROCEDURE TestCascadeRole
AS
BEGIN
	test_chain_utils_pkg.CreateCompanyNoRelationship(
		in_name					=> 'Vendor 1',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_1
	);

	test_chain_utils_pkg.CreateCompanyNoRelationship(
		in_name					=> 'Vendor 2',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_2
	);

	AssertRRM(v_vendor_sid_1, v_user_sid_1, v_user_role_sid, 0);
	AssertRRM(v_vendor_sid_2, v_user_sid_1, v_user_role_sid, 0);

	-- start relationship with vendor 1
	test_chain_utils_pkg.ConnectWithTopCompany(v_vendor_sid_1);

	-- top company user has been added to RRM for the vendor 1
	AssertRRM(v_vendor_sid_1, v_user_sid_1, v_user_role_sid, 1);

	--...but not the for the vendor 2
	AssertRRM(v_vendor_sid_2, v_user_sid_1, v_user_role_sid, 0);

	-- -- start relationship with vendor 2
	test_chain_utils_pkg.ConnectWithTopCompany(v_vendor_sid_2);

	AssertRRM(v_vendor_sid_1, v_user_sid_1, v_user_role_sid, 1);
	AssertRRM(v_vendor_sid_2, v_user_sid_1, v_user_role_sid, 1);
END;

END;
/