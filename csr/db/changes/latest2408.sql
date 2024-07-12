-- Please update version.sql too -- this keeps clean builds in sync
define version=2408
@update_header

grant select, insert, update on chain.card_progression_action to csrimp;
grant select, insert, update on chain.card_progression_action to CSR;

@../schema_pkg
@../schema_body

@update_tail
