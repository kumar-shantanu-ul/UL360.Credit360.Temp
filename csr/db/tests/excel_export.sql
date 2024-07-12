set serveroutput on
set echo off

@@test_excel_export_pkg
@@test_excel_export_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_excel_export_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_excel_export_pkg;

set echo on
