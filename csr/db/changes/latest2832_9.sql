-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=9
@update_header

-- *** DDL ***
alter table csr.scenario add data_source_sp_args varchar2(4000);
update csr.scenario set data_source_sp_args = 'vals,notes,files' where data_source=2;
alter table csr.scenario drop constraint ck_scenario_data_source;
alter table csr.scenario add constraint ck_scenario_data_source check (
	(data_source in (0, 1) and data_source_sp is null and data_source_sp_args is null) or 
	(data_source = 2 and data_source_sp is not null and data_source_sp_args is not null)
);

alter table csr.aggregate_ind_group add helper_proc_args varchar2(4000) default 'vals' not null;

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION' and temporary='N') loop
		dbms_output.put_line('tab '||r.table_name);
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.scenario add data_source_sp_args varchar2(4000);
alter table csrimp.aggregate_ind_group add helper_proc_args varchar2(4000) not null;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../aggregate_ind_pkg
@../aggregate_ind_body
@../approval_dashboard_pkg
@../approval_dashboard_body
@../csr_app_body
@../scenario_body
@../schema_body
@../stored_calc_datasource_body
@../csrimp/imp_body

@update_tail
