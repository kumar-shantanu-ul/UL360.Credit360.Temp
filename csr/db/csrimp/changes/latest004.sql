-- Please update version.sql too -- this keeps clean builds in sync
define version=4
@update_header

alter table imp_val modify val null;

@update_tail
