set serveroutput on
set echo off

@@test_common_pkg
@@test_region_certificate_pkg

@@test_common_body
@@test_region_certificate_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_region_certificate_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_region_certificate_pkg;
DROP PACKAGE csr.test_common_pkg;

set echo on
