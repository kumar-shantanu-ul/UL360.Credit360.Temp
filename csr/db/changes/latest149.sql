-- Please update version.sql too -- this keeps clean builds in sync
define version=149
@update_header

create table session_extra
(
	act_id	char(36) not null,
	key		varchar2(255) not null,
	binary	blob,
	text	clob,
	constraint pk_session_extra primary key (act_id, key)
	using index tablespace indx
)
lob (binary, text)
store as (cache);

-- Queue a job for deleting old 'extra session' data
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.SessionExtraCleanUp',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'session_extra_pkg.CleanOldData;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 04:12 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Raise delegation reminders');
       COMMIT;
END;
/

@update_tail
