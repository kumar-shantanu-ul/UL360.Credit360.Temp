-- Please update version.sql too -- this keeps clean builds in sync
define version=2354
@update_header

alter table csrimp.val modify val_id number(20);
alter table csrimp.val modify source_id number(20);
alter table csrimp.imp_val modify set_val_id number(20);

@update_tail