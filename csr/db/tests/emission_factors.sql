set serveroutput on
set echo off

--GRANT EXECUTE ON csr.factor_pkg TO csr;

@@test_emission_factors_pkg
@@test_emission_factors_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_emission_factors_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_emission_factors_pkg;

set echo on
