set serveroutput on
set echo off

--GRANT EXECUTE ON csr.meter_monitor_pkg TO csr;

@@test_meter_monitor_pkg
@@test_meter_monitor_body

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	csr.enable_pkg.EnableAutomatedExportImport;

	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_meter_monitor_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_meter_monitor_pkg;

set echo on
