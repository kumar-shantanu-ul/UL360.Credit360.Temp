-- If you are getting conflicts because you've rebuild your database recently
-- then drop these first:
--
-- DROP SEQUENCE CSR.CMS_IMP_INSTANCE_ID_SEQ;
-- DROP SEQUENCE CSR.CMS_IMP_INSTANCE_STEP_ID_SEQ;
-- DROP TABLE CSR.CMS_IMP_INSTANCE_STEP_MSG;
-- DROP TABLE CSR.CMS_IMP_INSTANCE_STEP;
-- DROP TABLE CSR.CMS_IMP_INSTANCE;
-- DROP INDEX CSR.UK_CMS_IMP_CLASS;
-- DROP TABLE CSR.CMS_IMP_CLASS_STEP;
-- DROP TABLE CSR.CMS_IMP_CLASS;
-- DROP TABLE CSR.CMS_IMP_FILE_TYPE;
-- DROP TABLE CSR.CMS_IMP_PROTOCOL;
--
-- RK is going to fix up the schema

-- Please update version.sql too -- this keeps clean builds in sync
define version=2455
@update_header

/*----------------------------------------------------------------------------------
-- Create the tables etc for CMS IMP
----------------------------------------------------------------------------------*/

-- SEQUENCE: CSR.CMS_IMP_INSTANCE_ID_SEQ 
--

CREATE SEQUENCE CSR.CMS_IMP_INSTANCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- 
-- SEQUENCE: CSR.CMS_IMP_INSTANCE_STEP_ID_SEQ 
--

CREATE SEQUENCE CSR.CMS_IMP_INSTANCE_STEP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
 
-- SEQUENCE: CSR.CMS_IMP_INSTANCE_STEP_MSG_SEQ 
--

CREATE SEQUENCE CSR.CMS_IMP_INSTANCE_STEP_MSG_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- SEQUENCE: CSR.CMS_IMP_MANUAL_INSTANCE_ID_SEQ
--

CREATE SEQUENCE CSR.CMS_IMP_MANUAL_INSTANCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
	
-- 
-- TABLE: CSR.CMS_IMP_CLASS 
--

CREATE TABLE CSR.CMS_IMP_CLASS(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_CLASS_SID     NUMBER(10, 0)     NOT NULL,
    LOOKUP_KEY            VARCHAR2(255),
    LABEL                 VARCHAR2(255)     NOT NULL,
    SCHEDULE_XML          SYS.XMLType,
    LAST_SCHEDULED_DTM    DATE,
    RERUN_ASAP            NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    ABORT_ON_ERROR        NUMBER(1, 0)      NOT NULL,
    HELPER_PKG            VARCHAR2(255),
    EMAIL_ON_ERROR        VARCHAR2(2048),
    EMAIL_ON_SUCCESS      VARCHAR2(2048),
	ON_COMPLETION_SP	  VARCHAR2(255),
	ON_COMPLETION_PLUGIN  VARCHAR2(255),
    CONSTRAINT CHK_CMS_IMP_CLS_RERUN CHECK (RERUN_ASAP IN (0,1)),
    CONSTRAINT CHK_CMS_IMP_CLS_ABORT CHECK (ABORT_ON_ERROR IN (0,1)),
    CONSTRAINT PK_CMS_IMP_CLASS PRIMARY KEY (APP_SID, CMS_IMP_CLASS_SID)
);



-- 
-- TABLE: CSR.CMS_IMP_CLASS_STEP 
--

