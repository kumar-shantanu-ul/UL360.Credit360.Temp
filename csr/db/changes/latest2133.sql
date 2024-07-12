-- Please update version.sql too -- this keeps clean builds in sync
define version=2133
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner = 'CSR' and table_name = 'SCENARIO_RUN_VERSION_FILE' and column_name = 'DISCARD';
	 
	if v_exists = 0 then
		execute immediate 'alter table csr.scenario_run_version_file add discard number(1) default 0 not null';
		execute immediate 'alter table csr.scenario_run_version_file add constraint ck_scn_run_ver_file_discard check (discard in (0,1))';
	end if;
end;
/

@../stored_calc_datasource_body

@update_tail