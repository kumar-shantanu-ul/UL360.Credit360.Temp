-- Please update version.sql too -- this keeps clean builds in sync
define version=2348
@update_header

alter table csr.val modify val_id number(20);

@update_tail