CREATE TABLE CSR.CMS_IMP_CLASS_STEP(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_CLASS_SID              NUMBER(10, 0)     NOT NULL,
    STEP_NUMBER                    NUMBER(10, 0)     NOT NULL,
    TAB_SID                        NUMBER(10, 0)     NOT NULL,
    MAPPING_XML                    SYS.XMLType       NOT NULL,
    HELPER_PKG                     VARCHAR2(255),
    DAYS_TO_RETAIN_PAYLOAD         NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    CMS_IMP_PROTOCOL_ID            NUMBER(10, 0)     NOT NULL,
    CMS_IMP_FILE_TYPE_ID           NUMBER(10, 0)     NOT NULL,
    DSV_SEPARATOR                  VARCHAR2(32),
    DSV_QUOTES_AS_LITERALS         NUMBER(1, 0),
    EXCEL_WORKSHEET_INDEX          NUMBER(10, 0),
	ALL_OR_NOTHING				   NUMBER(1, 0)		DEFAULT 0 NOT NULL,
    PAYLOAD_PATH				   VARCHAR2(1024),
	DELETE_ON_SUCCESS			   NUMBER(1, 0),
    DELETE_ON_ERROR				   NUMBER(1, 0),
    MOVE_TO_PATH_ON_SUCCESS		   VARCHAR2(1024),
    MOVE_TO_PATH_ON_ERROR		   VARCHAR2(1024),
	FTP_URL                        VARCHAR2(1024),
    FTP_SECURE_CREDS               CLOB,
    FTP_FINGERPRINT 			   VARCHAR2(1024),
	FTP_USERNAME	               VARCHAR2(256),
	FTP_PASSWORD	               VARCHAR2(256),
	FTP_PORT_NUMBER                NUMBER(10, 0),	
    FTP_FILE_MASK                  VARCHAR2(255),
    FTP_SORT_BY                    VARCHAR2(10),
	FILEDATA_SP        	           VARCHAR(255),
    CONSTRAINT CHK_CMS_IMP_CLS_STP_SEP CHECK (DSV_SEPARATOR IN ('PIPE','TAB','COMMA') OR DSV_SEPARATOR IS NULL),
    CONSTRAINT CHK_CMS_IMP_CLS_STP_QU CHECK (DSV_QUOTES_AS_LITERALS IN (0,1) OR DSV_QUOTES_AS_LITERALS IS NULL),
    CONSTRAINT CHK_CMS_IMP_CLS_STP_DS CHECK (DELETE_ON_SUCCESS IN (0,1) OR DELETE_ON_SUCCESS IS NULL),
    CONSTRAINT CHK_CMS_IMP_CLS_STP_DE CHECK (DELETE_ON_ERROR IN (0,1) OR DELETE_ON_ERROR IS NULL),
    CONSTRAINT CHK_CMS_IMP_CLS_STP_SO CHECK (FTP_SORT_BY IN ('DATE','FILENAME') OR FTP_SORT_BY IS NULL),
    CONSTRAINT PK_CMS_IMP_CLASS_STEP PRIMARY KEY (APP_SID, CMS_IMP_CLASS_SID, STEP_NUMBER)
);



-- 
-- TABLE: CSR.CMS_IMP_FILE_TYPE 
--

CREATE TABLE CSR.CMS_IMP_FILE_TYPE(
    CMS_IMP_FILE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                   VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_CMS_IMP_FILE_TYPE PRIMARY KEY (CMS_IMP_FILE_TYPE_ID)
);



-- 
-- TABLE: CSR.CMS_IMP_INSTANCE 
--

CREATE TABLE CSR.CMS_IMP_INSTANCE(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_INSTANCE_ID    NUMBER(10, 0)    NOT NULL,
    CMS_IMP_CLASS_SID      NUMBER(10, 0)    NOT NULL,
    BATCH_JOB_ID           NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_CMS_IMP_INSTANCE PRIMARY KEY (APP_SID, CMS_IMP_INSTANCE_ID),
    CONSTRAINT UK_CMS_IMP_INSTANCE  UNIQUE (APP_SID, CMS_IMP_INSTANCE_ID, CMS_IMP_CLASS_SID)
);



-- 
-- TABLE: CSR.CMS_IMP_INSTANCE_STEP 
--

