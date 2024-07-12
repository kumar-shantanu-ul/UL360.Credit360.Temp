-- Please update version.sql too -- this keeps clean builds in sync
define version=2405
@update_header

grant select, insert, update on chain.group_capability to csrimp;
grant select, insert, update on chain.group_capability to CSR;

@../schema_pkg
@../schema_body

@update_tail
