-- Please update version.sql too -- this keeps clean builds in sync
define version=1356
@update_header


@..\audit_pkg
@..\audit_body

-- Queue a job for processing audit module's mapped indicators at the start of each day
DECLARE
    job BINARY_INTEGER;
BEGIN
	FOR r IN (
		SELECT job_name FROM all_scheduler_jobs WHERE UPPER(job_name) = UPPER('TiggerAuditJobs') AND OWNER = UPPER('csr')
	)
	LOOP
		DBMS_SCHEDULER.DROP_JOB('csr.TiggerAuditJobs', TRUE);
	END LOOP;
	
	-- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.TriggerAuditJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'audit_pkg.TriggerAuditJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Trigger jobs to map audit module data to indicators');
   COMMIT;
END;
/

@update_tail