CREATE TABLE CSR.CMS_IMP_INSTANCE_STEP(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_INSTANCE_STEP_ID    NUMBER(10, 0)    NOT NULL,
    CMS_IMP_INSTANCE_ID         NUMBER(10, 0)    NOT NULL,
    CMS_IMP_CLASS_SID           NUMBER(10, 0)    NOT NULL,
    STEP_NUMBER                 NUMBER(10, 0)    NOT NULL,
    STARTED_DTM                 DATE             DEFAULT SYSDATE NOT NULL,
    COMPLETED_DTM               DATE,
    RESULT                      NUMBER(10, 0),
    PAYLOAD                     BLOB,
	ERROR_PAYLOAD               BLOB,
    CONSTRAINT PK_CMS_IMP_INSTANCE_STEP PRIMARY KEY (APP_SID, CMS_IMP_INSTANCE_STEP_ID)
);



-- 
-- TABLE: CSR.CMS_IMP_INSTANCE_STEP_MSG 
--

CREATE TABLE CSR.CMS_IMP_INSTANCE_STEP_MSG(
    APP_SID                         NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_INSTANCE_STEP_MSG_ID    NUMBER(10, 0)     NOT NULL,
    CMS_IMP_INSTANCE_STEP_ID        NUMBER(10, 0)     NOT NULL,
    MESSAGE                         VARCHAR2(2048)    NOT NULL,
    SEVERITY                        VARCHAR2(1)       NOT NULL,
    CONSTRAINT CHK_CMS_IMP_INST_STP_SEV CHECK (SEVERITY IN ('X','W')),
    CONSTRAINT PK_CMS_IMP_INSTANCE_STEP_MSG PRIMARY KEY (APP_SID, CMS_IMP_INSTANCE_STEP_MSG_ID)
);


-- 
-- TABLE: CSR.CMS_IMP_RESULT 
--

CREATE TABLE CSR.CMS_IMP_RESULT(
    CMS_IMP_RESULT_ID       NUMBER(10, 0)    NOT NULL,
    LABEL                   VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_CMS_IMP_RESULT PRIMARY KEY (CMS_IMP_RESULT_ID)
);


-- 
-- TABLE: CSR.CMS_IMP_PROTOCOL 
--

CREATE TABLE CSR.CMS_IMP_PROTOCOL(
    CMS_IMP_PROTOCOL_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                  VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_CMS_IMP_PROTOCOL PRIMARY KEY (CMS_IMP_PROTOCOL_ID)
);

-- 
-- TABLE: CSR.CMS_IMP_MANUAL_INSTANCE 
--

CREATE TABLE CSR.CMS_IMP_MANUAL_INSTANCE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_MANUAL_INSTANCE_ID  NUMBER(10, 0)    NOT NULL,
    CMS_IMP_CLASS_SID           NUMBER(10, 0)    NOT NULL,
    STARTED_DTM                 DATE             DEFAULT SYSDATE NOT NULL,
    COMPLETED_DTM               DATE,
    RESULT                      NUMBER(10, 0),
	RESULT_MESSAGE 				VARCHAR2(1024),
	PAYLOAD_FILENAME			VARCHAR2(256),
    PAYLOAD                     BLOB,
    ERROR_PAYLOAD               BLOB,
    CONSTRAINT PK_CMS_IMP_MANUAL_INSTANCE PRIMARY KEY (APP_SID, CMS_IMP_MANUAL_INSTANCE_ID)
);

-- 
-- INDEX: CSR.UK_CMS_IMP_CLASS 
--

CREATE UNIQUE INDEX CSR.UK_CMS_IMP_CLASS ON CSR.CMS_IMP_CLASS(APP_SID, UPPER(LOOKUP_KEY));
 
-- 
-- TABLE: CSR.CMS_IMP_CLASS_STEP 
--

ALTER TABLE CSR.CMS_IMP_CLASS_STEP ADD CONSTRAINT FK_CMS_IMP_CLS_IMP_CLS_STP 
    FOREIGN KEY (APP_SID, CMS_IMP_CLASS_SID)
    REFERENCES CSR.CMS_IMP_CLASS(APP_SID, CMS_IMP_CLASS_SID);

