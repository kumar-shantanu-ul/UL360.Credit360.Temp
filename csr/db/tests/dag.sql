set serveroutput on
set echo off

@@dag_test_pkg
@@dag_test_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.dag_test_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.dag_test_pkg;

set echo on
