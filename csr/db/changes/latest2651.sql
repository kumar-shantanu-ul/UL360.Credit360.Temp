--Please update version.sql too -- this keeps clean builds in sync
define version=2651
@update_header

alter table csr.calc_job add created_dtm date default sysdate not null ;
alter table csr.calc_job add attempts number (10) default 0 not null ;
create or replace view csr.v$calc_job as
	select cj.calc_job_id, c.host, cj.app_sid, cq.name calc_queue_name, 
		   sr.description scenario_run_description, cjp.description phase_description, 
		   case when cj.total_work = 0 then 0 else round(cj.work_done / cj.total_work * 100,2) end progress,
		   cj.running_on, cj.updated_dtm, cj.processing, cj.work_done, cj.total_work, cj.phase,
		   cj.calc_job_type, cj.scenario_run_sid, cj.start_dtm, cj.end_dtm, cj.created_dtm,
		   cj.last_attempt_dtm, cj.attempts, cq.calc_queue_id, cj.priority, cj.full_recompute,
		   cj.delay_publish_scenario, cj.process_after_dtm
	  from csr.calc_job cj
	  join csr.calc_job_phase cjp on cj.phase = cjp.phase
	  join csr.customer c on cj.app_sid = c.app_sid
	  join csr.calc_queue cq on cj.calc_queue_id = cq.calc_queue_id
	  left join csr.scenario_run sr on cj.app_sid = sr.app_sid and cj.scenario_run_sid = sr.scenario_run_sid;

@../stored_calc_datasource_body

@update_tail
