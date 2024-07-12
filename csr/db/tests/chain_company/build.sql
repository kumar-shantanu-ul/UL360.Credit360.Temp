SET DEFINE OFF

@@test_company_creation_pkg
@@test_company_creation_body
@@test_company_sync_roles_pkg
@@test_company_sync_roles_body
@@test_company_user_pkg
@@test_company_user_body

GRANT EXECUTE ON chain.test_company_creation_pkg TO csr;
GRANT EXECUTE ON chain.test_company_sync_roles_pkg TO csr;
GRANT EXECUTE ON chain.test_company_user_pkg TO csr;

SET DEFINE ON