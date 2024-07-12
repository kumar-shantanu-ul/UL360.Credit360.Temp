set serveroutput on
set echo off

@@test_customer_pkg
@@test_customer_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_customer_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_customer_pkg;

set echo on

