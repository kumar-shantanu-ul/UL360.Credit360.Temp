set serveroutput on
set echo off

@@test_scheduled_import_pkg
@@test_scheduled_import_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_scheduled_import_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_scheduled_import_pkg;

set echo on

