-- Please update version.sql too -- this keeps clean builds in sync
define version=765
@update_header

alter table csr.deleg_plan add name_template varchar2(1000);

@..\deleg_plan_body

@update_tail
