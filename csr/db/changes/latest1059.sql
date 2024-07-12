-- Please update version.sql too -- this keeps clean builds in sync
define version=1059
@update_header

-- job to populate the queue
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.DROP_JOB (
       job_name             => 'csr.QueueCalcJobs'
    );
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueCalcJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.stored_calc_datasource_pkg.QueueCalcJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=15',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Scan value change logs and produce jobs for the calculation engine');
END;
/

@update_tail
