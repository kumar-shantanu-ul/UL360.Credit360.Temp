-- Please update version.sql too -- this keeps clean builds in sync
define version=2420
@update_header

grant select, insert, update on chain.card to csrimp;
grant select, insert, update on chain.card to CSR;

@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail