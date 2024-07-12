set serveroutput on
set echo off


@@test_landing_page_pkg
@@test_landing_page_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_landing_page_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_landing_page_pkg;

set echo on

