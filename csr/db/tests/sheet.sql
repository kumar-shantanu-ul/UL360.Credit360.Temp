SET serveroutput ON
SET echo OFF

@@test_sheet_pkg
@@test_sheet_body

BEGIN				
	csr.unit_test_pkg.RunTests('csr.test_sheet_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_sheet_pkg;

SET echo ON
