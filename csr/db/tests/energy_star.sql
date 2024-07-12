set serveroutput on
set echo off

GRANT EXECUTE ON csr.energy_star_pkg TO csr;

@@test_common_pkg
@@test_energy_star_pkg

@@test_common_body
@@test_energy_star_body

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	csr.enable_pkg.EnableAutomatedExportImport;

	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_energy_star_pkg', :bv_site_name);
END;
/
show ERROR;
-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_energy_star_pkg;

set echo on
