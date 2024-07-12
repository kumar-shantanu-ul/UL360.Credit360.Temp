-- Please update version.sql too -- this keeps clean builds in sync
define version=1269
@update_header

CREATE SEQUENCE CSR.FLOW_STATE_LOG_FILE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;


CREATE TABLE CSR.FLOW_STATE_LOG_FILE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_LOG_FILE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_LOG_ID         NUMBER(10, 0)    NOT NULL,
    FILENAME                  VARCHAR2(255)    NOT NULL,
    MIME_TYPE                 VARCHAR2(256)    NOT NULL,
    DATA                      BLOB             NOT NULL,
    SHA1                      RAW(20)          NOT NULL,
    UPLOADED_DTM              DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_FLOW_STATE_LOG_FILE PRIMARY KEY (APP_SID, FLOW_STATE_LOG_FILE_ID)
);

ALTER TABLE CSR.FLOW_STATE_LOG_FILE ADD CONSTRAINT FK_FSL_FS_LOG_FILE
    FOREIGN KEY (APP_SID, FLOW_STATE_LOG_ID)
    REFERENCES CSR.FLOW_STATE_LOG(APP_SID, FLOW_STATE_LOG_ID);


ALTER TABLE CMS.TAB_COLUMN ADD (
	FULL_TEXT_INDEX_NAME	VARCHAR2(255)
);

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'cms.SyncFullTextIndexes',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'cms.tab_pkg.SyncFullTextIndexes;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise CMS full text indexes');
       COMMIT;
END;
/

ALTER TABLE CSR.ISSUE ADD (PARENT_ID NUMBER(10));

CREATE INDEX CSR.IDX_ISSUE_PARENT_ID ON CSR.ISSUE(APP_SID, PARENT_ID);

ALTER TABLE CSR.ISSUE ADD CONSTRAINT FK_ISSUE_ISSUE
    FOREIGN KEY (APP_SID, PARENT_ID)
    REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID);


CREATE OR REPLACE VIEW csr.v$simple_issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.parent_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
	   END is_overdue,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected
  FROM csr.issue i;


ALTER TABLE CSR.ISSUE_TYPE ADD (ALLOW_CHILDREN	NUMBER(1) DEFAULT 0 NOT NULL);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
	