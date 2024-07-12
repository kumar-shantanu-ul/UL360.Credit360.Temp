define version=91
@update_header

DROP TABLE chain.TASK_FILE;

/*******************************************************************
	CREATE NEW OBJECTS
*******************************************************************/

CREATE SEQUENCE chain.TASK_TYPE_ID_SEQ
    START WITH 1000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.TASK_ENTRY(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TASK_ENTRY_ID           NUMBER(10, 0)    NOT NULL,
    TASK_ID                 NUMBER(10, 0)    NOT NULL,
    TASK_ENTRY_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    NAME                    VARCHAR2(30),
    LAST_MODIFIED_DTM       TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    LAST_MODIFIED_BY_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CONSTRAINT CHK_TASK_ENTRY_NAME_IS_LOWER CHECK (NAME IS NULL OR NAME = LOWER(TRIM(NAME))),
    CONSTRAINT PK67 PRIMARY KEY (APP_SID, TASK_ENTRY_ID)
)
;

CREATE TABLE chain.TASK_ENTRY_DATE(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TASK_ENTRY_ID    NUMBER(10, 0)    NOT NULL,
    DTM              TIMESTAMP(6),
    CONSTRAINT PK332 PRIMARY KEY (APP_SID, TASK_ENTRY_ID)
)
;

CREATE TABLE chain.TASK_ENTRY_FILE(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TASK_ENTRY_ID      NUMBER(10, 0)    NOT NULL,
    FILE_UPLOAD_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK325 PRIMARY KEY (APP_SID, TASK_ENTRY_ID, FILE_UPLOAD_SID)
)
;

CREATE TABLE chain.TASK_ENTRY_NOTE(
    APP_SID          NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TASK_ENTRY_ID    NUMBER(10, 0)     NOT NULL,
    TEXT             VARCHAR2(4000),
    CONSTRAINT PK333 PRIMARY KEY (APP_SID, TASK_ENTRY_ID)
)
;

CREATE TABLE chain.TASK_ENTRY_TYPE(
    TASK_ENTRY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK69 PRIMARY KEY (TASK_ENTRY_TYPE_ID)
)
;

CREATE TABLE chain.TASK_ACTION(
    TASK_ACTION_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION       VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK328 PRIMARY KEY (TASK_ACTION_ID)
)
;

CREATE TABLE chain.TASK_ACTION_LOOKUP(
    TASK_ACTION_ID         NUMBER(10, 0)    NOT NULL,
    FROM_TASK_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    TO_TASK_STATUS_ID      NUMBER(10, 0)    NOT NULL
)
;

CREATE TABLE chain.TASK_ACTION_TRIGGER(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TASK_TYPE_ID           NUMBER(10, 0)    NOT NULL,
    ON_TASK_ACTION_ID      NUMBER(10, 0)    NOT NULL,
    TRIGGER_TASK_ACTION_ID NUMBER(10, 0)    NOT NULL,
    TRIGGER_TASK_NAME      VARCHAR2(30)     NOT NULL,
    POSITION               NUMBER(10, 0)    NOT NULL,
    CONSTRAINT CHK_TAT_TRIGGER_NAME_IS_LOWER CHECK (TRIGGER_TASK_NAME = LOWER(TRIM(TRIGGER_TASK_NAME)))
)
;

CREATE TABLE chain.TASK_ACTION_TRIGGER_TRANSITION(
    TASK_ACTION_ID         NUMBER(10, 0)    NOT NULL,
    FROM_TASK_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    TO_TASK_STATUS_ID      NUMBER(10, 0)    NOT NULL
)
;


CREATE OR REPLACE TYPE chain.T_TASK_ACTION_ROW AS 
  OBJECT ( 
	ON_TASK_ACTION			NUMBER(10),
	TRIGGER_TASK_ACTION		NUMBER(10),
	TRIGGER_TASK_NAME		VARCHAR2(30)
  );
/

CREATE OR REPLACE TYPE chain.T_TASK_ACTION_LIST AS 
  TABLE OF chain.T_TASK_ACTION_ROW;
/

