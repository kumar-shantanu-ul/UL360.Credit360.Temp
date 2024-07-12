set serveroutput on
set echo off

@@test_int_api_tags_pkg
@@test_int_api_tags_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_int_api_tags_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_int_api_tags_pkg;

set echo on

