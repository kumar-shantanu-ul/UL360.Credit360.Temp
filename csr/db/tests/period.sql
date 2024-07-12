set serveroutput on
set echo off

@@test_period_pkg
@@test_period_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_period_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_period_pkg;

set echo on
