-- Please update version.sql too -- this keeps clean builds in sync
define version=2317
@update_header

-- job to mark calc jobs as failed
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.MarkFailedCalcJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.stored_calc_datasource_pkg.MarkFailedJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=3',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Mark calc jobs as failed (if they have failed)');
END;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail