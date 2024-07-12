-- Please update version.sql too -- this keeps clean builds in sync
define version=1064
@update_header

alter table csr.calc_job add running_on varchar2(256);

create or replace view csr.v$calc_job as
	select cj.app_sid, c.host, cj.calc_job_id, cj.unmerged, cj.scenario_run_sid, cj.processing, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm,
		   cj.phase, cjp.description phase_description, cj.work_done, cj.total_work, cj.updated_dtm, cj.running_on
	  from csr.calc_job cj, csr.calc_job_phase cjp, csr.customer c
	 where cj.phase = cjp.phase
	   AND cj.app_sid = c.app_sid;


@../stored_calc_datasource_body

@update_tail
