-- Please update version.sql too -- this keeps clean builds in sync
define version=366
@update_header

alter table form add tab_direction number(1) default 0 not null;
alter table form add constraint CK_FORM_TAB_DIRECTION check (TAB_DIRECTION IN (0,1));

@../form_pkg
@../form_body

@update_tail
