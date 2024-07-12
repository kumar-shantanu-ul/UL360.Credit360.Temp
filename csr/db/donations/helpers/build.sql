set define off

PROMPT Compiling bae_helper package
@@bae_helper_pkg
@@bae_helper_body

PROMPT Compiling aviva_helper package
@@aviva_helper_pkg
@@aviva_helper_body

set define &

GRANT EXECUTE ON bae_helper_pkg TO csr,web_user;
GRANT EXECUTE ON aviva_helper_pkg TO csr,web_user;

