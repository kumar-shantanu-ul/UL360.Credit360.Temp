-- Please update version.sql too -- this keeps clean builds in sync
define version=200
@update_header

alter table val drop column base;

@update_tail
