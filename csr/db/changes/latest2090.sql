-- Please update version.sql too -- this keeps clean builds in sync
define version=2090
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_indexes
	 where owner = 'CSR' and index_name = 'IX_DELEG_PLAN_JOB_DELEG';
	if v_exists = 0 then
		execute immediate 'create index csr.IX_DELEG_PLAN_JOB_DELEG on csr.deleg_plan_job (app_sid, delegation_sid)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_indexes
	 where owner = 'CSR' and index_name = 'IX_DELEG_PLAN_JOB_DELEG_PLAN';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_deleg_plan_job_deleg_plan on csr.deleg_plan_job (app_sid, deleg_plan_sid)';
	end if;
end;
/

@update_tail
