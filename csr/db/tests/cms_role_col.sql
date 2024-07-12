set serveroutput on
set echo off

@@test_cms_role_col_pkg
@@test_cms_role_col_body

-- grant access to csr so that unit_test_pkg can call it
grant execute on cms.test_cms_role_col_pkg to csr;

@@create_rag_user

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('cms.test_cms_role_col_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE cms.test_cms_role_col_pkg;

set echo on
