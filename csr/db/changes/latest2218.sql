-- Please update version.sql too -- this keeps clean builds in sync
define version=2218
@update_header

begin
	for r in (select * from all_Tab_columns where owner='CSR' and table_name='SCENARIO_RUN_VAL' and column_name='SCENARIO_RUN_SID' and nullable='Y') loop
		execute immediate 'alter table csr.scenario_run_val modify scenario_run_sid not null';
	end loop;
end;
/

alter table csr.scenario_run_val drop CONSTRAINT PK_SCENARIO_RUN_VAL drop index;
alter table csr.scenario_run_val add 
    CONSTRAINT PK_SCENARIO_RUN_VAL 
    PRIMARY KEY (APP_SID, SCENARIO_RUN_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM);

@update_tail
