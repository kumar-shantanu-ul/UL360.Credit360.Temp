set serveroutput on
set echo off


@@test_credential_management_pkg
@@test_credential_management_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_credential_management_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_credential_management_pkg;

set echo on

