-- Please update version.sql too -- this keeps clean builds in sync
define version=2362
@update_header

alter table csrimp.temp_imp_set_val modify imp_val_id number(20);
alter table csrimp.temp_imp_set_val modify set_val_id number(20);

@update_tail