/*******************************************************************
	ALTER TABLES
*******************************************************************/

ALTER TABLE chain.TASK_TYPE ADD (
	NAME                   VARCHAR2(30),
	DEFAULT_TASK_STATUS_ID NUMBER(10, 0)    DEFAULT 0 NOT NULL,
	POSITION			   NUMBER(10) DEFAULT 0 NOT NULL,
	CARD_ID				   NUMBER(10),
	CONSTRAINT CHK_TASK_TYPE_NAME_IS_LOWER CHECK (NAME = LOWER(TRIM(NAME)))
);

ALTER TABLE chain.TASK ADD (
	LAST_TASK_STATUS_ID     NUMBER(10, 0),
	CONSTRAINT CHK_TASK_STATUS_NOT_VIRTUAL CHECK (TASK_STATUS_ID >= 0),
	CONSTRAINT CHK_LAST_STATUS_NOT_VIRTUAL CHECK (LAST_TASK_STATUS_ID >= 0 OR LAST_TASK_STATUS_ID IS NULL)    
);

ALTER TABLE chain.TASK_TYPE DROP COLUMN HELPER_FUNCTION;

ALTER TABLE chain.TASK DROP CONSTRAINT RefCHAIN_USER254;
ALTER TABLE chain.TASK DROP CONSTRAINT RefCHAIN_USER255;

ALTER TABLE chain.TASK DROP COLUMN CREATED_DTM;
ALTER TABLE chain.TASK DROP COLUMN CREATED_BY_SID;


/*******************************************************************
	FIXUP DATA / CREATE BASE DATA
*******************************************************************/

UPDATE default_message_definition SET helper_pkg = NULL;

UPDATE chain.task_type SET name = LOWER('checkSupplierData') WHERE task_type_id = 1;
UPDATE chain.task_type SET name = LOWER('discussConcerns') WHERE task_type_id = 2;
UPDATE chain.task_type SET name = LOWER('getCsrAuditReport') WHERE task_type_id = 3;
UPDATE chain.task_type SET name = LOWER('selfAssessment') WHERE task_type_id = 4;
UPDATE chain.task_type SET name = LOWER('verifyCsrProgram') WHERE task_type_id = 5;
UPDATE chain.task_type SET name = LOWER('initiateCsrAudit') WHERE task_type_id = 6;
UPDATE chain.task_type SET name = LOWER('establishAuditImprovementPlan') WHERE task_type_id = 7;
UPDATE chain.task_type SET name = LOWER('ammendContract') WHERE task_type_id = 8;
UPDATE chain.task_type SET name = LOWER('estabishSupplyContract') WHERE task_type_id = 9;
UPDATE chain.task_type SET name = LOWER('flagConcerns') WHERE task_type_id = 11;
UPDATE chain.task_type SET name = LOWER('establishSelfImprovmentPlan') WHERE task_type_id = 12;

UPDATE chain.task_type
   SET name = 'tasktype'||task_type_id,
       default_task_status_id = 7 -- pending
 WHERE name IS NULL;
 
UPDATE chain.task_type
   SET position = task_type_id;

UPDATE chain.task_type
   SET db_class = SUBSTR(db_class, 1, LENGTH(db_class) - LENGTH('.UpdateTask'))
 WHERE SUBSTR(db_class, LENGTH(db_class) - LENGTH('.UpdateTask') + 1) = '.UpdateTask';

/*****************************************************
	TASK STATUS
*****************************************************/
INSERT INTO chain.task_status (task_status_id, description) 
VALUES (-2, 'Reset to the default status for the task type');

INSERT INTO chain.task_status (task_status_id, description) 
VALUES (-1, 'Revert the status to the task.last_status_id');

INSERT INTO chain.task_status (task_status_id, description) 
VALUES (0, 'Hidden');	

-- clean up unused status
DELETE FROM chain.task_status
 WHERE task_status_id IN (1, 2, 4, 5);

/*****************************************************
	TASK ENTRY TYPE
*****************************************************/	

