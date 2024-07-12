
-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE SURVEYS.SURVEY_RESPONSE_SEQ;
CREATE SEQUENCE SURVEYS.RESPONSE_SUBMISSION_SEQ;
CREATE SEQUENCE SURVEYS.SURVEY_ANSWER_SEQ;

ALTER TABLE SURVEYS.QUESTION ADD (
	DELETED_DTM						DATE NULL,
	CONSTRAINT CHK_QUEST_DELETED_0_1 CHECK ((MATRIX_PARENT_ID IS NULL AND DELETED_DTM IS NULL) OR (MATRIX_PARENT_ID IS NOT NULL AND (DELETED_DTM IS NULL OR DELETED_DTM IS NOT NULL)))
);

ALTER TABLE SURVEYS.SURVEY_SECTION_QUESTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SSQ_DELETED_0_1 CHECK (DELETED IN (0,1))
);

ALTER TABLE SURVEYS.SURVEY_SECTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_SS_DELETED_0_1 CHECK (DELETED IN (0,1))
);

ALTER TABLE SURVEYS.QUESTION_OPTION ADD (
	DELETED						NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QO_DELETED_0_1 CHECK (DELETED IN (0,1))
);

CREATE TABLE SURVEYS.ANSWER(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_ID 					NUMBER(10, 0) 	NOT NULL,
	SUBMISSION_ID 				NUMBER(10, 0) 	NOT NULL,
	QUESTION_ID 				NUMBER(10, 0) 	NOT NULL,
	QUESTION_VERSION 			NUMBER(10, 0) 	NOT NULL,
	QUESTION_DRAFT				NUMBER(1)		DEFAULT 1 NOT NULL,
	QUESTION_OPTION_ID 			NUMBER(10, 0) 	NULL,
	REPEAT_INDEX 				NUMBER(10, 0) 	NULL,
	BOOLEAN_VALUE 				NUMBER(1) 		NULL,
	NUMERIC_VALUE 				NUMBER		 	NULL,
	TEXT_VALUE_SHORT 			VARCHAR2(4000)  NULL,
	TEXT_VALUE_LONG 			CLOB			NULL,
	DATE_VALUE					DATE 			NULL,
	CONSTRAINT PK_SURVEY_ANSWER PRIMARY KEY (APP_SID, ANSWER_ID, SUBMISSION_ID),
	CONSTRAINT CHK_ANSWER_BOOLEAN_VALUE CHECK (BOOLEAN_VALUE IN (0,1)),
	CONSTRAINT CHK_SURVEY_ANSWER_VALUE CHECK ((TEXT_VALUE_SHORT IS NOT NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NOT NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NOT NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NOT NULL AND DATE_VALUE IS NULL)
									OR (TEXT_VALUE_SHORT IS NULL AND TEXT_VALUE_LONG IS NULL AND BOOLEAN_VALUE IS NULL AND NUMERIC_VALUE IS NULL AND DATE_VALUE IS NOT NULL))
);

ALTER TABLE SURVEYS.ANSWER ADD 
	CONSTRAINT UK_ANSWER_SUBMISSION UNIQUE (APP_SID, SUBMISSION_ID, QUESTION_ID)
;

ALTER TABLE SURVEYS.ANSWER MODIFY QUESTION_DRAFT DEFAULT NULL;

CREATE TABLE SURVEYS.RESPONSE(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION				NUMBER(10, 0)	NOT NULL,
	RESPONSE_ID 				NUMBER(10, 0)   NOT NULL,
	CONSTRAINT PK_SURVEY_RESPONSE PRIMARY KEY (APP_SID, RESPONSE_ID)
)
;

ALTER TABLE SURVEYS.RESPONSE ADD
	CREATED_BY_USER_SID 		NUMBER(10, 0)	NULL
;

ALTER TABLE SURVEYS.RESPONSE ADD
	LATEST_SUBMISSION_ID		NUMBER(10, 0)	NULL
;

ALTER TABLE SURVEYS.RESPONSE ADD
	DRAFT		NUMBER(1)		NULL
;

BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE SURVEYS.RESPONSE
	   SET CREATED_BY_USER_SID = 3
	 WHERE CREATED_BY_USER_SID IS NULL;

	UPDATE SURVEYS.RESPONSE
	   SET DRAFT = 1
	 WHERE DRAFT IS NULL;
END;
/

ALTER TABLE SURVEYS.RESPONSE MODIFY CREATED_BY_USER_SID NOT NULL;
ALTER TABLE SURVEYS.RESPONSE MODIFY DRAFT NOT NULL;

