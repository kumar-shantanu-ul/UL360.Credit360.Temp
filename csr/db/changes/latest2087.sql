-- Please update version.sql too -- this keeps clean builds in sync
define version=2087
@update_header

alter table csr.batch_job add (
	one_at_a_time					number(1) default 0 not null,
	processing						number(1) default 0 not null,
	constraint ck_batch_job_one_at_a_time check (one_at_a_time in (0, 1)),
	constraint ck_batch_job_processing check (processing in (0, 1))
);

-- note the "0-" is important here -- if it's not present Oracle gives ORA-01408: such column list already indexed
create unique index csr.ux_batch_job_one_at_a_time on csr.batch_job 
(app_sid, batch_job_type_id, case when one_at_a_time = 1 and processing = 1 then 1 else 0-batch_job_id end);

alter table csr.batch_job_type add (
	one_at_a_time					number(1) default 0 not null,
	constraint ck_batch_job_type_one_at_time check (one_at_a_time in (0, 1))
);
update csr.batch_job_type set one_at_a_time = 1 where batch_job_type_id = 1;

create table csr.deleg_plan_job
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	batch_job_id					number(10) not null,
	delegation_sid					number(10),							-- merge if equal, new if not
	deleg_plan_sid					number(10),							-- merge if equal, new if not	
	is_dynamic_plan					number(1) default 1 not null,		-- merge if equal, new if not
	overwrite_dates					number(1) default 0 not null,		-- merge greatest value
	constraint ck_deleg_plan_job_type check (
		( delegation_sid is not null and deleg_plan_sid is null )
	 or ( delegation_sid is null and deleg_plan_sid is not null )
	),
	constraint pk_deleg_plan_job primary key (app_sid, batch_job_id),
	constraint fk_deleg_plan_job_batch_job foreign key (app_sid, batch_job_id)
	references csr.batch_job (app_sid, batch_job_id),
	constraint fk_deleg_plan_job_deleg_plan foreign key (app_sid, deleg_plan_sid)
	references csr.deleg_plan (app_sid, deleg_plan_sid),
	constraint fk_deleg_plan_job_deleg foreign key (app_sid, delegation_sid)
	references csr.delegation (app_sid, delegation_sid)
);

update csr.batch_job_type 
   set one_at_a_time = 1,
	   sp = 'csr.deleg_plan_pkg.ProcessJob'
 where batch_job_type_id = 1;

insert into csr.deleg_plan_job (app_sid, batch_job_id, delegation_sid)
	select app_sid, batch_job_id, delegation_sid
	  from csr.deleg_plan_job;

drop table csr.deleg_plan_sync_job;

create index csr.ix_deleg_plan_job_deleg on csr.deleg_plan_job (app_sid, delegation_sid);
create index csr.ix_deleg_plan_job_deleg_plan on csr.deleg_plan_job (app_sid, deleg_plan_sid);

@../batch_job_pkg
@../batch_job_body
@../csr_data_body
@../csr_user_body
@../deleg_plan_pkg
@../deleg_plan_body
@../delegation_body
@../region_body

@update_tail
