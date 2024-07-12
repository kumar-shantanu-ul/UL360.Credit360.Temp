set serveroutput on
set echo off

grant execute on chain.test_chain_utils_pkg to csr;

@@test_portlet_pkg
@@test_portlet_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_portlet_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_portlet_pkg;

set echo on

