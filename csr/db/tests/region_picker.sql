set serveroutput on
set echo off

@@test_region_picker_pkg
@@test_region_picker_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_region_picker_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_region_picker_pkg;

set echo on

