-- Please update version.sql too -- this keeps clean builds in sync
define version=2789
define minor_version=0
@update_header

declare
	v_ver number;
begin
	select db_version into v_ver from mail.version;
	if v_ver NOT IN (29,30) then
		raise_application_error(-20001, 'Mail schema is not version 29 or 30');
	end if;
end;
/

BEGIN
	FOR r IN (SELECT * FROM dba_scheduler_jobs WHERE owner='MAIL' and job_name='CLEANORPHANEDMESSAGES') loop
		DBMS_SCHEDULER.DROP_JOB(
       		job_name             => 'mail.cleanOrphanedMessages'
		);
	END LOOP;
    DBMS_SCHEDULER.CREATE_JOB(
       job_name             => 'mail.cleanOrphanedMessages',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'mail_pkg.cleanOrphanedMessages;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 02:21 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Remove messages that are no longer in any mailboxes'
    );
END;
/

update mail.version set db_version=31;

@../../../../oss/yam/db/oracle/mail_pkg
@../../../../oss/yam/db/oracle/mail_body

@update_tail
