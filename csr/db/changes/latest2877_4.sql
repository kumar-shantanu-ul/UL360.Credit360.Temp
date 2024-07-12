-- Please update version.sql too -- this keeps clean builds in sync
define version=2877
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

create table csr.scenario_run_snapshot_file
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	version							number(10) not null,
	file_path						varchar2(4000), --not null,
	sha1							raw(20), --not null,
	constraint pk_scenario_run_snapshot_file primary key (app_sid, scenario_run_snapshot_sid, version)
);

create table csr.scenario_run_snapshot
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	scenario_run_sid				number(10) not null,
	start_dtm						date not null,
	end_dtm							date not null,
	period_set_id					number(10),
	period_interval_id				number(10),
	last_updated_dtm				date default sysdate not null,
	version							number(10) not null deferrable initially deferred,
	constraint pk_scenario_run_snapshot primary key (app_sid, scenario_run_snapshot_sid),
	constraint fk_scenario_run_snapshot foreign key (app_sid, scenario_run_sid)
	references csr.scenario_run (app_sid, scenario_run_sid),
	constraint fk_scn_run_scn_snap_run_file foreign key (app_sid, scenario_run_snapshot_sid, version)
	references csr.scenario_run_snapshot_file (app_sid, scenario_run_snapshot_sid, version),
	constraint fk_scn_run_snap_period_int foreign key (app_sid, period_set_id, period_interval_id)
	references csr.period_interval (app_sid, period_set_id, period_interval_id),
	constraint ck_scn_run_snap_period_int check (
		(period_set_id is null and period_interval_id is null) or
		(period_set_id is not null and period_interval_id is not null)
	)
);
create index csr.ix_scn_run_snap_period_int on csr.scenario_run_snapshot (app_sid, period_set_id, period_interval_id);
create index csr.ix_scn_run_snap_scn_run on csr.scenario_run_snapshot (app_sid, scenario_run_sid);
create index csr.ix_scn_run_snap_file_ver on csr.scenario_run_snapshot (app_sid, scenario_run_snapshot_sid, version);

alter table csr.scenario_run_snapshot_file add
	constraint fk_scn_run_snap_file_scn_run foreign key (app_sid, scenario_run_snapshot_sid)
	references csr.scenario_run_snapshot (app_sid, scenario_run_snapshot_sid);

create table csr.scenario_run_snapshot_ind
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	ind_sid							number(10) not null,
	constraint pk_scenario_run_snapshot_ind primary key (app_sid, scenario_run_snapshot_sid, ind_sid),
	constraint fk_scn_run_snapshot_ind_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid)
);
create index csr.ix_scn_run_snapshot_ind_ind on csr.scenario_run_snapshot_ind (app_sid, ind_sid);

create table csr.scenario_run_snapshot_region
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	region_sid						number(10) not null,
	constraint pk_scenario_run_snapshot_reg primary key (app_sid, scenario_run_snapshot_sid, region_sid),
	constraint fk_scn_run_snapshot_reg_reg foreign key (app_sid, region_sid)
	references csr.region (app_sid, region_sid)
);
create index csr.ix_scn_run_snapshot_reg_reg on csr.scenario_run_snapshot_region (app_sid, region_sid);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
declare
	v_class_id security.security_pkg.T_CLASS_ID;
begin
	BEGIN
		security.user_pkg.logonadmin;
		security.class_pkg.CreateClass(sys_context('security','act'), NULL, 'CSRScenarioRunSnapshot', 'csr.scenario_run_snapshot_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
end;
/

-- RLS

-- Data

-- ** New package grants **
create or replace package csr.scenario_Run_snapshot_pkg as end;
/

grant execute on csr.scenario_run_snapshot_pkg to security;
grant execute on csr.scenario_run_snapshot_pkg to web_user;

-- *** Packages ***
@../scenario_run_snapshot_pkg
@../stored_calc_datasource_pkg
@../scenario_run_snapshot_body
@../stored_calc_datasource_body
	 
@update_tail