INSERT INTO chain.task_entry_type (task_entry_type_id, description) VALUES (1, 'timestamp');
INSERT INTO chain.task_entry_type (task_entry_type_id, description) VALUES (2, 'note');
INSERT INTO chain.task_entry_type (task_entry_type_id, description) VALUES (3, 'file');

/*****************************************************
	TASK ACTION
*****************************************************/

INSERT INTO chain.task_action (task_action_id, description) VALUES (1, 'Open a task');
INSERT INTO chain.task_action (task_action_id, description) VALUES (2, 'Close a task');
INSERT INTO chain.task_action (task_action_id, description) VALUES (3, 'Remove a task');
INSERT INTO chain.task_action (task_action_id, description) VALUES (4, 'N/A a task');
INSERT INTO chain.task_action (task_action_id, description) VALUES (11, 'Revert task open');
INSERT INTO chain.task_action (task_action_id, description) VALUES (12, 'Revert task close');
INSERT INTO chain.task_action (task_action_id, description) VALUES (13, 'Rever task remove');
INSERT INTO chain.task_action (task_action_id, description) VALUES (14, 'Revert task N/A');

/*****************************************************
	TASK ACTION LOOKUP
*****************************************************/

-- ON_OPEN_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 0, 3);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 7, 3);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 8, 3);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 9, 3);
-- ON_REVERT_OPEN_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (11, 3, 0);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (11, 3, 7);
-- ON_CLOSE_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 0, 6);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 7, 6);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 8, 6);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 3, 6);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 9, 6);
-- ON_REVERT_CLOSE_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (12, 6, 0);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (12, 6, 7);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (12, 6, 3);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (12, 6, 9);
-- ON_REMOVE_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 0, 8);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 3, 8);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 6, 8);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 7, 8);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 9, 8);
-- ON_REVERT_REMOVE_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 0);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 3);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 6);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 7);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 8);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, 9);
-- ON_NA_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 0, 9);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 7, 9);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 8, 9);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 3, 9);
-- ON_REVERT_NA_TASK lookups
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (14, 9, 0);
INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id) VALUES (14, 9, 7);

/*****************************************************
	TASK ACTION TRIGGER TRANSITION
*****************************************************/	

-- OPEN_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 0, 3);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 7, 3);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 8, 3);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (1, 9, 3);
-- REVERT_OPEN_TASK transitions 
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (11, 3, -2);
-- CLOSE_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 0, 6);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 3, 6);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 7, 6);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 8, 6);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (2, 9, 6);
-- REVERT_CLOSE_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (12, 6, 3);
-- REMOVE_TASK transitions 
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 0, 8);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 3, 8);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 6, 8);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 7, 8);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (3, 9, 8);
-- REVERT_REMOVE_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (13, 8, -1);
-- NA_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 0, 9);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 7, 9);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 8, 9);
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (4, 3, 9);
-- REVERT_NA_TASK transitions
INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id) VALUES (14, 9, -2);


/*******************************************************************
	MODIFY NULLABLES
*******************************************************************/

ALTER TABLE chain.TASK_TYPE MODIFY NAME NOT NULL;

/*******************************************************************
	CREATE INDICES
*******************************************************************/

CREATE UNIQUE INDEX chain.UNIQUE_NAMED_TASK_ENTRY ON chain.TASK_ENTRY(APP_SID, TASK_ID, NAME)
;

CREATE UNIQUE INDEX chain.UNIQUE_TASK_TYPE_NAME ON chain.TASK_TYPE(APP_SID, NAME, TASK_SCHEME_ID)
;

