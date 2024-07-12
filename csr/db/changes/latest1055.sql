-- Please update version.sql too -- this keeps clean builds in sync
define version=1055
@update_header

grant execute on dbms_aq to csr;

create table csr.old_stored_calc_job as
	select * from csr.stored_calc_job;
	
drop table csr.stored_calc_job;

create table csr.val_change_log (
    app_sid       		number(10)		default sys_context('security', 'app') not null,
    ind_sid				number(10)		not null,
    start_dtm			date			not null,
    end_dtm				date			not null,
    constraint ck_val_change_log_dates check (start_dtm = trunc(start_dtm, 'mon') and end_dtm = trunc(end_dtm, 'mon') and end_dtm > start_dtm),
    constraint pk_val_change_log primary key (app_sid, ind_sid),
    constraint fk_val_change_log_ind foreign key (app_sid, ind_sid)
    references csr.ind (app_sid, ind_sid)
);

insert into csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
	select app_sid, ind_sid, min(start_dtm), max(end_dtm)
	  from csr.old_stored_calc_job
	 group by app_sid, ind_sid;
drop table csr.old_stored_calc_job;
	  
create table csr.old_sheet_calc_job as
	select * from csr.sheet_calc_job;

drop table csr.sheet_calc_job;
		
create table csr.sheet_val_change_log (
	app_sid				number(10)		default sys_context('security', 'app') not null,
    ind_sid				number(10)		not null,
    start_dtm			date			not null,
    end_dtm				date			not null,
    constraint ck_sheet_val_change_log_dates check (start_dtm = trunc(start_dtm, 'mon') and end_dtm = trunc(end_dtm, 'mon') and end_dtm > start_dtm),
    constraint pk_sheet_val_change_log primary key (app_sid, ind_sid),
    constraint fk_sheet_val_change_log_ind foreign key (app_sid, ind_sid)
    references csr.ind (app_sid, ind_sid)
);

insert into csr.sheet_val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
	select app_sid, ind_sid, min(start_dtm), max(end_dtm)
	  from csr.old_sheet_calc_job
	 group by app_sid, ind_sid;
drop table csr.old_sheet_calc_job;


create table csr.calc_job_phase
(
	phase							number(10) not null,
	description						varchar2(500) not null,
	constraint pk_calc_job_phase primary key (phase)
);

begin
	insert into csr.calc_job_phase (phase, description) values (0, 'Idle');
	insert into csr.calc_job_phase (phase, description) values (1, 'Fetching data');
	insert into csr.calc_job_phase (phase, description) values (2, 'Aggregating up');
	insert into csr.calc_job_phase (phase, description) values (3, 'Aggregating down');
	insert into csr.calc_job_phase (phase, description) values (4, 'Running calculations');
	insert into csr.calc_job_phase (phase, description) values (5, 'Writing data');
	insert into csr.calc_job_phase (phase, description) values (6, 'Merging data');
	insert into csr.calc_job_phase (phase, description) values (7, 'Failed - awaiting retry');
end;
/

drop table csr.scrag_progress;
drop table csr.scrag_progress_phase;
drop view csr.v$scrag_progress;

create table csr.calc_job (
    app_sid       		number(10)		default sys_context('security','app') not null,
    calc_job_id			number(10)		not null,
    unmerged			number(1)		not null,
    scenario_run_sid	number(10),
    processing    		number(10)		default 0 not null,
    start_dtm     		date            not null,
    end_dtm       		date            not null,
    last_attempt_dtm	date,
    phase				number(10)		default 0 not null,
    work_done			number(10)		default 0 not null,
    total_work			number(10)		default 0 not null,    
    updated_dtm			date			default sysdate not null,
    constraint ck_calc_job_dates check (start_dtm = trunc(start_dtm, 'mon') and end_dtm = trunc(end_dtm, 'mon') and end_dtm > start_dtm),
    constraint ck_calc_job_processing check (processing in (0,1)),
    constraint ck_calc_job_unmerged check (unmerged in (0,1)),
    constraint pk_calc_job primary key (app_sid, calc_job_id),
    constraint uk_calc_job unique (app_sid, unmerged, scenario_run_sid, processing),
    constraint fk_calc_job_customer foreign key (app_sid) references csr.customer (app_sid),
    constraint fk_scenario_calc_job_scn_run foreign key (app_sid, scenario_run_sid)
    references csr.scenario_run (app_sid, scenario_run_sid),
    constraint fk_calc_job_phase foreign key (phase) references csr.calc_job_phase(phase)
);


