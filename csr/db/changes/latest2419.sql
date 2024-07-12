-- Please update version.sql too -- this keeps clean builds in sync
define version=2419
@update_header

grant select on chain.card_id_seq to csrimp;
grant select on chain.card_id_seq to CSR;

@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail