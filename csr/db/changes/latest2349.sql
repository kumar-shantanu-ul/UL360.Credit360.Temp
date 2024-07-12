-- Please update version.sql too -- this keeps clean builds in sync
define version=2349
@update_header

alter table csr.temp_val_id modify val_id number(20);
alter table csr.imp_val modify set_val_id number(20);
alter table csr.val_file modify val_id number(20);
alter table csr.val_accuracy modify val_id number(20);

@update_tail
