-- Please update version.sql too -- this keeps clean builds in sync
define version=2292
@update_header

alter table csr.form_ind_member rename column flags to show_total;
alter table csr.form_ind_member add constraint ck_form_ind_member_show_total check (show_total in (0,1));

alter table csrimp.form_ind_member rename column flags to show_total;
alter table csrimp.form_ind_member add constraint ck_form_ind_member_show_total check (show_total in (0,1));

alter table csr.customer add reporting_ind_root_sid number(10);
create index csr.ix_customer_rep_ind_root_sid on csr.customer (app_sid, reporting_ind_root_sid);
alter table csr.customer add constraint fk_customer_rep_ind_root_sid foreign key (app_sid, reporting_ind_root_sid) references csr.ind (app_sid, ind_sid);
alter table csrimp.customer add reporting_ind_root_sid number(10);

alter table csr.ind drop constraint ck_ind_type;
alter table csr.ind add constraint ck_ind_type CHECK (IND_TYPE IN (0,1,2,3,4));
alter table csrimp.ind drop constraint ck_ind_type;
alter table csrimp.ind add constraint ck_ind_type CHECK (IND_TYPE IN (0,1,2,3,4));

@../csr_data_pkg
@../calc_pkg
@../indicator_pkg
@../enable_pkg
@../stored_calc_datasource_pkg
@../calc_body
@../csr_app_body
@../csr_data_body
@../enable_body
@../indicator_body
@../form_body
@../schema_body
@../trash_body
@../csrimp/imp_body

@update_tail