ALTER TABLE CSR.CMS_IMP_CLASS_STEP ADD CONSTRAINT FK_CMS_IMP_F_TYP_CLS_STP 
    FOREIGN KEY (CMS_IMP_FILE_TYPE_ID)
    REFERENCES CSR.CMS_IMP_FILE_TYPE(CMS_IMP_FILE_TYPE_ID);

ALTER TABLE CSR.CMS_IMP_CLASS_STEP ADD CONSTRAINT FK_CMS_IMP_PRT_IMP_CLS_STP 
    FOREIGN KEY (CMS_IMP_PROTOCOL_ID)
    REFERENCES CSR.CMS_IMP_PROTOCOL(CMS_IMP_PROTOCOL_ID);
	
-- 
-- TABLE: CSR.CMS_IMP_INSTANCE 
--

ALTER TABLE CSR.CMS_IMP_INSTANCE ADD CONSTRAINT FK_BATCH_JOB_CMS_IMP_INS 
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID);

ALTER TABLE CSR.CMS_IMP_INSTANCE ADD CONSTRAINT FK_CMS_IMP_CLS_IMP_INST 
    FOREIGN KEY (APP_SID, CMS_IMP_CLASS_SID)
    REFERENCES CSR.CMS_IMP_CLASS(APP_SID, CMS_IMP_CLASS_SID);


-- 
-- TABLE: CSR.CMS_IMP_INSTANCE_STEP 
--

ALTER TABLE CSR.CMS_IMP_INSTANCE_STEP ADD CONSTRAINT FK_CMS_CLS_STP_INST_STP 
    FOREIGN KEY (APP_SID, CMS_IMP_CLASS_SID, STEP_NUMBER)
    REFERENCES CSR.CMS_IMP_CLASS_STEP(APP_SID, CMS_IMP_CLASS_SID, STEP_NUMBER);

ALTER TABLE CSR.CMS_IMP_INSTANCE_STEP ADD CONSTRAINT FK_CMS_IMP_INST_INST_STP 
    FOREIGN KEY (APP_SID, CMS_IMP_INSTANCE_ID, CMS_IMP_CLASS_SID)
    REFERENCES CSR.CMS_IMP_INSTANCE(APP_SID, CMS_IMP_INSTANCE_ID, CMS_IMP_CLASS_SID);

ALTER TABLE CSR.CMS_IMP_INSTANCE_STEP ADD CONSTRAINT FK_CMS_IMP_RES_INST_STP 
    FOREIGN KEY (RESULT)
    REFERENCES CSR.CMS_IMP_RESULT(CMS_IMP_RESULT_ID);
	
-- 
-- TABLE: CSR.CMS_IMP_INSTANCE_STEP_MSG 
--

ALTER TABLE CSR.CMS_IMP_INSTANCE_STEP_MSG ADD CONSTRAINT FK_CMS_IMP_INST_STP_MSG 
    FOREIGN KEY (APP_SID, CMS_IMP_INSTANCE_STEP_ID)
    REFERENCES CSR.CMS_IMP_INSTANCE_STEP(APP_SID, CMS_IMP_INSTANCE_STEP_ID);

-- 
-- TABLE: CSR.CMS_IMP_MANUAL_INSTANCE 
--

ALTER TABLE CSR.CMS_IMP_MANUAL_INSTANCE ADD CONSTRAINT FK_CMS_IMP_RES_MAN_INST
    FOREIGN KEY (RESULT)
    REFERENCES CSR.CMS_IMP_RESULT(CMS_IMP_RESULT_ID);
	
