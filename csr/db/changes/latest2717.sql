-- Please update version.sql too -- this keeps clean builds in sync
define version=2717
@update_header

DECLARE
	v_check	NUMBER;
BEGIN
  SELECT COUNT(*) 
    INTO v_check
    FROM sys.dba_scheduler_jobs
   WHERE OWNER = 'CSR'
     AND JOB_NAME = 'QS_ANSWER_FILE_TEXT';

  IF v_check = 1 THEN
    DBMS_SCHEDULER.DROP_JOB(
      job_name =>   'CSR.QS_ANSWER_FILE_TEXT',
      force => TRUE
    );
    COMMIT;
  END IF;
END;
/

@update_tail
