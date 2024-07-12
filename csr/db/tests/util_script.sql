set serveroutput on
set echo off

@@test_util_script_pkg
@@test_util_script_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_util_script_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_util_script_pkg;

@@test_util_script_2_pkg
@@test_util_script_2_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_util_script_2_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_util_script_2_pkg;

set echo on
