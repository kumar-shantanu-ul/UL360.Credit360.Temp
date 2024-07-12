set serveroutput on
set echo off

--GRANT EXECUTE ON csr.region_tree_pkg TO csr;

@@test_region_tree_pkg
@@test_region_tree_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_region_tree_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_region_tree_pkg;

set echo on
