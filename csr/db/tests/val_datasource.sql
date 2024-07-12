set serveroutput on
set echo off

@@test_val_datasource_pkg
@@test_val_datasource_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_val_datasource_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_val_datasource_pkg;

set echo on

