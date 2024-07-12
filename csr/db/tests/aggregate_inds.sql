set serveroutput on
set echo off

@@test_aggregate_ind_pkg
@@test_aggregate_ind_body

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	csr.enable_pkg.EnableDataBuckets;
	csr.unit_test_pkg.RunTests('csr.test_aggregate_ind_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_aggregate_ind_pkg;

set echo on