CREATE UNIQUE INDEX chain.UNIQUE_TASK_SUP_REL ON chain.TASK(APP_SID, TASK_TYPE_ID, OWNER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

/*******************************************************************
	ADD CONSTRAINTS
*******************************************************************/

ALTER TABLE chain.TASK ADD CONSTRAINT RefTASK_STATUS834 
    FOREIGN KEY (LAST_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ENTRY ADD CONSTRAINT RefTASK_ENTRY_TYPE841 
    FOREIGN KEY (TASK_ENTRY_TYPE_ID)
    REFERENCES chain.TASK_ENTRY_TYPE(TASK_ENTRY_TYPE_ID)
;

ALTER TABLE chain.TASK_ENTRY ADD CONSTRAINT RefCUSTOMER_OPTIONS842 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.TASK_ENTRY_DATE ADD CONSTRAINT RefTASK_ENTRY843 
    FOREIGN KEY (APP_SID, TASK_ENTRY_ID)
    REFERENCES chain.TASK_ENTRY(APP_SID, TASK_ENTRY_ID)
;

ALTER TABLE chain.TASK_ENTRY_FILE ADD CONSTRAINT RefTASK_ENTRY844 
    FOREIGN KEY (APP_SID, TASK_ENTRY_ID)
    REFERENCES chain.TASK_ENTRY(APP_SID, TASK_ENTRY_ID)
;

ALTER TABLE chain.TASK_ENTRY_FILE ADD CONSTRAINT RefFILE_UPLOAD845 
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES chain.FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
;

ALTER TABLE chain.TASK_ENTRY_NOTE ADD CONSTRAINT RefTASK_ENTRY846 
    FOREIGN KEY (APP_SID, TASK_ENTRY_ID)
    REFERENCES chain.TASK_ENTRY(APP_SID, TASK_ENTRY_ID)
;

ALTER TABLE chain.TASK_TYPE ADD CONSTRAINT RefCARD819 
    FOREIGN KEY (CARD_ID)
    REFERENCES chain.CARD(CARD_ID)
;

ALTER TABLE chain.TASK_TYPE ADD CONSTRAINT RefTASK_STATUS835 
    FOREIGN KEY (DEFAULT_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ACTION_LOOKUP ADD CONSTRAINT RefTASK_STATUS854 
    FOREIGN KEY (FROM_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ACTION_LOOKUP ADD CONSTRAINT RefTASK_STATUS855 
    FOREIGN KEY (TO_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ACTION_LOOKUP ADD CONSTRAINT RefTASK_ACTION856 
    FOREIGN KEY (TASK_ACTION_ID)
    REFERENCES chain.TASK_ACTION(TASK_ACTION_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER ADD CONSTRAINT RefTASK_ACTION857 
    FOREIGN KEY (ON_TASK_ACTION_ID)
    REFERENCES chain.TASK_ACTION(TASK_ACTION_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER ADD CONSTRAINT RefTASK_ACTION858 
    FOREIGN KEY (TRIGGER_TASK_ACTION_ID)
    REFERENCES chain.TASK_ACTION(TASK_ACTION_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER ADD CONSTRAINT RefTASK_TYPE859 
    FOREIGN KEY (APP_SID, TASK_TYPE_ID)
    REFERENCES chain.TASK_TYPE(APP_SID, TASK_TYPE_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER_TRANSITION ADD CONSTRAINT RefTASK_STATUS860 
    FOREIGN KEY (FROM_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER_TRANSITION ADD CONSTRAINT RefTASK_STATUS861 
    FOREIGN KEY (TO_TASK_STATUS_ID)
    REFERENCES chain.TASK_STATUS(TASK_STATUS_ID)
;

ALTER TABLE chain.TASK_ACTION_TRIGGER_TRANSITION ADD CONSTRAINT RefTASK_ACTION862 
    FOREIGN KEY (TASK_ACTION_ID)
    REFERENCES chain.TASK_ACTION(TASK_ACTION_ID)
;

ALTER TABLE chain.TASK ADD CONSTRAINT RefCHAIN_USER254 
    FOREIGN KEY (APP_SID, LAST_UPDATED_BY_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

BEGIN
	INSERT INTO chain.card_group
	(card_group_id, name, description)
	VALUES
	(19, 'Task Manager', 'Manages Card Tasks');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

/*******************************************************************
	COMPILE PACKAGES
*******************************************************************/

@..\chain_pkg
@..\chain_link_pkg
@..\card_pkg
@..\task_pkg
@..\questionnaire_pkg

@..\chain_link_body
@..\card_body
@..\task_body
@..\company_body
@..\dashboard_body
@..\dev_body
@..\message_body
@..\questionnaire_body
@..\company_user_body

@update_tail

