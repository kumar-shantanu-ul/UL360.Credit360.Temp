set serveroutput on
set echo off

@@test_automated_import_pkg
@@test_automated_import_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_automated_import_pkg', :bv_site_name);
END;
/

show ERROR;

DROP PACKAGE csr.test_automated_import_pkg;

set echo on