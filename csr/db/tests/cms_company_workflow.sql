SET SERVEROUTPUT ON
SET ECHO OFF
SET DEFINE OFF

GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;

@@test_company_cms_role_pkg
@@test_company_cms_role_body

SET DEFINE ON

@@create_rag_user

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	
	--we need to tear down everything in case the previous execution failed
	csr.test_company_cms_role_pkg.TearDown;
END;
/

@@create_company_workflow_staging

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	csr.enable_pkg.enablePortal;
END;
/

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('csr.test_company_cms_role_pkg', csr.unit_test_pkg.T_TESTS(
		'TestCompanyUserRoleAccess'), :bv_site_name);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_company_cms_role_pkg;

SET ECHO ON