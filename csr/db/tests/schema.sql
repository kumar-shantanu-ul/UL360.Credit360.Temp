SET serveroutput ON
SET echo OFF

@@test_schema_pkg
@@test_schema_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_schema_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_schema_pkg;

SET echo ON
