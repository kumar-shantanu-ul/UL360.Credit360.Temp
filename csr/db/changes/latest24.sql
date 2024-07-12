-- Please update version.sql too -- this keeps clean builds in sync
define version=24
@update_header

alter table sheet add (is_visible number(10) default 1 not null);

@update_tail
