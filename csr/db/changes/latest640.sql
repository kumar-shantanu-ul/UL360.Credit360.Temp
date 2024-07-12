-- Please update version.sql too -- this keeps clean builds in sync
define version=640
@update_header

CREATE OR REPLACE TYPE csr.T_CONSUMPTION_ROW AS
	OBJECT (
		POS				NUMBER(10, 0),
		START_DTM		DATE,
		END_DTM			DATE,
		CONSUMPTION		NUMBER(24, 10)
	);
/
GRANT EXECUTE ON csr.csr.T_CONSUMPTION_ROW TO PUBLIC;

CREATE OR REPLACE TYPE csr.T_CONSUMPTION_TABLE AS
	TABLE OF T_CONSUMPTION_ROW;
/

CREATE SEQUENCE csr.LIVE_DATA_DURATION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE csr.METER_RAW_DATA_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE csr.RAW_DATA_SOURCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE csr.ISSUE_METER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE csr.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;
ALTER TABLE csr.ISSUE ADD (
	ISSUE_METER_ID             NUMBER(10, 0),
    CONSTRAINT CHK_ISSUE_FKS CHECK (
	    (ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL)
		OR
		(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL)
		OR
		(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL)
		OR
		(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL)
		OR
		(ISSUE_METER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL)
		OR
		(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL)
	)
)
;

CREATE TABLE csr.ISSUE_METER(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_METER_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID        NUMBER(10, 0)    NOT NULL,
    ISSUE_DTM         DATE,
    CONSTRAINT PK914 PRIMARY KEY (APP_SID, ISSUE_METER_ID)
)
;

CREATE TABLE csr.LIVE_DATA_DURATION(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    LIVE_DATA_DURATION_ID    NUMBER(10, 0)    NOT NULL,
    DURATION                 NUMBER(10, 0),
    DESCRIPTION              VARCHAR2(256)    NOT NULL,
    IS_HOURS                 NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    IS_WEEKS                 NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    WEEK_START_DAY           NUMBER(10, 0),
    IS_MONTHS                NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    START_MONTH              NUMBER(10, 0),
    IS_SYSTEM_PERIOD         NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_MONTHS = 0 OR (IS_MONTHS = 1 AND IS_HOURS = 0 AND IS_WEEKS = 0)),
    CHECK (IS_HOURS = 0 OR (IS_HOURS  = 1 AND IS_WEEKS = 0 AND IS_MONTHS = 0)),
    CHECK (IS_WEEKS = 0 OR (IS_WEEKS = 1 AND IS_HOURS = 0 AND IS_MONTHS = 0)),
    CHECK (WEEK_START_DAY IS NULL OR IS_WEEKS = 1),
    CHECK (START_MONTH IS NULL OR IS_MONTHS = 1),
    CHECK (IS_SYSTEM_PERIOD IN (0,1)),
    CONSTRAINT PK912 PRIMARY KEY (APP_SID, LIVE_DATA_DURATION_ID)
)
;


CREATE TABLE csr.METER_LIVE_DATA(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID               NUMBER(10, 0)     NOT NULL,
    LIVE_DATA_DURATION_ID    NUMBER(10, 0)     NOT NULL,
    START_DTM                DATE              NOT NULL,
    METER_RAW_DATA_ID        NUMBER(10, 0),
    END_DTM                  DATE              NOT NULL,
    MODIFIED_DTM             DATE              DEFAULT SYSDATE NOT NULL,
    CONSUMPTION              NUMBER(24, 10),
    CONSTRAINT PK911 PRIMARY KEY (APP_SID, REGION_SID, LIVE_DATA_DURATION_ID, START_DTM)
)
;

CREATE TABLE csr.METER_RAW_DATA(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_RAW_DATA_ID     NUMBER(10, 0)    NOT NULL,
    RAW_DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    RECEIVED_DTM          DATE             NOT NULL,
    START_DTM             DATE             NOT NULL,
    END_DTM               DATE             NOT NULL,
    MIME_TYPE             VARCHAR2(256)    NOT NULL,
    DATA                  BLOB             NOT NULL,
    CONSTRAINT PK913 PRIMARY KEY (APP_SID, METER_RAW_DATA_ID)
)
;

CREATE TABLE csr.METER_RAW_DATA_SOURCE(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RAW_DATA_SOURCE_ID    NUMBER(10, 0)     NOT NULL,
    SOURCE_EMAIL          VARCHAR2(1024)    NOT NULL,
    PARSER_TYPE           VARCHAR2(256)     NOT NULL,
    CONSTRAINT PK919 PRIMARY KEY (APP_SID, RAW_DATA_SOURCE_ID)
)
;
CREATE INDEX csr.IDX_METER_LIVE_DURATION ON csr.METER_LIVE_DATA(APP_SID, REGION_SID, LIVE_DATA_DURATION_ID)
;
CREATE INDEX csr.IDX_METER_LIVE_PERIOD ON csr.METER_LIVE_DATA(APP_SID, REGION_SID, LIVE_DATA_DURATION_ID, START_DTM, END_DTM)
;
CREATE INDEX csr.IDX_METER_LIVE_REGION ON csr.METER_LIVE_DATA(APP_SID, REGION_SID)
;

ALTER TABLE csr.ISSUE ADD CONSTRAINT RefISSUE_METER2020 
    FOREIGN KEY (APP_SID, ISSUE_METER_ID)
    REFERENCES csr.ISSUE_METER(APP_SID, ISSUE_METER_ID)
;

ALTER TABLE csr.ISSUE_METER ADD CONSTRAINT RefALL_METER2021 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE csr.ISSUE_METER ADD CONSTRAINT RefCUSTOMER2022 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.LIVE_DATA_DURATION ADD CONSTRAINT RefCUSTOMER2037 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.METER_LIVE_DATA ADD CONSTRAINT RefLIVE_DATA_DURATION2023 
    FOREIGN KEY (APP_SID, LIVE_DATA_DURATION_ID)
    REFERENCES csr.LIVE_DATA_DURATION(APP_SID, LIVE_DATA_DURATION_ID)
;

ALTER TABLE csr.METER_LIVE_DATA ADD CONSTRAINT RefALL_METER2024 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE csr.METER_LIVE_DATA ADD CONSTRAINT RefMETER_RAW_DATA2031 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES csr.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

ALTER TABLE csr.METER_RAW_DATA ADD CONSTRAINT RefCUSTOMER2025 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.METER_RAW_DATA ADD CONSTRAINT RefMETER_RAW_DATA_SOURCE2032 
    FOREIGN KEY (APP_SID, RAW_DATA_SOURCE_ID)
    REFERENCES csr.METER_RAW_DATA_SOURCE(APP_SID, RAW_DATA_SOURCE_ID)
;

ALTER TABLE csr.METER_RAW_DATA_SOURCE ADD CONSTRAINT RefCUSTOMER2033 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user cuass
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+);

BEGIN
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'ISSUE_METER',
        policy_name     => 'ISSUE_METER_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );

	dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_RAW_DATA_SOURCE',
        policy_name     => 'METER_RAW_DATA_SOURCE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
        
	dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_RAW_DATA',
        policy_name     => 'METER_RAW_DATA_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
        
	dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'LIVE_DATA_DURATION',
        policy_name     => 'LIVE_DATA_DURATION_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
        
	dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_LIVE_DATA',
        policy_name     => 'METER_LIVE_DATA_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
END;
/

@../csr_data_pkg
@../issue_pkg
@../meter_monitor_pkg

@../issue_body
@../region_event_body
@../meter_monitor_body

grant execute ON csr.meter_monitor_pkg to web_user;

@update_tail