/*----------------------------------------------------------------------------------
-- Setup RLS
----------------------------------------------------------------------------------*/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	
	--CSR.CMS_IMP_CLASS
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_CLASS',
			policy_name     => 'CMS_IMP_CLS_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_CLASS');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_CLASS');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_CLASS as feature not enabled');
	END;
	
	--CSR.CMS_IMP_CLASS_STEP
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_CLASS_STEP',
			policy_name     => 'CMS_IMP_CLS_STP_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_CLASS_STEP');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_CLASS_STEP');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_CLASS_STEP as feature not enabled');
	END;
	
	--CSR.CMS_IMP_INSTANCE
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_INSTANCE',
			policy_name     => 'CMS_IMP_INST_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_INSTANCE');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_INSTANCE');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_INSTANCE as feature not enabled');
	END;
	
	--CSR.CMS_IMP_INSTANCE_STEP
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_INSTANCE_STEP',
			policy_name     => 'CMS_IMP_INST_STP_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_INSTANCE_STEP');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_INSTANCE_STEP');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_INSTANCE_STEP as feature not enabled');
	END;
	
	--CSR.CMS_IMP_INSTANCE_STEP_MSG
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_INSTANCE_STEP_MSG',
			policy_name     => 'CMS_IMP_INST_STP_MSG_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_INSTANCE_STEP_MSG');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_INSTANCE_STEP_MSG');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_INSTANCE_STEP_MSG as feature not enabled');
	END;
	
	--CSR.CMS_IMP_MANUAL_INSTANCE
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'CMS_IMP_MANUAL_INSTANCE',
			policy_name     => 'CMS_IMP_MAN_INST_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to CMS_IMP_MANUAL_INSTANCE');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CMS_IMP_MANUAL_INSTANCE');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for CMS_IMP_MANUAL_INSTANCE as feature not enabled');
	END;
	
END;
/	
	
/*----------------------------------------------------------------------------------
-- Insert base data
----------------------------------------------------------------------------------*/	
BEGIN

	INSERT INTO CSR.CMS_IMP_FILE_TYPE (CMS_IMP_FILE_TYPE_ID, LABEL)
		VALUES (0, 'dsv');
	INSERT INTO CSR.CMS_IMP_FILE_TYPE (CMS_IMP_FILE_TYPE_ID, LABEL)
		VALUES (1, 'excel');
	INSERT INTO CSR.CMS_IMP_FILE_TYPE (CMS_IMP_FILE_TYPE_ID, LABEL)
		VALUES (2, 'xml');
		
	INSERT INTO CSR.CMS_IMP_PROTOCOL (CMS_IMP_PROTOCOL_ID, LABEL)
		VALUES(0, 'FTP');
	INSERT INTO CSR.CMS_IMP_PROTOCOL (CMS_IMP_PROTOCOL_ID, LABEL)
		VALUES(1, 'FTPS');
	INSERT INTO CSR.CMS_IMP_PROTOCOL (CMS_IMP_PROTOCOL_ID, LABEL)
		VALUES(2, 'SFTP');
	INSERT INTO CSR.CMS_IMP_PROTOCOL (CMS_IMP_PROTOCOL_ID, LABEL)
		VALUES(3, 'DB_BLOB');
	INSERT INTO CSR.CMS_IMP_PROTOCOL (CMS_IMP_PROTOCOL_ID, LABEL)
		VALUES(4, 'LOCAL');
		
	INSERT INTO CSR.CMS_IMP_RESULT (CMS_IMP_RESULT_ID, LABEL)
		VALUES(0, 'SUCCESS');
	INSERT INTO CSR.CMS_IMP_RESULT (CMS_IMP_RESULT_ID, LABEL)
		VALUES(1, 'PARTIAL SUCCESS');
	INSERT INTO CSR.CMS_IMP_RESULT (CMS_IMP_RESULT_ID, LABEL)
		VALUES(2, 'FAILURE');
	INSERT INTO CSR.CMS_IMP_RESULT (CMS_IMP_RESULT_ID, LABEL)
		VALUES(3, 'CRITICAL FAILURE');
	INSERT INTO CSR.CMS_IMP_RESULT (CMS_IMP_RESULT_ID, LABEL)
		VALUES(4, 'NOT ATTEMPTED');
