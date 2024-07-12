-- Please update version.sql too -- this keeps clean builds in sync
define version=382
@update_header

create table issue_scheduled_task (
	app_sid number(10) default sys_context('security', 'app') not null,
	issue_scheduled_task_id number(10) not null,
	label varchar2(255) not null,
	schedule_xml xmltype not null,
	period_xml xmltype not null,
	assign_to_user_sid number(10) not null,
	last_created date,
	constraint pk_issue_scheduled_task primary key (issue_scheduled_task_id)
	using index tablespace indx,
	constraint fk_issue_sched_task_user foreign key (app_sid, assign_to_user_sid)
	references csr_user(app_sid, csr_user_sid)
);

create sequence issue_scheduled_task_id_seq;

@..\issue_pkg
@..\issue_body

@update_tail