CREATE TABLE SURVEYS.RESPONSE_SUBMISSION(
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	RESPONSE_ID					NUMBER(10) NOT NULL,
	SUBMISSION_ID				NUMBER(10) NOT NULL,
	SUBMITTED_DTM				DATE,
	SUBMITTED_BY_USER_SID		NUMBER(10),
	CONSTRAINT PK_SURVEY_RESPONSE_SUBMISSION PRIMARY KEY (APP_SID, SUBMISSION_ID)
)
;

-- Alter tables
ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN MATCH_EVERY_CATEGORY;
ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN COMMENTS_DISPLAY_TYPE;

ALTER TABLE SURVEYS.QUESTION_VERSION ADD DEFAULT_DATE_VALUE DATE;

-- FKs onto RESPONSE_SUBMISSION
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_SUBMISSION_ANSWER
	FOREIGN KEY (APP_SID, SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION(APP_SID, SUBMISSION_ID)
;

-- FKs onto SURVEY_VERSION
ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_SURVEY
	FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION(APP_SID, SURVEY_SID, SURVEY_VERSION)
;

-- FKs to QUESTION_VERSION
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_ANSWER_QUESTION_VERSION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION(APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;

-- FKs to QUESTION_OPTION
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_ANSWER_Q_OPTION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_OPTION(APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
;

-- FKs to RESPONSE
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD CONSTRAINT FK_SUBMISSION_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;

ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_SUBMISSION
	FOREIGN KEY (APP_SID, LATEST_SUBMISSION_ID)
	REFERENCES SURVEYS.RESPONSE_SUBMISSION (APP_SID, SUBMISSION_ID)
;

-- new section simple info text general setting
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD SIMPLE_INFO_TEXT VARCHAR2(4000);

-- SURVEYS.SURVEY_SECTION_TR label was the wrong data type (varchar not varchar2)
-- changing to be nullable - as section title is not mandatory
ALTER TABLE SURVEYS.SURVEY_SECTION_TR ADD LABEL_X VARCHAR2(1024);
UPDATE SURVEYS.SURVEY_SECTION_TR set LABEL_X = LABEL;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR DROP COLUMN LABEL;
ALTER TABLE SURVEYS.SURVEY_SECTION_TR RENAME COLUMN LABEL_X TO LABEL;

DROP SEQUENCE SURVEYS.SURVEY_SECTION_ID_SEQ;
DROP SEQUENCE SURVEYS.SURVEY_QUESTION_ID_SEQ;

-- *** Grants ***
grant select, references ON csr.csr_user TO surveys;

-- ** Cross schema constraints ***
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD CONSTRAINT FK_SUBMISSION_USER
	FOREIGN KEY (APP_SID, SUBMITTED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE SURVEYS.RESPONSE ADD CONSTRAINT FK_RESPONSE_CREATED_USER
	FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

CREATE INDEX surveys.ix_response_created_by_us ON surveys.response (app_sid, created_by_user_sid);
CREATE INDEX surveys.ix_response_subm_submitted_by_ ON surveys.response_submission (app_sid, submitted_by_user_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.detailed_help_link, qv.action
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid
	  WHERE q.matrix_parent_id is null;

CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments,
		qv.detailed_help_link, qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft;

-- *** Data changes ***
-- RLS

-- Data

UPDATE surveys.question_type
   SET question_type = 'fileupload',
       label = 'File upload'
 WHERE question_type = 'files'
;

UPDATE surveys.question_type
   SET question_type = 'matrixsimple',
       label = 'Simple matrix'
 WHERE question_type = 'matrix'
;

UPDATE surveys.question_type
   SET question_type = 'matrixrow',
       label = 'Matrix row'
 WHERE question_type = 'radiorow'
;

DELETE FROM surveys.question_type WHERE question_type = 'slider';

DECLARE
	v_class_id 		security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	

	BEGIN
		security.class_pkg.CreateClass(
			in_act_id			=> v_act,
			in_parent_class_id	=> NULL,
			in_class_name		=> 'QuestionLibrary',
			in_helper_pkg		=> NULL,
			in_helper_prog_id	=> NULL,
			out_class_id		=> v_class_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_class_id := security.class_pkg.GetClassID('QuestionLibrary');
	END;

	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 65536, -- question_library_pkg.PERMISSION_APPROVE_QUESTION
			in_permission_name		=> 'Approve question'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;

	security.user_pkg.LogOff(v_act);
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.integration_api_pkg AS END;
/
GRANT EXECUTE ON csr.integration_api_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
--@..\surveys\survey_pkg
--@..\surveys\survey_body
--@..\surveys\question_library_pkg
--@..\surveys\question_library_body
--@..\surveys\question_library_report_body

@..\integration_api_pkg
@..\chain\company_user_pkg

@..\enable_body
@..\permission_body
@..\integration_api_body
@..\enable_body
@..\chain\company_user_body

@update_tail