create index csr.ix_calc_job_phase on csr.calc_job(phase);
	
create or replace view csr.v$calc_job as
	select cj.app_sid, c.host, cj.calc_job_id, cj.unmerged, cj.scenario_run_sid, cj.processing, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm,
		   cj.phase, cjp.description phase_description, cj.work_done, cj.total_work, cj.updated_dtm
	  from csr.calc_job cj, csr.calc_job_phase cjp, csr.customer c
	 where cj.phase = cjp.phase
	   AND cj.app_sid = c.app_sid;


create index csr.ix_calc_job_scenario_run on csr.calc_job(app_sid, scenario_run_sid)
;

create table csr.calc_job_ind (
    app_sid			number(10)			default sys_context('security','app') not null,
	calc_job_id	    number(10)			not null,
    ind_sid			number(10)			not null,
    constraint pk_calc_job_ind primary key (app_sid, calc_job_id, ind_sid),
    constraint fk_calc_job_ind_calc_job foreign key (app_sid, calc_job_id) 
    references csr.calc_job (app_sid, calc_job_id),
    constraint fk_calc_job_ind_ind foreign key (app_sid, ind_sid)
    references csr.ind (app_sid, ind_sid)
);

create index csr.ix_calc_job_ind_ind on csr.calc_job_ind(app_sid, ind_sid)
;

create table csr.calc_job_aggregate_ind (
    app_sid			number(10)			default sys_context('security','app') not null,
	calc_job_id	    number(10)			not null,
    ind_sid			number(10)			not null,
    constraint pk_calc_job_aggregate_ind primary key (app_sid, calc_job_id, ind_sid),
    constraint fk_calc_job_agg_ind_calc_job foreign key (app_sid, calc_job_id) 
    references csr.calc_job (app_sid, calc_job_id),
    constraint fk_calc_job_agg_ind_ind foreign key (app_sid, ind_sid)
    references csr.ind (app_sid, ind_sid)
);

create index csr.ix_calc_job_agg_ind_ind on csr.calc_job_aggregate_ind(app_sid, ind_sid)
;

create sequence csr.calc_job_id_seq;

drop table csr.scrag_queue;

create or replace type csr.t_scrag_queue_entry as object (
	calc_job_id number(10)
);
/

BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.scrag_queue',
		queue_payload_type => 'csr.t_scrag_queue_entry'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.scrag_queue',
		queue_table => 'csr.scrag_queue'
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.scrag_queue'
	);
END;
/

ALTER TABLE csr.scenario_man_run_request add unmerged number(1) default 0 not null;
ALTER TABLE csr.scenario_man_run_request add constraint ck_scn_man_rr_unmerged check (unmerged in (0,1));
alter table csr.scenario_man_run_request drop column processing;

drop index CSR.IX_AGG_CALC_JOB_GRP ;
alter table csr.aggregate_ind_calc_job  drop primary key drop index;
delete from csr.aggregate_ind_calc_job 
 where processing = 1
   and (app_sid, aggregate_ind_group_id) in (
   		select app_sid, aggregate_ind_group_id 
   		  from csr.aggregate_ind_calc_job 
 	     where processing = 0);
alter table csr.aggregate_ind_calc_job add CONSTRAINT PK_AGG_IND_RECALC_JOB PRIMARY KEY (APP_SID, AGGREGATE_IND_GROUP_ID);
alter table csr.aggregate_ind_calc_job drop column processing;

alter table csr.scenario_auto_run_request drop primary key drop index;
delete from csr.scenario_auto_run_request
 where processing = 1
   and (app_sid, scenario_sid) in (
   		select app_sid, scenario_sid
   		  from csr.scenario_auto_run_request
 	     where processing = 0);
alter table csr.scenario_auto_run_request add CONSTRAINT PK_SCENARIO_AUTO_RUN_REQUEST PRIMARY KEY (APP_SID, SCENARIO_SID);
alter table csr.scenario_auto_run_request drop column processing;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CALC_JOB',
		policy_name     => 'CALC_JOB_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CALC_JOB_IND',
		policy_name     => 'CALC_JOB_IND_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CALC_JOB_AGGREGATE_IND',
		policy_name     => 'CALC_JOB_AGGREGATE_IND_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../calc_pkg
@../csr_data_pkg
@../system_status_pkg
@../stored_calc_datasource_pkg
@../calc_body
@../val_body
@../indicator_body
@../csr_user_body
@../region_body
@../delegation_body
@../stored_calc_datasource_body
@../csr_data_body
@../system_status_body
@../actions/scenario_body

@update_tail
