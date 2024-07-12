-- Please update version.sql too -- this keeps clean builds in sync
define version=915
@update_header

create table csr.dataview_scenario_run (
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	dataview_sid					number(10) not null,
	scenario_run_type				number(10) not null,
	scenario_run_sid				number(10),
	constraint uk_dataview_scenario_run unique (app_sid, dataview_sid, scenario_run_type, scenario_run_sid),
	constraint fk_dataview_scn_run_scn_run foreign key (app_sid, scenario_run_sid)
	references csr.scenario_run (app_sid, scenario_run_sid),
	constraint ck_scenario_run_sid check (
		( scenario_run_type = 2 and scenario_run_sid is not null ) or
		( scenario_run_type in (0,1) and scenario_run_sid is null ))
);

create index csr.ix_dataview_scn_run_scn_run on csr.dataview_scenario_run (app_sid, scenario_run_sid);

@../scenario_body
@../dataview_pkg
@../dataview_body

@update_tail
