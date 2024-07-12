set serveroutput on
set echo off

@@test_baseline_pkg
@@test_baseline_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_baseline_pkg', :bv_site_name);
END;
/

show ERROR;

DROP PACKAGE csr.test_baseline_pkg;

set echo on