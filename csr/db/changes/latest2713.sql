-- Please update version.sql too -- this keeps clean builds in sync
define version=2713
@update_header

DECLARE
	v_count 	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_scheduler_jobs
	 WHERE UPPER(job_name) = UPPER('csr.qs_answer_file_text');
	   
	IF v_count > 0 THEN
		DBMS_SCHEDULER.CREATE_JOB (
		   job_name             => 'csr.qs_response_file_text',
		   job_type             => 'PLSQL_BLOCK',
		   job_action           => 'ctx_ddl.sync_index(''ix_qs_response_file_srch'');',
		   job_class            => 'low_priority_job',
		   start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		   repeat_interval      => 'FREQ=MINUTELY',
		   enabled              => TRUE,
		   auto_drop            => FALSE,
		   comments             => 'Synchronise quick survey text indexes');
	   COMMIT;
   END IF;
END;
/

BEGIN
	UPDATE csr.qs_response_file
	   SET data = data;
	COMMIT;
END;
/

@update_tail
