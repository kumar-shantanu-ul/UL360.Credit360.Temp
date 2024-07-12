-- Please update version.sql too -- this keeps clean builds in sync
define version=963
@update_header

alter table csr.ind add is_system_managed number(1) default 0 not null;
alter table csr.ind add constraint CK_IND_IS_SYSTEM_MANAGED CHECK (IS_SYSTEM_MANAGED IN (0,1));
alter table csrimp.ind add is_system_managed number(1) default 0 not null;
alter table csrimp.ind add constraint ck_ind_is_system_managed check (is_system_managed in (0,1));

update csr.ind set is_system_managed = 1 where gas_type_id is not null or ind_type = 3;
update csr.ind set is_system_managed = 1 where ind_sid in (select ind_sid from csr.ind_selection_group_member);

alter table csr.ind add constraint CK_IND_MUST_BE_MANAGED check (
	( gas_type_id is not null and is_system_managed = 1 ) or -- gas indicators must be managed
	( ind_type = 3 and is_system_managed = 1 ) or -- aggregate indicators must be managed
	( ind_type != 3 and gas_type_id is null ) -- neither of these is ok as managed or unmanaged
);	

@../csr_data_pkg
@../indicator_pkg
@../region_pkg
@../stored_calc_datasource_pkg
@../val_datasource_pkg
@../delegation_pkg
@../factor_pkg
@../dataview_body 
@../vb_legacy_body
@../pending_datasource_body
@../region_body
@../actions/task_body
@../delegation_body
@../csrimp/imp_body
@../stored_calc_datasource_body
@../pending_body
@../datasource_body
@../range_body
@../val_datasource_body
@../schema_body
@../indicator_body
@../csrimp/imp_body
@../factor_body
@../audit_body

@update_tail
