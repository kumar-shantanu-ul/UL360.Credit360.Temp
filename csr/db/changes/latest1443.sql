-- Please update version.sql too -- this keeps clean builds in sync
define version=1443
@update_header

alter table csr.customer add dynamic_deleg_plans_batched number(1) default 0 not null;
alter table csr.customer add constraint ck_customer_dyn_deleg_plan check (dynamic_deleg_plans_batched in (0,1));

@../deleg_plan_body

@update_tail
