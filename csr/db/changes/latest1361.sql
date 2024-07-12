-- Please update version.sql too -- this keeps clean builds in sync
define version=1361
@update_header 

GRANT SELECT ON security.password_regexp TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acc_policy_pwd_regexp TO csr;

@../csr_data_body;

@update_tail
