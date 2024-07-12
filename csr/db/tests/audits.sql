set serveroutput on
set echo off

@@test_audit_report_pkg
@@test_audit_report_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_audit_report_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_audit_report_pkg;

@@disable_pkg
@@test_audit_pkg
@@disable_body
@@test_audit_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_audit_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_audit_pkg;
DROP PACKAGE csr.disable_pkg;

set echo on
