-- Please update version.sql too -- this keeps clean builds in sync
define version=22
@update_header

CREATE TABLE TASK_PERIOD_OVERRIDE(
    TASK_SID             NUMBER(10, 0)    NOT NULL,
    START_DTM            DATE             NOT NULL,
    REGION_SID           NUMBER(10, 0)    NOT NULL,
    OVERRIDDEN_BY_SID    NUMBER(10, 0)    NOT NULL,
    OVERRIDDEN_DTM       DATE             NOT NULL,
    REASON               CLOB             NULL,
    CONSTRAINT PK58 PRIMARY KEY (TASK_SID, START_DTM, REGION_SID)
)
;


ALTER TABLE TASK_PERIOD_OVERRIDE ADD CONSTRAINT RefTASK_PERIOD74 
    FOREIGN KEY (TASK_SID, START_DTM, REGION_SID)
    REFERENCES TASK_PERIOD(TASK_SID, START_DTM, REGION_SID)
;

CREATE TABLE FILE_UPLOAD(
    FILE_ID      NUMBER(10, 0)    NOT NULL,
    FILE_NAME    VARCHAR2(256)    NOT NULL,
    MIME_TYPE    VARCHAR2(256)    NOT NULL,
    DATA         BLOB,
    CONSTRAINT PK60 PRIMARY KEY (FILE_ID)
)
;

CREATE TABLE TASK_FILE_UPLOAD(
    TASK_SID    NUMBER(10, 0)    NOT NULL,
    FILE_ID     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK61 PRIMARY KEY (TASK_SID, FILE_ID)
)
;

CREATE TABLE TASK_PERIOD_FILE_UPLOAD(
    TASK_SID      NUMBER(10, 0)    NOT NULL,
    START_DTM     DATE             NOT NULL,
    REGION_SID    NUMBER(10, 0)    NOT NULL,
    FILE_ID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK62 PRIMARY KEY (TASK_SID, START_DTM, REGION_SID, FILE_ID)
)
;

ALTER TABLE TASK_FILE_UPLOAD ADD CONSTRAINT RefFILE_UPLOAD79 
    FOREIGN KEY (FILE_ID)
    REFERENCES FILE_UPLOAD(FILE_ID)
;

ALTER TABLE TASK_FILE_UPLOAD ADD CONSTRAINT RefTASK80 
    FOREIGN KEY (TASK_SID)
    REFERENCES TASK(TASK_SID)
;

ALTER TABLE TASK_PERIOD_FILE_UPLOAD ADD CONSTRAINT RefFILE_UPLOAD81 
    FOREIGN KEY (FILE_ID)
    REFERENCES FILE_UPLOAD(FILE_ID)
;

ALTER TABLE TASK_PERIOD_FILE_UPLOAD ADD CONSTRAINT RefTASK_PERIOD82 
    FOREIGN KEY (TASK_SID, START_DTM, REGION_SID)
    REFERENCES TASK_PERIOD(TASK_SID, START_DTM, REGION_SID)
;

CREATE SEQUENCE FILE_UPLOAD_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CUSTOMER_OPTIONS MODIFY
	GREYOUT_UNASSOC_TASKS	NUMBER(1, 0)
;

ALTER TABLE CUSTOMER_OPTIONS ADD (
	ALLOW_PERF_OVERRIDE		NUMBER(1, 0) DEFAULT 0 NOT NULL,
    ALLOW_PARENT_OVERRIDE	NUMBER(1, 0) DEFAULT 0 NOT NULL
);

-- Grant access to the file cache
PROMPT > Enter service name (e.g. ASPEN):
connect csr/csr@&&1
grant select, references on filecache to actions;

-- Reconnect to actions
connect actions/actions@&&1

@update_tail
