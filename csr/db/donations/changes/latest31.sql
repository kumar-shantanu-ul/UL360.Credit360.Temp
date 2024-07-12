-- Please update version.sql too -- this keeps clean builds in sync
define version=31
@update_header

alter table budget add compare_field_num number(2);
commit;

@../fields_pkg
@../fields_body
@../budget_pkg
@../budget_body


@update_tail
