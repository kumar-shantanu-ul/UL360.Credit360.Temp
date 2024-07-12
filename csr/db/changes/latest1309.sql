-- Please update version.sql too -- this keeps clean builds in sync
define version=1309
@update_header

-- Queue a job to expire old error logs
DECLARE
    job BINARY_INTEGER;
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
	   job_name             => 'aspen2.expireErrorLog',
	   job_type             => 'PLSQL_BLOCK',
	   job_action           => 'error_log_pkg.expire',
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
