-- Please update version.sql too -- this keeps clean builds in sync
define version=1077
@update_header

GRANT execute ON security.accountpolicyhelper_pkg TO web_user;

@../../../security/db/oracle/accountpolicyhelper_body

@update_tail
