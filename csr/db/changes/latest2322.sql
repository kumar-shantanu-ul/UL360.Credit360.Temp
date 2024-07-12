-- Please update version.sql too -- this keeps clean builds in sync
define version=2322
@update_header


ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD (
    RUN_DAILY NUMBER(1) DEFAULT 0 NOT NULL, 
    LABEL VARCHAR2(1024),
    CONSTRAINT CHK_AGGR_IND_GRP_RUN_DAILY CHECK (RUN_DAILY IN (0,1))
);

UPDATE CSR.AGGREGATE_IND_GROUP SET LABEL = NAME;

ALTER TABLE CSR.AGGREGATE_IND_GROUP MODIFY LABEL NOT NULL;


ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP ADD (
    RUN_DAILY         NUMBER(1),
    LABEL           VARCHAR2(1024)
);

UPDATE CSRIMP.AGGREGATE_IND_GROUP SET LABEL = NAME, RUN_DAILY = 0;

ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP MODIFY LABEL NOT NULL;
ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP MODIFY RUN_DAILY NOT NULL;



-- Queue a job for lazy devs who want an easy way to refresh aggregate ind groups daily
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.RefreshDailyGroups',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.aggregate_ind_pkg.RefreshDailyGroups;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Refresh aggregate ind groups');
       COMMIT;
END;
/


@..\schema_body
@..\csrimp\imp_body
@..\aggregate_ind_pkg
@..\aggregate_ind_body
@..\deleg_plan_pkg
@..\deleg_plan_body
@..\delegation_body

@update_tail