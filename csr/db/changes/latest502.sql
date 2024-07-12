-- Please update version.sql too -- this keeps clean builds in sync
define version=502
@update_header

alter table customer add audit_calc_changes number(1) default 0 not null;
alter table customer add constraint ck_customer_audit_calc_changes check (audit_calc_changes in (0,1));
alter table ind add calc_description varchar2(4000);

@..\calc_pkg
@..\calc_body
@..\csr_app_body
@..\dataview_body
@..\datasource_body
@..\range_body
@..\pending_datasource_body
@..\schema_body
@..\delegation_body
@..\indicator_pkg
@..\indicator_body
@..\pending_body

-- plus actions\task_body.sql
-- actions\ind_template_body.sql
-- (if you have actions)

@update_tail
