-- Please update version.sql too -- this keeps clean builds in sync
define version=817
@update_header

grant select, insert, update, delete on actions.task_recalc_job to csr;
grant select, insert, update, delete on actions.task_recalc_period to csr;
grant select, insert, update, delete on actions.task_recalc_region to csr;
grant select on actions.task_region to csr;
grant select on actions.task_ind_dependency to csr;

create table csr.app_lock(
    app_sid    						number(10, 0)	default sys_context('security','app') not null,
    lock_type						number(10)		not null,
    dummy							number(1, 0)	default 0 not null,
    constraint pk_app_lock primary key (app_sid, lock_type),
    constraint fk_app_lock_customer foreign key (app_sid) references csr.customer(app_sid)
);
insert into csr.app_lock (app_sid, lock_type)
	select app_sid, 1
	  from csr.customer;
insert into csr.app_lock (app_sid, lock_type)
	select app_sid, 2
	  from csr.customer;
drop table csr.calc_job_lock;

begin
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'APP_LOCK',
		policy_name     => 'APP_LOCK_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
end;
/

@../csr_data_pkg
@../calc_pkg
@../csr_data_body
@../calc_body
@../region_body
@../indicator_body
@../system_status_body

@update_tail