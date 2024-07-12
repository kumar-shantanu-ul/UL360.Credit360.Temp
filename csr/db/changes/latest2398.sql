-- Please update version.sql too -- this keeps clean builds in sync
define version=2398
@update_header

delete from csr.calc_job_aggregate_ind_group
  where calc_job_id in (
	select cjn.calc_job_id 
	  from csr.calc_job cjn
	 where cjn.calc_job_type is null
	   and exists(select 1 
				    from csr.calc_job cj 
				   where cj.calc_job_type = decode(cjn.scenario_run_sid, null, 0, 2)
				     and nvl(cj.scenario_run_sid,-1) = nvl(cjn.scenario_run_sid, -1)
					 and cj.app_sid=cjn.app_sid)
);

delete from csr.calc_job_ind
  where calc_job_id in (
	select cjn.calc_job_id 
	  from csr.calc_job cjn
	 where cjn.calc_job_type is null
	   and exists(select 1 
				    from csr.calc_job cj 
				   where cj.calc_job_type = decode(cjn.scenario_run_sid, null, 0, 2)
				     and nvl(cj.scenario_run_sid,-1) = nvl(cjn.scenario_run_sid, -1)
					 and cj.app_sid=cjn.app_sid)
);

delete from csr.calc_job cjn
 where cjn.calc_job_type is null
   and exists(select 1 
				from csr.calc_job cj 
			   where cj.calc_job_type = decode(cjn.scenario_run_sid, null, 0, 2)
				 and nvl(cj.scenario_run_sid,-1) = nvl(cjn.scenario_run_sid, -1)
				 and cj.app_sid=cjn.app_sid);

update csr.calc_job set calc_job_type = 0 where calc_job_type is null and scenario_run_sid is null;
update csr.calc_job set calc_job_type = 2 where calc_job_type is null and scenario_run_sid is not null;
alter table csr.calc_job modify calc_job_type not null;

@update_tail
