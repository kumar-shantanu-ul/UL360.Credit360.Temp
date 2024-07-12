SET serveroutput ON
SET echo OFF

@@test_scenario_pkg
@@test_scenario_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_scenario_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_scenario_pkg;

SET echo ON
