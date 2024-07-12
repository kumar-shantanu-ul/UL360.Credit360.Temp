CREATE OR REPLACE PACKAGE BODY chain.test_followers_role_pkg AS

v_site_name			VARCHAR2(50) := 'company-follower-role-test.credit360.com';
v_follower_role_sid	NUMBER;
v_user_sid_1	 	NUMBER;
v_user_sid_2	 	NUMBER;
v_user_sid_3	 	NUMBER;
v_vendor_sid_1 		NUMBER;
v_site_sid_1 		NUMBER;
v_vendor_ct_id 		NUMBER;
v_site_ct_id 		NUMBER;

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
	TearDownFixture;
	security.user_pkg.LogonAdmin;
	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);

	security.user_pkg.LogonAdmin(v_site_name);

	-- this also sets up two tier 
	csr.unit_test_pkg.EnableChain;

	-- enable follower role
	v_follower_role_sid := test_chain_utils_pkg.EnableFollowerRoleForCompTypeRel('VENDOR', 'SITE');

	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_site_ct_id := company_type_pkg.GetCompanyTypeId('SITE');

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
	null;
	-- IF AppExists THEN
	-- 	security.user_pkg.LogonAdmin(v_site_name);
	-- 	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SITE');
	-- 	test_chain_utils_pkg.DeleteFullyCompaniesOfType('VENDOR');
	-- END IF;
END;

FUNCTION GetRRMCount(
	in_site_sid		NUMBER,
	in_role_sid		NUMBER,
	in_user_sid		NUMBER	
) RETURN NUMBER
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_role_member
	 WHERE region_sid = csr.supplier_pkg.GetRegionSid(in_site_sid)
	   AND role_sid = in_role_sid
	   AND user_sid = in_user_sid;

	RETURN v_count;
END;

PROCEDURE AssertRRMRole(
	in_site_sid			NUMBER,
	in_role_sid			NUMBER,
	in_user_sid			NUMBER,
	in_expected_count	NUMBER
)
AS
	v_rrm_count	NUMBER;
BEGIN
	v_rrm_count := GetRRMCount(in_site_sid, in_role_sid, in_user_sid); 
	csr.unit_test_pkg.AssertAreEqual(in_expected_count, v_rrm_count, 'The number of RRM records isn''t the expected one');
END;

PROCEDURE AssertFollower(
	in_vendor_sid		NUMBER,
	in_site_sid			NUMBER,
	in_user_sid			NUMBER,
	in_expected_count	NUMBER
)
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM supplier_follower
	 WHERE purchaser_company_sid = in_vendor_sid
	   AND supplier_company_sid = in_site_sid
	   AND user_sid = in_user_sid;

	csr.unit_test_pkg.AssertAreEqual(in_expected_count, v_count, 'The number of follower records isn''t the expected one');
END;

-- Tests

-- Given a T1 company is connected to a T2 supplier
-- And 2 users of T1 company are following the T2 supplier
-- When the relationship between T1 company and T2 supplier gets deleted
-- Then the follower roles on the T2 supplier for the 2 T1 company users also get removed

PROCEDURE TestRoleGetsDeletedWhenRelaDel
AS
BEGIN
	-- arrange
	test_chain_utils_pkg.CreateCompanyNoRelationship(
		in_name					=> 'Vendor 1',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_1
	);

	test_chain_utils_pkg.CreateCompanyNoRelationship(
		in_name					=> 'Site 1',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_site_sid_1
	);

	v_user_sid_1 := test_chain_utils_pkg.CreateCompanyUser(v_vendor_sid_1, 'usera');
	v_user_sid_2 := test_chain_utils_pkg.CreateCompanyUser(v_vendor_sid_1, 'userb');
	v_user_sid_3 := test_chain_utils_pkg.CreateCompanyUser(v_vendor_sid_1, 'userc');

	test_chain_utils_pkg.ConnectCompanies(v_vendor_sid_1, v_site_sid_1);

	company_pkg.AddSupplierFollower (
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_supplier_company_sid		=> v_site_sid_1,
		in_user_sid					=> v_user_sid_1
	);

	company_pkg.AddSupplierFollower (
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_supplier_company_sid		=> v_site_sid_1,
		in_user_sid					=> v_user_sid_2
	);

	-- make sure the roles are granted only for followers
	AssertRRMRole(
		in_site_sid			 => v_site_sid_1, 
		in_role_sid 		 => v_follower_role_sid,
		in_user_sid 		 => v_user_sid_1,
		in_expected_count	 => 1
	);

	AssertFollower(
		in_vendor_sid		=> v_vendor_sid_1,
		in_site_sid			=> v_site_sid_1,
		in_user_sid			=> v_user_sid_1,
		in_expected_count	=> 1
	);
	
	AssertRRMRole(
		in_site_sid			 => v_site_sid_1, 
		in_role_sid			 => v_follower_role_sid,
		in_user_sid 		 => v_user_sid_2,
		in_expected_count	 => 1
	);

	AssertFollower(
		in_vendor_sid		=> v_vendor_sid_1,
		in_site_sid			=> v_site_sid_1,
		in_user_sid			=> v_user_sid_2,
		in_expected_count	=> 1
	);

	AssertRRMRole(
		in_site_sid			 => v_site_sid_1, 
		in_role_sid			 => v_follower_role_sid,
		in_user_sid 		 => v_user_sid_3,
		in_expected_count	 => 0
	);

	AssertFollower(
		in_vendor_sid		=> v_vendor_sid_1,
		in_site_sid			=> v_site_sid_1,
		in_user_sid			=> v_user_sid_3,
		in_expected_count	=> 0
	);

	-- act
	company_pkg.DeleteRelationship(v_vendor_sid_1, v_site_sid_1);

	-- assert
	AssertRRMRole(
		in_site_sid			 => v_site_sid_1, 
		in_role_sid 		 => v_follower_role_sid,
		in_user_sid 		 => v_user_sid_1,
		in_expected_count	 => 0
	);

	AssertFollower(
		in_vendor_sid		=> v_vendor_sid_1,
		in_site_sid			=> v_site_sid_1,
		in_user_sid			=> v_user_sid_1,
		in_expected_count	=> 0
	);

	AssertRRMRole(
		in_site_sid			 => v_site_sid_1, 
		in_role_sid			 => v_follower_role_sid,
		in_user_sid 		 => v_user_sid_2,
		in_expected_count	 => 0
	);

	AssertFollower(
		in_vendor_sid		=> v_vendor_sid_1,
		in_site_sid			=> v_site_sid_1,
		in_user_sid			=> v_user_sid_2,
		in_expected_count	=> 0
	);
END;

END;
/