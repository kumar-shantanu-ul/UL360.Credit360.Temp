set serveroutput on
set echo off

--GRANT EXECUTE ON csr.meter_patch_pkg TO csr;

@@test_meter_pkg
@@test_meter_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_meter_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_meter_pkg;

set echo on
