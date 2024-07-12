set serveroutput on
set echo off

@@test_target_profile_pkg
@@test_target_profile_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_target_profile_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_target_profile_pkg;

set echo on

