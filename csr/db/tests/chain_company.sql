SET SERVEROUTPUT ON
SET ECHO OFF

@@chain_company\build

BEGIN
	chain.test_company_creation_pkg.TearDown;
	chain.test_company_creation_pkg.TearDownFixture;
	chain.test_company_sync_roles_pkg.TearDown;
	chain.test_company_sync_roles_pkg.TearDownFixture;
	chain.test_company_user_pkg.TearDown;
	chain.test_company_user_pkg.TearDownFixture;
	COMMIT;
END;
/

BEGIN
 	-- Run tests in package	
 	csr.unit_test_pkg.RunTests(
		in_pkg					=> 'chain.test_company_creation_pkg',
		in_tests				=> csr.unit_test_pkg.T_TESTS(
									'TestCreateCompany', 'TestCreateSubsidiary', 'TestCompanyUpdate', 'TestCityCountryRegionLayout', 'TestAllRegionLayouts', 'TestMultipleCTLayouts', 'TestParentLayout'
								),
		in_site_name			=> :bv_site_name
 	);

	csr.unit_test_pkg.RunTests(
		in_pkg					=> 'chain.test_company_sync_roles_pkg',
		in_tests				=> csr.unit_test_pkg.T_TESTS('TestCascadeRole'),
		in_site_name			=> :bv_site_name
 	);
	
	csr.unit_test_pkg.RunTests('chain.test_company_user_pkg', :bv_site_name);	
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_company_creation_pkg;
DROP PACKAGE chain.test_company_sync_roles_pkg;
DROP PACKAGE chain.test_company_user_pkg;

SET ECHO ON
