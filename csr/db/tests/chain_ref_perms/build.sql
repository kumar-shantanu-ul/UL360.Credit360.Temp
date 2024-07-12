SET DEFINE OFF

@@chain_ref_perms\test_ref_perms_pkg
@@chain_ref_perms\test_ref_perms_body

GRANT EXECUTE ON chain.test_ref_perms_pkg TO csr;

SET DEFINE ON
