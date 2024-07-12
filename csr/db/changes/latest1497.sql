-- Please update version.sql too -- this keeps clean builds in sync
define version=1497
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Auto Approve Valid Delegation', 0);

CREATE TABLE CSR.DELEGATION_AUTOMATIC_APPROVAL(
    APP_SID           NUMBER(10, 0)    NOT NULL,--DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DUE_DATE_OFFSET   NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_DELEGAA PRIMARY KEY (APP_SID)
);

CREATE TABLE CSR.SHEET_AUTOMATIC_APPROVAL(
    APP_SID           NUMBER(10, 0)    NOT NULL,--DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BATCH_JOB_ID      NUMBER(10, 0)    NOT NULL,
    SHEET_ID          NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEETAA PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

ALTER TABLE CSR.SHEET_AUTOMATIC_APPROVAL ADD CONSTRAINT FK_SHEETAA_BATCHJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;

ALTER TABLE CSR.SHEET_AUTOMATIC_APPROVAL ADD CONSTRAINT FK_SHEETAA_SHEET
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;

ALTER TABLE CSR.SHEET_AUTOMATIC_APPROVAL ADD CONSTRAINT FK_SHEETAA_USER
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.SHEET ADD(
    AUTOMATIC_APPROVAL_DTM        DATE DEFAULT NULL,
    AUTOMATIC_APPROVAL_STATUS     CHAR DEFAULT 'P'
)
;

ALTER TABLE CSR.SHEET
ADD CONSTRAINT CK_AASTATUS
  CHECK (AUTOMATIC_APPROVAL_STATUS IN ('P', 'Q', 'A', 'R'));

INSERT INTO CSR.batch_job_type VALUES (3, 'Auto approve sheet', null, 'auto-approve-run');

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		  job_name            => 'csr.EnqueueAutoApprove',
		  job_type            => 'PLSQL_BLOCK',
		  job_action          => 'BEGIN csr.auto_approve_pkg.EnqueueAutoApproveSheets; END;',
		  job_class           => 'low_priority_job',
		  repeat_interval     => 'FREQ=HOURLY',
		  enabled             => FALSE,
		  auto_drop           => FALSE,
		  start_date          => TO_DATE('2000-01-01 01:30:00','yyyy-mm-dd hh24:mi:ss'),
		  comments            => 'Find sheets that can be auto approved and enqueue them for batch job');  
END;
/

CREATE OR REPLACE PACKAGE CSR.auto_approve_pkg
AS
END;
/

grant execute on csr.auto_approve_pkg to web_user;

@../batch_job_pkg
@../auto_approve_pkg
@../auto_approve_body

@update_tail
