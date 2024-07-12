-- Please update version.sql too -- this keeps clean builds in sync
define version=2437
@update_header

alter table csr.calc_job add delay_publish_scenario number(1) default 0 not null;
alter table csr.calc_job add constraint ck_calc_job_delay_publish_scn check (delay_publish_scenario in (0,1));

alter table csr.scenario_auto_run_request add delay_publish_scenario number(1) default 0 not null;
alter table csr.scenario_auto_run_request add constraint ck_scn_ar_req_dly_publish_scn check (delay_publish_scenario in (0,1));
drop table csr.temp_sheets_ind_region_to_use2;

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../region_body

@update_tail
