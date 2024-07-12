SET serveroutput ON
SET echo OFF

@@test_delegation_pkg
@@test_delegation_body

BEGIN				
	csr.unit_test_pkg.RunTests('csr.test_delegation_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_delegation_pkg;

SET echo ON
