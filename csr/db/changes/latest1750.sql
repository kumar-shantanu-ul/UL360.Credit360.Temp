-- Please update version too -- this keeps clean builds in sync
define version=1750
@update_header

alter table csr.scenario add file_based number(1) default 0 not null;
alter table csr.scenario add constraint ck_scenario_file_based check (file_based in (0,1));

alter table csr.scenario_run add version number(10);
	
create table csr.scenario_run_version
(
	app_sid				number(10) default sys_context('security', 'app') not null,
	scenario_run_sid	number(10) not null,
	version				number(10) not null,
	constraint pk_scenario_run_version primary key (app_sid, scenario_run_sid, version)
);

create table csr.scenario_run_version_file
(
	app_sid				number(10) default sys_context('security', 'app') not null,
	scenario_run_sid	number(10) not null,
	version				number(10) not null,
	interval			varchar2(1) not null,
	file_path			varchar2(4000) not null,
	sha1				raw(20) not null,
	constraint pk_scenario_run_version_file primary key (app_sid, scenario_run_sid, version, interval),
	constraint ck_scenario_run_file_interval check (interval in ('-', 'm', 'q', 'h', 'y')),
	constraint fk_scn_run_file_scn_run_ver foreign key (app_sid, scenario_run_sid, version)
	references csr.scenario_run_version (app_sid, scenario_run_sid, version)
);

alter table csr.scenario_run add constraint fk_scn_run_scn_run_ver foreign key 
(app_sid, scenario_run_sid, version) references csr.scenario_run_version (app_sid, scenario_run_sid, version);

@../scenario_run_pkg
@../scenario_run_body
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
