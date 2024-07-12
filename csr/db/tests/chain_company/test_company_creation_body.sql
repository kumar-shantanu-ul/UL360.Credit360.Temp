CREATE OR REPLACE PACKAGE BODY chain.test_company_creation_pkg AS

v_site_name					VARCHAR2(50) := 'company-creation-test.credit360.com';
v_top_company_sid			NUMBER;
v_vendor_ct_id				NUMBER;
v_site_ct_id				NUMBER;

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
	csr.unit_test_pkg.EnableChain;
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

	v_top_company_sid := chain.helper_pkg.getTopCompanySid;
	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_site_ct_id := company_type_pkg.GetCompanyTypeId('SITE');
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

PROCEDURE ConfirmSig (
	in_company_sid			security.security_pkg.T_SID_ID,
	in_expected_sig			VARCHAR2	-- Expects signature as 'part:1|part:2|part:n|'
)
AS
	v_company_name			VARCHAR2(255);
	v_company_region		security.security_pkg.T_SID_ID;
	v_company_sig			VARCHAR2(255);
BEGIN

	SELECT region_sid
	  INTO v_company_region
	  FROM v$company
	 WHERE company_sid = in_company_sid;

	SELECT name
	  INTO v_company_name
	  FROM company
	 WHERE company_sid = in_company_sid;

	-- Company Signature test

	SELECT signature
	  INTO v_company_sig
	  FROM company
	 WHERE company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(LOWER(in_expected_sig || 'na:' || v_company_name), LOWER(v_company_sig), 'Company signature not as expected');

END;

PROCEDURE ConfirmRegionPath (
	in_company_sid			security.security_pkg.T_SID_ID,
	in_expected_region_path	VARCHAR2	-- Expects region path as '/part_1/part_2/part_n/'
)
AS
	v_company_name			VARCHAR2(255);
	v_company_region		security.security_pkg.T_SID_ID;
BEGIN

	SELECT region_sid
	  INTO v_company_region
	  FROM v$company
	 WHERE company_sid = in_company_sid;

	SELECT name
	  INTO v_company_name
	  FROM company
	 WHERE company_sid = in_company_sid;

	-- Region tree test
	csr.unit_test_pkg.AssertAreEqual('/regions/Suppliers' || in_expected_region_path || v_company_name || ' (' || in_company_sid || ')',
		csr.region_pkg.GetFlattenedRegionPath(security.security_pkg.getact, v_company_region),
		'Region layout is not as expected.');

END;

PROCEDURE ConfirmSigRegionPath (
	in_company_sid			security.security_pkg.T_SID_ID,
	in_expected_sig			VARCHAR2,	-- Expects signature as 'part:1|part:2|part:n|'
	in_expected_region_path	VARCHAR2	-- Expects region path as '/part_1/part_2/part_n/'
)
AS
	v_company_name			VARCHAR2(255);
	v_company_region		security.security_pkg.T_SID_ID;
	v_company_sig			VARCHAR2(255);
BEGIN
	
	ConfirmSig(
		in_company_sid			=>	in_company_sid,
		in_expected_sig			=>	in_expected_sig
	);

	ConfirmRegionPath(
		in_company_sid			=>	in_company_sid,
		in_expected_region_path	=>	in_expected_region_path
	);

END;

