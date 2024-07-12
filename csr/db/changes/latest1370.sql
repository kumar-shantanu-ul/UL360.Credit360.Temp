-- Please update version.sql too -- this keeps clean builds in sync
define version=1370
@update_header

-- Queue a job to expire old error logs
DECLARE
    job BINARY_INTEGER;
BEGIN
	FOR r IN (
		SELECT job_name FROM all_scheduler_jobs WHERE UPPER(job_name) = UPPER('expireErrorLog') AND OWNER = UPPER('aspen2')
	)
	LOOP
		DBMS_SCHEDULER.DROP_JOB('aspen2.expireErrorLog', TRUE);
	END LOOP;
	DBMS_SCHEDULER.CREATE_JOB (
	   job_name             => 'aspen2.expireErrorLog',
	   job_type             => 'PLSQL_BLOCK',
	   job_action           => 'error_pkg.ExpireErrors',
	   job_class			=> 'low_priority_job',
	   repeat_interval	    => 'FREQ=DAILY',
	   enabled              => TRUE,
	   auto_drop            => FALSE,
	   start_date		    => TO_DATE('2000-01-01 01:30:00','yyyy-mm-dd hh24:mi:ss'),
	   comments             => 'Expire old error logs');    
	COMMIT;
END;
/

@update_tail
