SET DEFINE OFF

@@test_followers_role_pkg
@@test_followers_role_body

GRANT EXECUTE ON chain.test_followers_role_pkg TO csr;

SET DEFINE ON