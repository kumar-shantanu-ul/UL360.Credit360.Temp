set serveroutput on
set echo off

@@test_issue_test_pkg
@@test_issue_test_body
@@test_issue_co_involve_upd_pkg
@@test_issue_co_involve_upd_body
@@test_issue_custom_field_pkg
@@test_issue_custom_field_body

BEGIN
	csr.unit_test_pkg.RunTests('test_issue_test_pkg', :bv_site_name);
	csr.unit_test_pkg.RunTests('test_issue_co_involve_upd_pkg', :bv_site_name);
	csr.unit_test_pkg.RunTests('test_issue_custom_field_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_issue_test_pkg;
DROP PACKAGE csr.test_issue_co_involve_upd_pkg;
DROP PACKAGE csr.test_issue_custom_field_pkg;

set echo on
