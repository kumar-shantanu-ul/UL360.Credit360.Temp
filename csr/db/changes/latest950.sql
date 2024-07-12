-- Please update version.sql too -- this keeps clean builds in sync
define version=950
@update_header

alter table csr.customer add ind_selections_enabled number(1) default 0 not null;
alter table csr.customer add constraint ck_customer_ind_sel_enabled check (ind_selections_enabled in (0,1));

@../csr_app_body
@../indicator_pkg
@../indicator_body

@update_tail
