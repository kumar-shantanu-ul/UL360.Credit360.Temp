set serveroutput on
set echo off

grant execute on chain.test_chain_utils_pkg to csr;
grant execute on chain.product_type_pkg to csr;
grant all on chain.product_type_tr to csr;
grant select on chain.v$product_type to csr;

@@test_product_type_pkg
@@test_product_type_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_product_type_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_product_type_pkg;

set echo on

