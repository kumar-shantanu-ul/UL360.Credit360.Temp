set serveroutput on
set echo off

@@test_user_cover_pkg
@@test_user_cover_body
@@test_cms_user_cover_pkg
@@test_cms_user_cover_body

-- grant access to csr so that unit_test_pkg can call it
grant execute on cms.test_cms_user_cover_pkg to csr;

exec security.user_pkg.logonadmin(:bv_site_name);
@@create_rag_user

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_user_cover_pkg', :bv_site_name);
	
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('cms.test_cms_user_cover_pkg', :bv_site_name);
	
	-- Alternatively can run a sub-set of tests (or with nicer capitalisations)
	/*csr.unit_test_pkg.RunTests('csr.test_user_cover_pkg', csr.unit_test_pkg.T_TESTS(
		'SimpleDelegationCover'
	), :bv_site_name);*/
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_user_cover_pkg;
DROP PACKAGE cms.test_cms_user_cover_pkg;

set echo on