-- Test: Company created with the same name and country
PROCEDURE TestCreateCompany
AS
	v_vendor_1				VARCHAR2(255) := 'Major Vendor Inc';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_sid_1			NUMBER;
	v_vendor_2				VARCHAR2(255) := 'Major Vendor Inc';
	v_vendor_country_2		VARCHAR2(2) := 'de';
	v_vendor_3				VARCHAR2(255) := 'Major Vendor Ltd';
	v_vendor_country_3		VARCHAR2(2) := 'gb';
	v_vendor_4				VARCHAR2(255) := 'M.ajor, Ve-ndor () G/MB\H';
	v_vendor_country_4		VARCHAR2(2) := 'de';
	v_so_name_4				VARCHAR2(255) := 'M ajor Ve ndor G MB H';
	v_expected_sig			VARCHAR2(255) := LOWER('co:de|na:M ajor Ve ndor G MB H');
	v_company_sig			VARCHAR2(255);
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
BEGIN
	-- create company 1 of type vendor
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> v_vendor_1,
		in_country_code			=> v_vendor_country_1,
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_1
	);
	company_pkg.ActivateCompany(v_vendor_sid_1);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_1
	   AND country_code = v_vendor_country_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	-- create company 2 of type vendor (same name as vendor 1 and different country)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> v_vendor_2,
		in_country_code			=> v_vendor_country_2,
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_2
	   AND country_code = v_vendor_country_2;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	-- create company 3 of type vendor (different name and country same as vendor 1)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> v_vendor_3,
		in_country_code			=> v_vendor_country_3,
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_3
	   AND country_code = v_vendor_country_3;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 matches');

	-- create company 4 of type vendor (with characters in name to be striped off from SO name)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> v_vendor_4,
		in_country_code			=> v_vendor_country_4,
		in_company_type_id		=> v_vendor_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);
	
	v_so_name_4 := v_so_name_4 || ' (' || v_company_sid || ')';
	
	SELECT COUNT(so.sid_id)
	  INTO v_company_count
	  FROM security.securable_object so
	  JOIN company c ON so.sid_id = c.company_sid
	 WHERE c.name = v_vendor_4
	   AND so.name = v_so_name_4;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 matches.');

	SELECT signature
	INTO v_company_sig
	FROM company
	WHERE name = v_vendor_4;

	csr.unit_test_pkg.AssertAreEqual(v_expected_sig, v_company_sig, 'Normalised company sig does not match expected.');

	-- create company 5 of type vendor (same name and country as vendor 3, expect failure)
	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name					=> v_vendor_3,
			in_country_code			=> v_vendor_country_3,
			in_company_type_id		=> v_vendor_ct_id,
			in_sector_id			=> NULL,
			out_company_sid			=> v_company_sid
		);

		v_test_result := 0;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Created company when expected to fail due to uniqueness constraint.');

	-- Delete company 1, then attempt to recreate.
	BEGIN
		company_pkg.DeleteCompany(
			in_company_sid 			=> v_vendor_sid_1
		);
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name					=> v_vendor_1,
			in_country_code			=> v_vendor_country_1,
			in_company_type_id		=> v_vendor_ct_id,
			in_sector_id			=> NULL,
			out_company_sid			=> v_vendor_sid_1
		);
		company_pkg.ActivateCompany(v_vendor_sid_1);
		v_test_result := 1;
	EXCEPTION
		WHEN OTHERS THEN
			v_test_result := 0;
	END;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Unable to recreate company after delete.');

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_1
	   AND country_code = v_vendor_country_1;

	csr.unit_test_pkg.AssertAreEqual(2, v_company_count, 'Expected 2 matches, one active and one deleted');
END;

PROCEDURE TestCreateSubsidiary
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_vendor_1				VARCHAR2(255) := 'Parent Inc';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
	v_vendor_2				VARCHAR2(255) := 'Parent 2 Inc';
	v_vendor_country_2		VARCHAR2(2) := 'gb';
	v_vendor_2_sid			security.security_pkg.T_SID_ID;
	v_subsd_1				VARCHAR2(255) := 'Subsidiary Ltd';
	v_subsd_country_1		VARCHAR2(2) := 'gb';
	v_subsd_2				VARCHAR2(255) := 'Subsidiary Holdings';
	v_subsd_country_2		VARCHAR2(2) := 'gb';
	v_subsd_3				VARCHAR2(255) := 'Subsidiary Ltd';
	v_subsd_country_3		VARCHAR2(2) := 'de';
