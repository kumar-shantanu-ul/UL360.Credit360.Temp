set serveroutput on
set echo off

@@test_tag_pkg
@@test_tag_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_tag_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_tag_pkg;

set echo on
