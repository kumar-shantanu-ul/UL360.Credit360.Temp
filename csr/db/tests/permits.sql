set serveroutput on
set echo off

@@test_permits_pkg
@@test_permits_body

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	csr.unit_test_pkg.RunTests('csr.test_permits_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_permits_pkg;

set echo on
