-- Please update version.sql too -- this keeps clean builds in sync
define version=1306
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

-- XXX: this will probably fail -- the UPD user needs grant option on this view
-- which implies running as SYS not UPD.
-- I suppose we'll have to tell DT that.
-- grant select on dba_scheduler_job_run_details to upd with grant option;
grant select on dba_scheduler_job_run_details to aspen2;

create table aspen2.error_log (
	error_log_id	number(10) not null,
	app_sid			number(10) default sys_context('security','app'),
	dtm 			date default sysdate not null,
	message 		varchar2(4000) not null,
	sent 			number(1) default 0 not null,
	constraint pk_error_log primary key (error_log_id),
	constraint ck_error_log_sent check (sent in (0,1))
);

create table aspen2.sent_dba_scheduler_log_id
(
	last_sent_log_id 	number(10) not null,
	only_one_row 		number(1) default 0 not null,
	constraint ck_sent_dba_sch_log_oor check (only_one_row=0),
	constraint pk_sent_dba_scheduler_log_id primary key (only_one_row)
);
create sequence aspen2.error_log_id_seq;

create or replace package aspen2.error_pkg as
procedure dummy;
end;
/
create or replace package body aspen2.error_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on aspen2.error_pkg to csr;
grant select on csr.customer to aspen2;

-- fix for differences between the model and live
grant execute on ctx_ddl to csr;
grant execute on ctx_ddl to chain;


declare
	v_exists number;
	job BINARY_INTEGER;
begin
	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'DOCLIB_TEXT';
	if v_exists = 0 then
		-- reindex job -- index on commit is flaky

	    -- now and every mintue afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.doclib_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_doc_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2008/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise doclib text indexes');
		COMMIT;
	end if;

	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'FILE_UPLOAD_TEXT';
	if v_exists = 0 then
	    -- now and every minute afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.file_upload_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_file_upload_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise file upload text content indexes');
		COMMIT;
	end if;

	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'SHEET_NOTE_TEXT';
	if v_exists = 0 then
	    -- now and every minute afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.sheet_note_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_sh_val_note_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise sheet note text indexes');
		COMMIT;
	end if;

	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'HELP_BODY_TEXT';
	if v_exists = 0 then
	    -- now and every minute afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.help_body_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_help_body_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise body text indexes');
		COMMIT;
	end if;

	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'QS_ANSWER_FILE_TEXT';
	if v_exists = 0 then
	    -- now and every minute afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.qs_answer_file_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_qs_answer_file_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise survey mangager text indexes');
		COMMIT;
	end if;

	select count(*) into v_exists from dba_scheduler_jobs where owner='CSR' and job_name = 'ISSUE_LOG_TEXT';
	if v_exists = 0 then
	    -- now and every minute afterwards
	    -- 10g w/low_priority_job created
	    DBMS_SCHEDULER.CREATE_JOB (
	       job_name             => 'csr.issue_log_text',
	       job_type             => 'PLSQL_BLOCK',
	       job_action           => 'ctx_ddl.sync_index(''ix_issue_log_search'');ctx_ddl.sync_index(''ix_issue_search'');',
	       job_class            => 'low_priority_job',
	       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	       repeat_interval      => 'FREQ=MINUTELY',
	       enabled              => TRUE,
	       auto_drop            => FALSE,
	       comments             => 'Synchronise issue text indexes');
		COMMIT;
	end if;
end;
/
	
@../../../aspen2/db/error_pkg
@../../../aspen2/db/error_body
@../delegation_body

@update_tail
