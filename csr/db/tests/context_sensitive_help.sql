set serveroutput on
set echo off


@@test_context_sensitive_help_pkg
@@test_context_sensitive_help_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_context_sensitive_help_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_context_sensitive_help_pkg;

set echo on

