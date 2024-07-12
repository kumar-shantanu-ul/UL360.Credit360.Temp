-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.debug_log (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	debug_log_id					NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	start_dtm						TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
	end_dtm							TIMESTAMP,
	object_id						NUMBER(10),
	CONSTRAINT pk_debug_log PRIMARY KEY (app_sid, debug_log_id)
);

CREATE TABLE chain.debug_act (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	act_id							CHAR(36) NOT NULL,
	CONSTRAINT pk_debug_act PRIMARY KEY (app_sid, act_id)
);

CREATE SEQUENCE chain.debug_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

--DROP TABLE chain.filter_cache;

CREATE TYPE CHAIN.T_FILTER_CACHE_VARRAY as VARRAY(1) of chain.T_FILTERED_OBJECT_TABLE;
/

CREATE TABLE chain.filter_cache (
	app_sid			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_sid		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	act_id			CHAR(36)   DEFAULT SYS_CONTEXT('SECURITY', 'ACT') NOT NULL,
	card_group_id	NUMBER(10) NOT NULL,
	expire_dtm		DATE NOT NULL,
	cms_col_sid		NUMBER(10),
	cached_rows		CHAIN.T_FILTER_CACHE_VARRAY
);

CREATE UNIQUE INDEX chain.uk_filter_cache ON chain.filter_cache(app_sid, card_group_id, user_sid, act_id, cms_col_sid);
CREATE INDEX chain.ix_filter_cache_expry ON chain.filter_cache(expire_dtm);
CREATE INDEX chain.ix_filter_cache_user ON chain.filter_cache(user_sid);

CREATE TABLE aspen2.request_queue (	
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	user_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	act_id							CHAR(36)   DEFAULT SYS_CONTEXT('SECURITY', 'ACT') NOT NULL,
	last_active_dtm					TIMESTAMP  DEFAULT SYSTIMESTAMP NOT NULL,
	guid							VARCHAR2(36) NOT NULL,
	active_request_number			NUMBER(10) NOT NULL,
	CONSTRAINT pk_request_queue PRIMARY KEY (app_sid, guid)
);

CREATE INDEX aspen2.ix_request_queue_active_dtm ON aspen2.request_queue (last_active_dtm);

-- Alter tables
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD 
	FILTER_CACHE_TIMEOUT NUMBER(10) DEFAULT 600 NOT NULL;

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS ADD 
	FILTER_CACHE_TIMEOUT NUMBER(10);

UPDATE CSRIMP.CHAIN_CUSTOMER_OPTIONS
   SET FILTER_CACHE_TIMEOUT = 600
 WHERE FILTER_CACHE_TIMEOUT IS NULL;

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS MODIFY
	FILTER_CACHE_TIMEOUT NOT NULL;


-- *** Grants ***
GRANT SELECT, REFERENCES ON chain.debug_log TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW chain.v$debug_log AS
	SELECT app_sid, debug_log_id, end_dtm - start_dtm duration, label, object_id, start_dtm, end_dtm
	  FROM chain.debug_log
	 ORDER BY debug_log_id DESC;

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'ASPEN2',
			object_name     => 'REQUEST_QUEUE',
			policy_name     => 'REQUEST_QUEUE_POLICY',
			function_schema => 'ASPEN2',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
	EXCEPTION
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
	END;
END;
/

-- Data
DECLARE
    job BINARY_INTEGER;
BEGIN
	FOR r IN (
		SELECT job_name FROM all_scheduler_jobs WHERE UPPER(job_name) = UPPER('ExpireRequestQueue') AND OWNER = UPPER('aspen2')
	)
	LOOP
		DBMS_SCHEDULER.DROP_JOB('aspen2.ExpireRequestQueue', TRUE);
	END LOOP;
	
	DBMS_SCHEDULER.CREATE_JOB (
		job_name             => 'aspen2.ExpireRequestQueue',
		job_type             => 'PLSQL_BLOCK',
		job_action           => 'request_queue_pkg.ExpireRequestQueue;',
		job_class            => 'low_priority_job',
		repeat_interval      => 'FREQ=HOURLY',
		enabled              => TRUE,
		auto_drop            => FALSE,
		start_date           => TO_DATE('2000-01-01 00:25:00','yyyy-mm-dd hh24:mi:ss'),
		comments             => 'Expire old requests in the request queue');    

	COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every 10 minutes
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.RunFilterExpiry',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'filter_pkg.RemoveExpiredCaches;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=10',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Triggers job for running chain jobs');
       COMMIT;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE aspen2.request_queue_pkg AS
	PROCEDURE Dummy;
END;
/
grant execute on aspen2.request_queue_pkg to web_user;
grant execute on aspen2.request_queue_pkg to cms, chain, csr;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/setup_pkg
@../../../aspen2/cms/db/filter_pkg
@../../../aspen2/db/request_queue_pkg
@../audit_pkg
@../csr_data_pkg

@../chain/filter_body
@../chain/setup_body
@../../../aspen2/cms/db/filter_body
@../../../aspen2/db/request_queue_body
@../audit_report_body
@../initiative_report_body
@../issue_report_body
@../meter_report_body
@../non_compliance_report_body
@../property_report_body
@../user_report_body
@../chain/company_filter_body
@../schema_body
@../region_body
@../role_body
@../flow_body
@../csr_user_body
@../issue_body
@../issue_report_body
@../audit_body
@../non_compliance_report_body
@../audit_report_body
@../csrimp/imp_body

@update_tail