BEGIN
	-- create parent company 1 of type vendor
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);
	company_pkg.ActivateCompany(v_vendor_1_sid);

	-- create parent company 2 of type vendor
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_2,
		in_country_code				=> v_vendor_country_2,
		in_company_type_id			=> v_vendor_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_2_sid
	);
	company_pkg.ActivateCompany(v_vendor_2_sid);

	-- create subsidiary company 1 of type site and parent vendor 1
	company_pkg.CreateSubCompany(
		in_parent_sid			=> v_vendor_1_sid,
		in_name					=> v_subsd_1,
		in_country_code			=> v_subsd_country_1,
		in_company_type_id		=> v_site_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE parent_sid = v_vendor_1_sid
	   AND name = v_subsd_1
	   AND country_code = v_subsd_country_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	ConfirmSigRegionPath (
		in_company_sid			=>	v_company_sid,
		in_expected_sig			=>	'parent:' || v_vendor_1_sid || '|',
		in_expected_region_path	=>	'/gb/Parent Inc (' || v_vendor_1_sid ||')/'
	);

	-- create subsidiary company 2 (same name and country as subsidiary company 1) of type site and parent vendor 2
	company_pkg.CreateSubCompany(
		in_parent_sid			=> v_vendor_2_sid,
		in_name					=> v_subsd_1,
		in_country_code			=> v_subsd_country_1,
		in_company_type_id		=> v_site_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE parent_sid = v_vendor_2_sid
	   AND name = v_subsd_1
	   AND country_code = v_subsd_country_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	-- create subsidiary company 3 (different name and country from subsidiary company 1) of type site and parent vendor 1
	company_pkg.CreateSubCompany(
		in_parent_sid			=> v_vendor_1_sid,
		in_name					=> v_subsd_2,
		in_country_code			=> v_subsd_country_2,
		in_company_type_id		=> v_site_ct_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_company_sid
	);
	company_pkg.ActivateCompany(v_company_sid);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE parent_sid = v_vendor_1_sid
	   AND name = v_subsd_2
	   AND country_code = v_subsd_country_2;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	-- create subsidiary company 4 (same name and country from subsidiary company 1) of type site and parent vendor 1, expected failure
	BEGIN
		company_pkg.CreateSubCompany(
			in_parent_sid			=> v_vendor_1_sid,
			in_name					=> v_subsd_1,
			in_country_code			=> v_subsd_country_1,
			in_company_type_id		=> v_site_ct_id,
			in_sector_id			=> NULL,
			out_company_sid			=> v_company_sid
		);
		v_test_result := 0;
	EXCEPTION
		WHEN OTHERS THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Created company when expected to fail due to uniqueness constraint.');

	-- create subsidiary company 5 (same name and different country from subsidiary company 1) of type site and parent vendor 1, expected failure
	BEGIN
		company_pkg.CreateSubCompany(
			in_parent_sid			=> v_vendor_1_sid,
			in_name					=> v_subsd_3,
			in_country_code			=> v_subsd_country_3,
			in_company_type_id		=> v_site_ct_id,
			in_sector_id			=> NULL,
			out_company_sid			=> v_company_sid
		);
		v_test_result := 0;
	EXCEPTION
		WHEN OTHERS THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Created company when expected to fail due to uniqueness constraint.');
END;

-- Test for updates
PROCEDURE TestCompanyUpdate
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_vendor_1				VARCHAR2(255) := 'Static Vendor Inc';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
	v_vendor_2				VARCHAR2(255) := 'Alternate Update Vendor Inc';
	v_vendor_country_2		VARCHAR2(2) := 'gb';
	v_vendor_2_sid			security.security_pkg.T_SID_ID;
	v_vendor_3				VARCHAR2(255) := 'Static Vendor Inc';
	v_vendor_country_3		VARCHAR2(2) := 'de';
	v_vendor_3_sid			security.security_pkg.T_SID_ID;
BEGIN	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_2,
		in_country_code				=> v_vendor_country_2,
		in_company_type_id			=> v_vendor_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_2_sid
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_3,
		in_country_code				=> v_vendor_country_3,
		in_company_type_id			=> v_vendor_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_3_sid
	);

	BEGIN
		company_pkg.UpdateCompany(
			in_company_sid				=> v_vendor_2_sid,
			in_name						=> v_vendor_1
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Expected update to fail due to uniqueness error.');

	BEGIN
		company_pkg.UpdateCompany(
			in_company_sid				=> v_vendor_3_sid,
			in_country_code				=> v_vendor_country_2
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Expected update to fail due to uniqueness error.');
END;

-- Test for Region layout city-country create company
PROCEDURE TestCityCountryRegionLayout
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_vendor_1				VARCHAR2(255) := 'Region Layout Inc';
	v_vendor_alt			VARCHAR2(255) := 'Alt Name Layout Inc';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_country_alt	VARCHAR2(2) := 'de';
	v_vendor_city_1			VARCHAR2(255) := 'Cambridge';
	v_vendor_city_alt		VARCHAR2(255) := 'Lower Tadley';
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
BEGIN
	-- Alter the region layout.
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'VENDOR',
		in_default_region_layout	=> '{COUNTRY}/{CITY}/{COMPANY_TYPE}'
	);
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'SITE',
		in_default_region_layout	=> '{COUNTRY}/{CITY}/{COMPANY_TYPE}'
	);

	-- Test incomplete company creation (missing city)
	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_1,
			in_country_code				=> v_vendor_country_1,
			in_company_type_id			=> v_vendor_ct_id,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 1;
	EXCEPTION
		WHEN OTHERS THEN
			v_test_result := 0;
	END;

	ConfirmSigRegionPath (
		in_company_sid			=>	v_vendor_1_sid,
		in_expected_sig			=>	'co:gb|ct:' || v_vendor_ct_id || '|',
		in_expected_region_path	=>	'/gb/VENDOR/'
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_city						=> v_vendor_city_1,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_1
	   AND city = v_vendor_city_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	ConfirmSigRegionPath (
		in_company_sid			=>	v_vendor_1_sid,
		in_expected_sig			=>	'co:gb|ci:Cambridge|ct:' || v_vendor_ct_id || '|',
		in_expected_region_path	=>	'/gb/Cambridge/VENDOR/'
	);

	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_alt,
			in_country_code				=> v_vendor_country_1,
			in_company_type_id			=> v_vendor_ct_id,
			in_city						=> v_vendor_city_1,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 0;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Unexpected duplicate in name test.');

	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_1,
			in_country_code				=> v_vendor_country_alt,
			in_company_type_id			=> v_vendor_ct_id,
			in_city						=> v_vendor_city_1,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 0;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Unexpected duplicate in country test.');

	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_1,
			in_country_code				=> v_vendor_country_1,
			in_company_type_id			=> v_vendor_ct_id,
			in_city						=> v_vendor_city_alt,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 0;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Unexpected duplicate in city test.');

		BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_1,
			in_country_code				=> v_vendor_country_1,
			in_company_type_id			=> v_site_ct_id,
			in_city						=> v_vendor_city_1,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 0;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Unexpected duplicate in company type test.');

	BEGIN
		test_chain_utils_pkg.CreateCompanyHelper(
			in_name						=> v_vendor_1,
			in_country_code				=> v_vendor_country_1,
			in_company_type_id			=> v_vendor_ct_id,
			in_city						=> v_vendor_city_1,
			in_sector_id				=> NULL,
			out_company_sid				=> v_vendor_1_sid
		);
		v_test_result := 0;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_test_result := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(1, v_test_result, 'Expected duplicate company creation to fail.');

END;

-- Test sector, country, state, city, and company type.
PROCEDURE TestAllRegionLayouts
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_sector_1				VARCHAR2(255) := '1';
	v_vendor_1				VARCHAR2(255) := 'Whole Region Layout Inc';
	v_vendor_alt			VARCHAR2(255) := 'Alternate Name Inc';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_country_alt	VARCHAR2(2) := 'de';
	v_vendor_state_1		VARCHAR2(255) := 'Cambridgeshire';
	v_vendor_state_alt		VARCHAR2(255) := 'Hampshire';
	v_vendor_city_1			VARCHAR2(255) := 'Cambridge';
	v_vendor_city_alt		VARCHAR2(255) := 'Basingstoke';
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
BEGIN
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'VENDOR',
		in_default_region_layout	=> '{COMPANY_TYPE}/{COUNTRY}/{STATE}/{CITY}/{SECTOR}'
	);

	helper_pkg.UpdateSector(
		in_sector_id				=> v_sector_1,
		in_description				=> 'Test'
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_city						=> v_vendor_city_1,
		in_state					=> v_vendor_state_1,
		in_sector_id				=> v_sector_1,
		out_company_sid				=> v_vendor_1_sid
	);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM chain.company
	 WHERE name = v_vendor_1
	   AND city = v_vendor_city_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected 1 exact match');

	ConfirmSigRegionPath (
		in_company_sid			=>	v_vendor_1_sid,
		in_expected_sig			=>	'ct:' || v_vendor_ct_id || '|co:gb|st:Cambridgeshire|ci:Cambridge|sct:1|',
		in_expected_region_path	=>	'/VENDOR/gb/Cambridgeshire/Cambridge/Test/'
	);

	company_pkg.UpdateCompany(
		in_company_sid				=> v_vendor_1_sid,
		in_name						=> v_vendor_alt,
		in_country_code				=> v_vendor_country_alt,
		in_city						=> v_vendor_city_alt,
		in_state					=> v_vendor_state_alt
	);

	-- DE9402: Expect the region name to change when company name is changed.  It doesn't currently.
	ConfirmSig(
		in_company_sid			=>	v_vendor_1_sid,
		in_expected_sig			=>	'ct:' || v_vendor_ct_id || '|co:de|st:Hampshire|ci:Basingstoke|sct:1|'
	);
END;

PROCEDURE TestMultipleCTLayouts
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_vendor_1				VARCHAR2(255) := 'Generic Company GMBH';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_state_1		VARCHAR2(255) := 'Cambridgeshire';
	v_vendor_city_1			VARCHAR2(255) := 'Cambridge';
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
BEGIN
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'VENDOR',
		in_default_region_layout	=> '{COMPANY_TYPE}/{COUNTRY}/{STATE}/{CITY}'
	);
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'SITE',
		in_default_region_layout	=> '{COUNTRY}/{CITY}/{COMPANY_TYPE}'
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_city						=> v_vendor_city_1,
		in_state					=> v_vendor_state_1,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_site_ct_id,
		in_city						=> v_vendor_city_1,
		in_state					=> v_vendor_state_1,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM company
	 WHERE name = v_vendor_1;

	csr.unit_test_pkg.AssertAreEqual(2, v_company_count, 'Expected two companies to be made.');
	
