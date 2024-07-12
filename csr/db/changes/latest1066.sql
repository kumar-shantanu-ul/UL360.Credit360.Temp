-- Please update version.sql too -- this keeps clean builds in sync
define version=1066
@update_header

alter table csr.scenario_run_val drop primary key drop index;
alter table csr.scenario_run_val drop column scenario_run_val_id;
drop sequence csr.scenario_run_val_id_seq;
begin
	for r in (select constraint_name from all_constraints where owner='CSR' and constraint_name='UK_SCENARIO_RUN_VAL' and table_name='SCENARIO_RUN_VAL' and constraint_type='U') loop
		execute immediate 'alter table csr.scenario_run_val drop constraint uk_scenario_run_val drop index';
	end loop;
	for r in (select index_name from all_indexes where owner='CSR' and index_name='UK_SCENARIO_RUN_VAL' and dropped='NO') loop
		execute immediate 'drop index csr.uk_scenario_run_val';
	end loop;
end;
/
alter table csr.scenario_run_val add constraint pk_scenario_run_val primary key (APP_SID, SCENARIO_RUN_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM);

@../stored_calc_datasource_body
@../scenario_run_pkg
@../scenario_run_body
@../val_datasource_body

@update_tail
