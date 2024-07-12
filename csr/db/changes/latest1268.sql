-- Please update version.sql too -- this keeps clean builds in sync
define version=1268
@update_header

grant insert,select,update,delete on csrimp.dataview_region_description to web_user;
grant insert,select,update,delete on csrimp.delegation_ind_description to web_user;
grant insert,select,update,delete on csrimp.delegation_region_description to web_user;

alter table csr.deleg_plan_deleg_region drop column has_manual_amends;

@../schema_body
@../region_body
@../csrimp/imp_body

@update_tail
