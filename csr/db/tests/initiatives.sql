set serveroutput on
set echo off

@@test_initiatives_pkg
@@test_initiatives_body

BEGIN
	csr.unit_test_pkg.RunTests('test_initiatives_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_initiatives_pkg;

set echo on