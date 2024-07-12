-- Please update version.sql too -- this keeps clean builds in sync
define version=387
@update_header

alter table ind add roll_forward number(1) default 0 not null;
alter table ind add constraint ck_ind_roll_forward check (roll_forward in (0,1));

insert into source_type (source_type_id, description) values (9, 'Rolled forward');

@..\csr_data_pkg
@..\indicator_pkg
@..\datasource_body
@..\vb_legacy_body
@..\range_body
@..\pending_datasource_body
@..\region_body
@..\schema_body
@..\calc_body
@..\delegation_body
@..\tag_body
@..\indicator_body
@..\pending_body

alter session set current_schema="ACTIONS";
@..\actions\project_body
@..\actions\task_body
@..\actions\ind_template_body
alter session set current_schema="CSR";
@..\..\..\aspen2\tools\recompile_packages

-- Queue a job for rolling forward value data for marked indicators
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.RollForward',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'indicator_pkg.RollForward;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MONTHLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Roll forward data for marked indicators');
       COMMIT;
END;
/

@update_tail
