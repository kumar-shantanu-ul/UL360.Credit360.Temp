-- Please update version.sql too -- this keeps clean builds in sync
define version=1123
@update_header

alter table csr.customer add (
  COPY_VALS_TO_NEW_SHEETS          NUMBER(1, 0)      DEFAULT 0 NOT NULL,
  CONSTRAINT CHK_CPY_VAL_TO_NEW_SHT CHECK (COPY_VALS_TO_NEW_SHEETS IN (0,1))
);


@..\delegation_pkg

@..\indicator_body
@..\delegation_body

-- Queue a job for rolling forward value data for marked indicators
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards (could possibly be monthly?)
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.CreateNewSheets',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'delegation_pkg.CreateNewSheets;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Create new sheets for delegations');
       COMMIT;
END;
/


@update_tail