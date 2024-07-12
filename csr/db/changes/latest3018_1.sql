-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

alter table csr.batch_job_type add max_concurrent_jobs number(10);
alter table csr.batch_job add priority number(10) default 1 not null;
alter table csr.batch_job rename column one_at_a_time to in_order;
alter table csr.batch_job_type rename column one_at_a_time to in_order;
alter table csr.batch_job add ram_usage number(20) default null;
alter table csr.batch_job add cpu_ms number(20) default null;
alter table csr.batch_job_type add ram_estimate number(20) default null;
alter table csr.batch_job_Type add priority number(10) default 1 not null;

create index ix_batch_job_completed_dtm on csr.batch_job (completed_dtm);

alter table csr.batch_job drop constraint CK_BATCH_JOB_ONE_AT_A_TIME;
alter table csr.batch_job add CONSTRAINT CK_BATCH_JOB_IN_ORDER CHECK (IN_ORDER IN (0, 1));

alter table csr.batch_job_type drop constraint CK_BATCH_JOB_TYPE_ONE_AT_TIME;
alter table csr.batch_job_type add CONSTRAINT CK_BATCH_JOB_TYPE_IN_ORDER CHECK (IN_ORDER IN (0, 1));

CREATE TABLE CSR.BATCH_JOB_TYPE_APP_CFG
(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_TYPE_ID				NUMBER(10) NOT NULL,
	RAM_ESTIMATE					NUMBER(20),
	PRIORITY						NUMBER(10),
	MAX_CONCURRENT_JOBS				NUMBER(10),
	CONSTRAINT PK_BATCH_JOB_TYPE_APP_CFG PRIMARY KEY (APP_SID, BATCH_JOB_TYPE_ID)
);
	
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG ADD
	CONSTRAINT FK_BJT_APP_CFG_CUSTOMER FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER (APP_SID);
	
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG ADD
	CONSTRAINT FK_BJT_APP_CFG_BJT FOREIGN KEY (BATCH_JOB_TYPE_ID)
	REFERENCES CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID);

CREATE TABLE CSR.BATCH_JOB_TYPE_APP_STAT
(
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_TYPE_ID				NUMBER(10) NOT NULL,
	RAM_MAX							NUMBER(20),
	RAM_AVG							NUMBER(20),
	CPU_MAX_MS						NUMBER(20),
	CPU_AVG_MS						NUMBER(20),
	RUN_TIME_MAX					NUMBER(20),
	RUN_TIME_AVG					NUMBER(20),
	START_DELAY_MAX					NUMBER(20),
	START_DELAY_AVG					NUMBER(20),
	CONSTRAINT PK_BATCH_JOB_TYPE_APP_STAT PRIMARY KEY (APP_SID, BATCH_JOB_TYPE_ID)
);

ALTER TABLE CSR.BATCH_JOB_TYPE_APP_STAT ADD CONSTRAINT FK_BJT_APP_STAT_CUSTOMER
FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER (APP_SID);

ALTER TABLE CSR.BATCH_JOB_TYPE_APP_STAT ADD 	CONSTRAINT FK_BJT_APP_STAT_BJT
FOREIGN KEY (BATCH_JOB_TYPE_ID) REFERENCES CSR.BATCH_JOB_TYPE
(BATCH_JOB_TYPE_ID);

create index csr.ix_bjt_app_cfg_bjt on csr.batch_job_type_app_cfg (batch_job_type_id);
create index csr.ix_bjt_app_stat_bjt on csr.batch_job_type_app_stat (batch_job_type_id);

CREATE TABLE CSR.BATCH_JOB_NOTIFY (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL, 
	BATCH_JOB_ID 					NUMBER(10) NOT NULL,
	CONSTRAINT PK_BATCH_JOB_NOTIFY_TABLE PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

CREATE MATERIALIZED VIEW LOG ON CSR.BATCH_JOB_NOTIFY;
GRANT CREATE TABLE TO CSR;
CREATE MATERIALIZED VIEW CSR.V$BATCH_JOB_NOTIFY BUILD IMMEDIATE REFRESH FAST ON COMMIT AS
	SELECT APP_SID, BATCH_JOB_ID
	  FROM CSR.BATCH_JOB_NOTIFY;
REVOKE CREATE TABLE FROM CSR;

ALTER TABLE CSR.BATCH_JOB_NOTIFY ADD CONSTRAINT
	FK_BATCH_JOB_NOTIFY_CUSTOMER FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER (APP_SID);

begin
execute immediate
'CREATE OR REPLACE TRIGGER csr.batch_job_notify_trigger
	AFTER INSERT ON csr.v$batch_job_notify
BEGIN
	csr.batch_job_pk' ||'g.TriggerRun(0);
END;';
end;
/

begin
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', 'localhost:0', 'listen,resolve' );
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '255.255.255.255:899', 'connect,resolve' );
end;
/

DECLARE
	v_enqueue_options				dbms_aq.enqueue_options_t;
	v_message_properties			dbms_aq.message_properties_t;
	v_message_handle				RAW(16);
BEGIN
	DBMS_AQADM.STOP_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE (
		queue_name  => 'csr.batch_job_queue'
	);
	DBMS_AQADM.DROP_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue'
	);
	COMMIT;
END;
/

-- job to mark batch jobs as failed
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.MarkFailedBatchJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.MarkFailedJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=3',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Mark batch jobs as failed (if they have failed)');
END;
/

-- job for adding batch job stats
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.BatchJobStats',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.ComputeJobStats;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 01:43 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Compute aggregate batch job stats');
       COMMIT;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name)
VALUES (54, 'Eat RAM', 'eat-ram');

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_trigger
@../batch_job_pkg
@../batch_job_body
@../auto_approve_body
@../csr_app_body

@update_tail