END;

PROCEDURE TestParentLayout
AS
	v_company_sid			NUMBER;
	v_company_count			NUMBER;
	v_test_result			NUMBER;
	v_vendor_1				VARCHAR2(255) := 'Vendor';
	v_site_1				VARCHAR2(255) := 'Site';
	v_vendor_country_1		VARCHAR2(2) := 'gb';
	v_vendor_state_1		VARCHAR2(255) := 'Cambridgeshire';
	v_vendor_city_1			VARCHAR2(255) := 'Cambridge';
	v_site_country_1		VARCHAR2(2) := 'de';
	v_parent_company_name	VARCHAR2(255);
	v_vendor_1_sid			security.security_pkg.T_SID_ID;
	v_site_1_sid			security.security_pkg.T_SID_ID;
	v_vendor_region_sid		security.security_pkg.T_SID_ID;
	v_site_region_sid		security.security_pkg.T_SID_ID;
BEGIN
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'VENDOR',
		in_default_region_layout	=> '{SECTOR}'
	);
	test_chain_utils_pkg.UpdateCompanyTypeLayout (
		in_lookup_key				=> 'SITE',
		in_default_region_layout	=> '{PARENT}/{COUNTRY}'
	);

	test_chain_utils_pkg.ToggleCreateSubsUnderParentForCompanyType(
		in_lookup_key => 'SITE',
		in_create_subsids_under_parent => 0
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> v_vendor_1,
		in_country_code				=> v_vendor_country_1,
		in_company_type_id			=> v_vendor_ct_id,
		in_city						=> v_vendor_city_1,
		in_state					=> v_vendor_state_1,
		in_sector_id				=> NULL,
		out_company_sid				=> v_vendor_1_sid
	);

	test_chain_utils_pkg.CreateSubCompanyHelper(
		in_parent_sid 				=> v_vendor_1_sid,
		in_name						=> v_site_1,
		in_country_code				=> v_site_country_1,
		in_company_type_id			=> v_site_ct_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_site_1_sid
	);

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM company
	 WHERE name = v_vendor_1
	   AND company_type_id = v_vendor_ct_id;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected one vendor company to be made.');

	SELECT COUNT(company_sid)
	  INTO v_company_count
	  FROM company
	 WHERE name = v_site_1
	   AND company_type_id = v_site_ct_id;

	csr.unit_test_pkg.AssertAreEqual(1, v_company_count, 'Expected one site company to be made.');

	ConfirmSigRegionPath (
		in_company_sid			=>	v_vendor_1_sid,
		in_expected_sig			=>	'|',
		in_expected_region_path	=>	'/'
	);

	SELECT name
	  INTO v_parent_company_name
	  FROM company
	 WHERE company_sid = v_vendor_1_sid;

	ConfirmSigRegionPath (
		in_company_sid			=>	v_site_1_sid,
		in_expected_sig			=>	'parent:' || v_vendor_1_sid || '|',
		in_expected_region_path	=>	'/' || v_parent_company_name || ' (' || v_vendor_1_sid || ')/de/'
	);

	-- Toggle back create subsids under parent
	test_chain_utils_pkg.ToggleCreateSubsUnderParentForCompanyType(
		in_lookup_key => 'SITE',
		in_create_subsids_under_parent => 1
	);
END;

END;
/