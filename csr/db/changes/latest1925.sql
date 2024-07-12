-- Please update version.sql too -- this keeps clean builds in sync
define version=1925
@update_header

alter table csr.model add scenario_run_type number(10) default 0 not null;
alter table csr.model add scenario_run_sid number(10);
update csr.model set scenario_run_type = 1 where data_source_options is not null;
alter table csr.model drop column data_source_options;
alter table csr.model add constraint ck_model_scn_run_sid check (
	(scenario_run_type = 2 and scenario_run_sid is not null) or
	(scenario_run_type in (0, 1) and scenario_run_sid is null)
);
alter table csr.model add constraint fk_model_scn_run
foreign key (app_sid, scenario_run_sid) references csr.scenario_run (app_sid, scenario_run_sid);

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.model add scenario_run_type number(10) not null;
alter table csrimp.model add scenario_run_sid number(10);
alter table csrimp.model drop column data_source_options;
alter table csrimp.model add constraint ck_model_scn_run_sid check (
	(scenario_run_type = 2 and scenario_run_sid is not null) or
	(scenario_run_type in (0, 1) and scenario_run_sid is null)
);


@../model_pkg
@../model_body
@../schema_body
@../csrimp/imp_body

@update_tail