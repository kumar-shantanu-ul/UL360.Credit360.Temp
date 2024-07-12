-- Please update version.sql too -- this keeps clean builds in sync
define version=49
@update_header

alter table custom_field modify field_num NUMBER(3);
alter table scheme_field modify field_num number(3);
alter table custom_field_dependency modify field_num number(3);
alter table custom_field_dependency modify dependent_field_num number(3);

@update_tail
