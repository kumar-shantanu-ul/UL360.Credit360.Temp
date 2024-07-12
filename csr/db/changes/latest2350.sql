-- Please update version.sql too -- this keeps clean builds in sync
define version=2350
@update_header

alter table csr.get_value_result modify source_id number(20);
alter table csr.val modify source_id number(20);

@update_tail
