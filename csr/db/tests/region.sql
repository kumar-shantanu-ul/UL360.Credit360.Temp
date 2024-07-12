set serveroutput on
set echo off

@@test_region_pkg
@@test_region_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_region_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_region_pkg;

set echo on
