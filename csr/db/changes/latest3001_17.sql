-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='SCENARIO_RUN' and column_name='LAST_RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.scenario_run add last_run_by_user_sid number(10) default 3 not null';
		execute immediate 'alter table csr.scenario_run add constraint fk_Scenario_run_last_run_user foreign key (app_sid, last_run_by_user_sid) references csr.csr_user (app_sid, csr_user_sid)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='SCENARIO_RUN'  and column_name='LAST_RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.scenario_run add last_run_by_user_sid number(10) not null';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='CALC_JOB'  and column_name='RUN_BY_USER_SID';
	if v_exists = 0 then
		execute immediate 'alter table csr.calc_job add run_by_user_sid number(10) default nvl(sys_context(''SECURITY'',''SID''),3) not null';
		execute immediate 'alter table csr.calc_job add constraint fk_calc_job_last_run_user foreign key (app_sid, run_by_user_sid) references csr.csr_user (app_sid, csr_user_sid)';
	end if;

	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_CALC_JOB_RUN_BY_USER_S';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_calc_job_run_by_user_s on csr.calc_job (app_sid, run_by_user_sid)';
	end if;
	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_SCENARIO_ALER_CSR_USER_SID';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_scenario_aler_csr_user_sid on csr.scenario_alert (app_sid, csr_user_sid)';
	end if;
	select count(*) into v_exists from all_indexes where owner='CSR' and index_name='IX_SCENARIO_RUN_LAST_RUN_BY_U';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_scenario_run_last_run_by_u on csr.scenario_run (app_sid, last_run_by_user_sid)';
	end if;
end;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
