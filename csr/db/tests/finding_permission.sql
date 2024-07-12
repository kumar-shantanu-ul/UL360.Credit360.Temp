set serveroutput on
set echo off

@@test_finding_permission_pkg
@@test_finding_permission_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_finding_permission_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_finding_permission_pkg;

set echo on
