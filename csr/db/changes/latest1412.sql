-- Please update version.sql too -- this keeps clean builds in sync
define version=1412
@update_header

alter table csr.scenario_man_run_request rename column unmerged to data_source;
alter table csr.scenario_man_run_request add constraint ck_scn_man_run_req_data_src check (data_source in (0,1,2));

alter table csr.calc_job rename column unmerged to data_source;
alter table csr.calc_job drop constraint ck_calc_job_unmerged;
alter table csr.calc_job add constraint ck_calc_job_data_source check (data_source in (0,1,2));

alter table csr.customer add merged_scenario_run_sid number(10);
alter table csr.customer add constraint fk_customer_mrg_scenario_run 
foreign key (app_sid, merged_scenario_run_sid) references csr.scenario_run (app_sid, scenario_run_sid);
create index csr.ix_cust_mrged_scn_run_sid on csr.customer (app_sid, merged_scenario_run_sid);

alter table csrimp.customer add merged_scenario_run_sid number(10);

create or replace view csr.v$calc_job as
	select cj.app_sid, c.host, cj.calc_job_id, cj.data_source, cj.scenario_run_sid, cj.processing, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm,
		   cj.phase, cjp.description phase_description, cj.work_done, cj.total_work, cj.updated_dtm, cj.running_on
	  from csr.calc_job cj, csr.calc_job_phase cjp, csr.customer c
	 where cj.phase = cjp.phase
	   AND cj.app_sid = c.app_sid;

@../stored_calc_datasource_pkg
@../schema_body
@../system_status_body
@../stored_calc_datasource_body
@../csrimp/imp_body
@../scenario_body
@../csr_app_body
@../csr_data_body

@update_tail
