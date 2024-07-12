-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=8
@update_header

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

-- *** DDL ***
-- Create tables
BEGIN
	FOR r IN (
		SELECT 	table_name
		  FROM all_tables
		 WHERE owner = 'CSR' 
		   AND table_name IN('USER_COURSE', 'USER_COURSE_LOG', 'FLOW_STATE_NATURE', 'TEMP_USER_COURSE_FILTER')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CSR.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/

CREATE TABLE CSR.USER_COURSE (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	USER_SID				NUMBER(10) NOT NULL,
	COURSE_ID				NUMBER(10) NOT NULL,
	VALID					NUMBER(1) DEFAULT 0 NOT NULL,
	RESCHEDULE_DUE			NUMBER(1) DEFAULT 0 NOT NULL,
	COMPLETED_DTM			DATE,
	SCORE					NUMBER(5, 2),
	EXPIRY_DTM				DATE,
	EXPIRY_NOTICE_DTM		DATE,
	EXPIRY_NOTICE_SENT		NUMBER(1) DEFAULT 0 NOT NULL,
	ESCALATION_NOTICE_DTM	DATE,
	ESCALATION_NOTICE_SENT	NUMBER(1) DEFAULT 0 NOT NULL,
	RESCHEDULE_DTM			DATE,
	SCHEDULE_COURSE			NUMBER(1) DEFAULT 0 NOT NULL,
	COURSE_SCHEDULE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_USER_COURSE PRIMARY KEY (APP_SID, USER_SID, COURSE_ID)
);

CREATE TABLE CSR.USER_COURSE_LOG (
	USER_COURSE_LOG_ID		NUMBER(10) NOT NULL,
	APP_SID					NUMBER(10) NOT NULL,
	USER_SID				NUMBER(10) NOT NULL,
	COURSE_ID				NUMBER(10) NOT NULL,
	LOG_DTM					DATE,
	COMPLETED_DTM			DATE,
	EXPIRED_DTM				DATE,
	SCORE					NUMBER(5, 2),
	CONSTRAINT PK_USER_COURSE_LOG PRIMARY KEY (APP_SID, USER_COURSE_LOG_ID)
);

CREATE TABLE CSR.FLOW_STATE_NATURE (
	FLOW_STATE_NATURE_ID	NUMBER(10) NOT NULL,
	LABEL					VARCHAR2(64) NOT NULL,
	FLOW_ALERT_CLASS    	VARCHAR2(256) NOT NULL,
	CONSTRAINT PK_FLOW_STATE_NATURE PRIMARY KEY (FLOW_STATE_NATURE_ID)
);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_USER_COURSE_FILTER
(
APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
TRAINEE_SID				NUMBER(10),
COURSE_ID				NUMBER(10),
TITLE					VARCHAR2(100),
TRAINING_PRIORITY_ID	NUMBER(10),
TRAINING_PRIORITY_POS	NUMBER(2),
FLOW_ITEM_ID			NUMBER(10),
FLOW_STATE_ID			NUMBER(10)
) ON COMMIT DELETE ROWS;

-- CREATE SEQUENCES
BEGIN
	FOR r IN (
		SELECT sequence_name
		  FROM all_sequences
		 WHERE sequence_name = 'USER_COURSE_LOG_ID_SEQ'
		   AND sequence_owner = UPPER('CSR')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP SEQUENCE CSR.'||r.sequence_name;
	END LOOP;
END;
/

CREATE SEQUENCE CSR.USER_COURSE_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- Merged in from Dan. Need to review his changes
DROP TYPE CSR.T_FLOW_STATE_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_ROW AS
	OBJECT (
		XML_POS					NUMBER(10),	
		POS						NUMBER(10), 
		ID						NUMBER(10), 
		LABEL					VARCHAR2(255), 
		LOOKUP_KEY				VARCHAR2(255),
		IS_FINAL				NUMBER(1),
		STATE_COLOUR			NUMBER(10),
		EDITABLE_ROLE_SIDS		VARCHAR2(2000),
		NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
		EDITABLE_COL_SIDS		VARCHAR2(2000),
		NON_EDITABLE_COL_SIDS	VARCHAR2(2000),
		INVOLVED_TYPE_IDS		VARCHAR2(2000),
		ATTRIBUTES_XML			XMLType,
		FLOW_STATE_NATURE_ID	NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/
-- END: Merged in from Dan

-- DROP TYPE CSR.T_TRAINING_FLOW_STATE_TABLE;
-- DROP TYPE CSR.T_TRAINING_FLOW_STATE_ROW;

-- DROP TYPE CSR.T_TRAINING_USER_COURSE_TABLE;
-- DROP TYPE CSR.T_TRAINING_USER_COURSE_ROW;

CREATE OR REPLACE TYPE CSR.T_TRAINING_FLOW_STATE_ROW AS 
	OBJECT ( 
	FLOW_STATE_ID			NUMBER(10),
	FLOW_SID				NUMBER(10),
	LABEL					VARCHAR2(255),
	LOOKUP_KEY				VARCHAR2(255),
	FLOW_STATE_NATURE_ID	NUMBER(10),
	POS						NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_TRAINING_FLOW_STATE_TABLE AS 
	TABLE OF CSR.T_TRAINING_FLOW_STATE_ROW;
/

CREATE OR REPLACE TYPE CSR.T_TRAINING_USER_COURSE_ROW AS 
	OBJECT ( 
		APP_SID 	NUMBER(10,0),
		USER_SID 	NUMBER(10,0),
		COURSE_ID	NUMBER(10,0)
	);
/

CREATE OR REPLACE TYPE CSR.T_TRAINING_USER_COURSE_TABLE AS 
	TABLE OF CSR.T_TRAINING_USER_COURSE_ROW;
/
-- Alter tables

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'TRAINING_PRIORITY'
	   AND column_name = 'POS';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.TRAINING_PRIORITY ADD POS NUMBER(2)';
	END IF;
END;
/

UPDATE csr.training_priority SET pos = 2 WHERE training_priority_id = 1;
UPDATE csr.training_priority SET pos = 1 WHERE training_priority_id = 2;

DECLARE
	v_nullable	VARCHAR2(1);
BEGIN
	SELECT nullable INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'TRAINING_PRIORITY'
	   AND column_name = 'POS';
	IF v_nullable = 'Y' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.training_priority MODIFY pos NOT NULL';
	END IF;
END;
/

DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'TRAINING_PRIORITY'
	   AND constraint_name = 'UK_TRAINING_PRIORITY';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.training_priority ADD CONSTRAINT UK_TRAINING_PRIORITY UNIQUE (pos)';
	END IF;
END;
/

-- ADD FLOW_STATE_NATURE_ID TO FLOW_STATE
DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'FLOW_STATE'
	   AND column_name = 'FLOW_STATE_NATURE_ID';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_STATE ADD FLOW_STATE_NATURE_ID NUMBER(10)';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_STATE ADD CONSTRAINT FK_FLOW_STATE_NATURE FOREIGN KEY (FLOW_STATE_NATURE_ID) REFERENCES CSR.FLOW_STATE_NATURE(FLOW_STATE_NATURE_ID)';
	END IF;
END;
/

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(column_name) INTO v_check
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'T_FLOW_STATE'
	   AND column_name = 'FLOW_STATE_NATURE_ID';

	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.T_FLOW_STATE ADD FLOW_STATE_NATURE_ID NUMBER(10)';
	END IF;
END;
/

-- USER_COURSE
ALTER TABLE CSR.USER_COURSE ADD CONSTRAINT FK_USER_COURSE_COURSE
	FOREIGN KEY (APP_SID, COURSE_ID) 
	REFERENCES CSR.COURSE(APP_SID, COURSE_ID);

ALTER TABLE CSR.USER_COURSE ADD CONSTRAINT FK_USER_COURSE_USER
	FOREIGN KEY (APP_SID, USER_SID) 
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

-- FK_USER_COURSE_TRAINING added below to avoid errorss

-- USER_COURSE_LOG
ALTER TABLE CSR.USER_COURSE_LOG ADD CONSTRAINT FK_USER_COURSE_LOG
	FOREIGN KEY (APP_SID, USER_SID, COURSE_ID) 
	REFERENCES CSR.USER_COURSE(APP_SID, USER_SID, COURSE_ID);

-- FLOW_STATE_NATURE
ALTER TABLE CSR.FLOW_STATE_NATURE ADD CONSTRAINT FK_FLOW_STATE_NATURE_CLASS
	FOREIGN KEY (FLOW_ALERT_CLASS) 
	REFERENCES CSR.FLOW_ALERT_CLASS(FLOW_ALERT_CLASS);

-- Some varchars are way too small
BEGIN
	FOR r IN (
		SELECT 	table_name, column_name, data_type, data_length
		  FROM all_tab_columns
		 WHERE owner = 'CSR' 
		   AND table_name IN ('TEMP_COURSE', 'TEMP_COURSE_SCHEDULE')
		   AND column_name = 'TITLE'
		   AND data_length < 100
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.' || r.table_name || ' MODIFY TITLE VARCHAR2(100)';
	END LOOP;
END;
/

-- ADD COURSE_ID (not null) TO USER_TRAINING AND ADD TO FK FROM COURSE_SCHEDULE
DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(column_name)
	  INTO v_check
	  FROM all_tab_columns
	 WHERE OWNER = 'CSR'
	   AND TABLE_NAME = 'USER_TRAINING'
	   AND COLUMN_NAME = 'COURSE_ID';
	
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.USER_TRAINING ADD COURSE_ID NUMBER(10)';
	END IF;
END;
/

UPDATE csr.user_training ut
   SET ut.course_id = (SELECT course_id FROM csr.course_schedule cs WHERE cs.course_schedule_id = ut.course_schedule_id)
 WHERE ut.course_id IS NULL;

DECLARE
	v_nullable	VARCHAR2(1);
BEGIN
	SELECT nullable INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'USER_TRAINING'
	   AND column_name = 'COURSE_ID';
	IF v_nullable = 'Y' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.user_training MODIFY course_id NOT NULL';
	END IF;
END;
/

DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'COURSE_SCHEDULE'
	   AND constraint_name = 'UK_COURSE_SCHEDULE';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.course_schedule ADD CONSTRAINT UK_COURSE_SCHEDULE UNIQUE (APP_SID, COURSE_SCHEDULE_ID, COURSE_ID)';
	END IF;
END;
/

-- ALTER CONSTRAINTS ON csr.user_training

ALTER TABLE csr.user_training DROP CONSTRAINT FK_USER_TRAINING_SCHEDULE;

ALTER TABLE csr.user_training ADD CONSTRAINT FK_USER_TRAINING_SCHEDULE
	FOREIGN KEY (app_sid, course_schedule_id, course_id) 
	REFERENCES csr.course_schedule(app_sid, course_schedule_id, course_id);

ALTER TABLE csr.user_training DROP CONSTRAINT PK_USER_TRAINING;

ALTER TABLE csr.user_training ADD CONSTRAINT PK_USER_TRAINING
	PRIMARY KEY (app_sid, user_sid, course_schedule_id, course_id);
	
DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'USER_TRAINING'
	   AND constraint_name = 'UK_USER_TRAINING';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.user_training ADD CONSTRAINT UK_USER_TRAINING UNIQUE (FLOW_ITEM_ID)';
	END IF;
END;
/

-- ADD THIS CONSTRAINT IN NOW AFTER FIXING UP THE PK ON USER_TRAINING
ALTER TABLE CSR.USER_COURSE ADD CONSTRAINT FK_USER_COURSE_TRAINING
	FOREIGN KEY (APP_SID, USER_SID, COURSE_SCHEDULE_ID, COURSE_ID) 
	REFERENCES CSR.USER_TRAINING(APP_SID, USER_SID, COURSE_SCHEDULE_ID, COURSE_ID);		
	
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
CREATE OR REPLACE VIEW csr.v$training_flow_item AS
     SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, 
			ut.user_sid,
			f.label flow_label,
			fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
			fs.state_colour current_state_colour,
			fs.is_deleted flow_state_is_deleted,
			fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
			fi.survey_response_id, fi.dashboard_instance_id,
			fs.flow_state_nature_id,
			fsn.label flow_state_nature,
			ut.course_id,
			ut.course_schedule_id
       FROM flow_item fi
	   JOIN flow f ON fi.flow_sid = f.flow_sid
	   JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
	   JOIN user_training ut ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
  LEFT JOIN flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id;

CREATE OR REPLACE VIEW csr.v$training_line_manager AS  
	SELECT c.app_sid, c.course_id, c.course_type_id, ur.parent_user_sid line_manager_sid, ur.child_user_sid trainee_sid
	  FROM course c
	  JOIN course_type ct
			 ON ct.app_sid = c.app_sid
			AND ct.course_type_id = c.course_type_id
	 JOIN user_relationship ur
			 ON ur.app_sid = ct.app_sid
			AND ur.user_relationship_type_id = ct.user_relationship_type_id;

CREATE OR REPLACE VIEW csr.v$training_flow_item AS
     SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, 
			ut.user_sid,
			f.label flow_label,
			fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
			fs.state_colour current_state_colour,
			fs.is_deleted flow_state_is_deleted,
			fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
			fi.survey_response_id, fi.dashboard_instance_id,
			fs.flow_state_nature_id,
			fsn.label flow_state_nature,
			ut.course_id,
			ut.course_schedule_id
       FROM flow_item fi
	   JOIN flow f ON fi.flow_sid = f.flow_sid
	   JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
	   JOIN user_training ut ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
  LEFT JOIN flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id;

CREATE OR REPLACE VIEW csr.v$training_line_manager AS  
	SELECT c.app_sid, c.course_id, c.course_type_id, ur.parent_user_sid line_manager_sid, ur.child_user_sid trainee_sid
	  FROM course c
	  JOIN course_type ct
			 ON ct.app_sid = c.app_sid
			AND ct.course_type_id = c.course_type_id
	 JOIN user_relationship ur
			 ON ur.app_sid = ct.app_sid
			AND ur.user_relationship_type_id = ct.user_relationship_type_id;

-- *** Data changes ***
-- RLS

-- Data
UPDATE CSR.flow_alert_class SET helper_pkg = 'CSR.TRAINING_FLOW_HELPER_PKG' WHERE flow_alert_class = 'training';

BEGIN
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (0, 'training', 'Unscheduled');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (1, 'training', 'Unapproved');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (2, 'training', 'Approved / Confirmed');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (3, 'training', 'Post-attendance');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (4, 'training', 'Deleted');
END;
/


INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (76, 'Training Module', 'EnableTraining', 'Enables the training module');

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.training_flow_helper_pkg AS END;
/

GRANT EXECUTE ON csr.training_flow_helper_pkg TO web_user;

-- *** Packages ***
@../csr_data_pkg
@../flow_pkg
@../training_pkg
@../training_flow_helper_pkg
@../enable_pkg

@../flow_body
@../training_body
@../training_flow_helper_body
@../enable_body


@update_tail
