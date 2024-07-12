-- Please update version.sql too -- this keeps clean builds in sync
define version=403
@update_header

alter table customer add calc_sum_zero_fill number(1) default 1 not null;
alter table customer add constraint ck_customer_calc_sum_0_fill check (calc_sum_zero_fill in (0,1));
alter table customer modify calc_sum_zero_fill default 0;

@../csr_app_body
@../schema_body

@update_tail
