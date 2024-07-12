-- Please update version.sql too -- this keeps clean builds in sync
define version=1226
@update_header

alter table csr.calc_job modify phase default 0;
alter table csr.calc_job modify updated_dtm default sysdate;

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='CALC_JOB' and column_name='SCENARIO_RUN_SID' and nullable='N') loop
		execute immediate 'alter table csr.calc_job modify scenario_run_sid null';
	end loop;
end;
/

@update_tail
