-- Please update version.sql too -- this keeps clean builds in sync
define version=1294
@update_header

grant insert on csr.app_lock to csrimp;
grant insert on csr.customer_help_lang to csrimp;
grant select on csr.help_lang to csrimp;

@../schema_body
@../csrimp/imp_body

@update_tail