END;
/
	
/*----------------------------------------------------------------------------------
-- Create new securable object type for CMSDataImports
----------------------------------------------------------------------------------*/
	
DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRCmsDataImport', 'csr.cms_data_imp_pkg', null, v_Id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/

/*----------------------------------------------------------------------------------
-- Create the batch job type
----------------------------------------------------------------------------------*/

BEGIN
	INSERT INTO csr.batch_job_type
	  (BATCH_JOB_TYPE_ID, DESCRIPTION, SP, PLUGIN_NAME, ONE_AT_A_TIME, FILE_DATA_SP)
	VALUES
	  (13, 'Cms Data import', NULL, 'cms-data-import', 0, NULL );
END;  
/

/*----------------------------------------------------------------------------------
-- Create the new alert type
----------------------------------------------------------------------------------*/

DECLARE
	v_default_alert_frame_id		NUMBER;
	v_customer_alert_type_id		NUMBER;
	v_importcomplete_alert_type_id	NUMBER := 66;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (v_importcomplete_alert_type_id, 
		'Scheduled import completed',
		'A scheduled import has completeted',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_importcomplete_alert_type_id, 0, 'IMPORT_CLASS_LABEL', 'Import class label', 'The name/description of the import', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_importcomplete_alert_type_id, 0, 'RESULT', 'To friendly name', 'The result of the import instance', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_importcomplete_alert_type_id, 0, 'URL', 'To user name', 'A link to the full details of the import instance', 3);


	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (v_importcomplete_alert_type_id, v_default_alert_frame_id, 'automatic');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (v_importcomplete_alert_type_id, 'en',
		'<template>A scheduled import has completed</template>',
		'<template><p><mergefield name="IMPORT_CLASS_LABEL"/> import has completed with the following result;</p><p><mergefield name="RESULT"/></p>Further results can be accessed at the following page; <mergefield name="URL"/></template>', 
		'<template/>'
		);
	
END;
/

/*----------------------------------------------------------------------------------
-- Setup the schedule to create import jobs
----------------------------------------------------------------------------------*/

BEGIN

  DBMS_SCHEDULER.create_job (
    job_name        => 'CmsDataImport',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          csr.user_pkg.logonadmin();
          csr.cms_data_imp_pkg.ScheduleRun();
          commit;
          END;
    ',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=daily; byhour=2; byminute=0; bysecond=0;',
    end_date        => NULL,
    enabled         => TRUE,
    comments        => 'Cms data import schedule');

END;
/

/*----------------------------------------------------------------------------------
-- New capability
----------------------------------------------------------------------------------*/

BEGIN
	INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manually import CMS data import instances', 0);
END;
/

/*----------------------------------------------------------------------------------
-- Enable script
----------------------------------------------------------------------------------*/

BEGIN
	UPDATE csr.module
	   SET module_id = 36
	 WHERE module_name = 'Measure Conversions';

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning) VALUES (32, 'CMS data import', 'EnableCmsDataImport', 'Enables CMS data import.', 0);
END;
/

/*----------------------------------------------------------------------------------
-- Dummy the new package
----------------------------------------------------------------------------------*/

create or replace package csr.cms_data_imp_pkg as
procedure dummy;
end;
/
create or replace package body csr.cms_data_imp_pkg as
procedure dummy
as
begin
	null;
end;
end;
/


/*----------------------------------------------------------------------------------
-- Grants
----------------------------------------------------------------------------------*/

-- so we can create objects of the new type in SecMgr
grant execute on csr.cms_data_imp_pkg to security;
grant execute on csr.cms_data_imp_pkg to web_user;


/*----------------------------------------------------------------------------------
-- Packages
----------------------------------------------------------------------------------*/

@..\batch_job_pkg
@..\cms_data_imp_pkg
@..\cms_data_imp_body
@..\enable_pkg
@..\enable_body

@update_tail
