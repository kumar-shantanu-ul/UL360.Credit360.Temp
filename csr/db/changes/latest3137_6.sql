-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
-- US7961 start
CREATE SEQUENCE surveys.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE SEQUENCE surveys.audit_log_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE TABLE SURVEYS.AUDIT_LOG_TYPE(
	AUDIT_LOG_TYPE_ID	NUMBER(10, 0) NOT NULL,
	NAME				VARCHAR2(20),
	CONSTRAINT PK_AUDIT_LOG_TYPE PRIMARY KEY (AUDIT_LOG_TYPE_ID)
);

DELETE FROM SURVEYS.AUDIT_LOG_DETAIL;
DELETE FROM SURVEYS.AUDIT_LOG;
ALTER TABLE SURVEYS.AUDIT_LOG ADD
(
	AUDIT_LOG_TYPE_ID	NUMBER(10) NOT NULL
);

CREATE TABLE SURVEYS.ANSWER_FILE(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_FILE_ID		NUMBER(10, 0)	NOT NULL,
	RESPONSE_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_ID			NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION	NUMBER(10, 0)	NOT NULL,
	FILENAME			VARCHAR2(255)	NOT NULL,
	MIME_TYPE			VARCHAR2(256)	NOT NULL,
	SHA1				RAW(20)			NOT NULL,
	CAPTION				VARCHAR2(1023),
	SURVEY_SID			NUMBER(10, 0)	NOT NULL,
	SURVEY_VERSION		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SURVEY_ANSWER_FILE PRIMARY KEY (APP_SID, ANSWER_FILE_ID),
	CONSTRAINT UK_SURVEY_ANSWER_FILE UNIQUE (APP_SID, ANSWER_FILE_ID, RESPONSE_ID),
	CONSTRAINT UK_SURVEYS_ANSWER_FILE_A UNIQUE (APP_SID, RESPONSE_ID, QUESTION_ID, SHA1, FILENAME, MIME_TYPE)
)
;

CREATE SEQUENCE SURVEYS.SURVEY_ANSWER_FILE_ID_SEQ;

CREATE INDEX SURVEYS.IX_ANS_FILE_RESP_ID ON SURVEYS.ANSWER_FILE(APP_SID, RESPONSE_ID)
;

CREATE TABLE SURVEYS.RESPONSE_FILE(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	RESPONSE_ID		NUMBER(10, 0)	NOT NULL,
	FILENAME		VARCHAR2(255)	NOT NULL,
	MIME_TYPE		VARCHAR2(256)	NOT NULL,
	DATA			BLOB			NOT NULL,
	SHA1			RAW(20)			NOT NULL,
	UPLOADED_DTM	DATE			DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_RESPONSE_FILE PRIMARY KEY (APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
)
;

CREATE INDEX SURVEYS.IX_RESP_FILE_BY_SHA1 ON SURVEYS.RESPONSE_FILE(APP_SID, SHA1, FILENAME, MIME_TYPE)
;
-- US7961 stop

-- Alter tables
ALTER TABLE surveys.question_option_data_sources DROP CONSTRAINT chk_data_source_selected_0_1;
ALTER TABLE surveys.question_option_data_sources DROP COLUMN selected;

ALTER TABLE surveys.question_version ADD (
	option_data_source_id				NUMBER(10, 0),
	CONSTRAINT fk_question_ver_data_source FOREIGN KEY (app_sid, option_data_source_id) REFERENCES surveys.question_option_data_sources(app_sid, data_source_id)
);

ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANS_FILE_QSTN_ID
	FOREIGN KEY (APP_SID, QUESTION_ID, SURVEY_SID, SURVEY_VERSION)
	REFERENCES SURVEYS.SURVEY_SECTION_QUESTION(APP_SID, QUESTION_ID, SURVEY_SID, SURVEY_VERSION)
;

ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANS_FILE_RESP_ID
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;

ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_FILE
	FOREIGN KEY (APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
	REFERENCES SURVEYS.RESPONSE_FILE(APP_SID, RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
;

ALTER TABLE SURVEYS.RESPONSE_FILE ADD CONSTRAINT FK_RESPONSE_FILE_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;

DECLARE
	v_count NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_count
	  FROM all_constraints
	 WHERE owner='SURVEYS' and (constraint_name = 'RefCUSTOMER_ANSWER_FILE')
	   AND table_name ='ANSWER_FILE';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE surveys.answer_file DROP CONSTRAINT RefCUSTOMER_ANSWER_FILE';
	END IF;
END;
/

ALTER TABLE SURVEYS.RESPONSE ADD CAMPAIGN_SENT NUMBER(1);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_CUSTOMER
	FOREIGN KEY (APP_SID)
	REFERENCES CSR.CUSTOMER(APP_SID)
;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.CREATE OR REPLACE VIEW surveys.v$question AS
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang, qv.option_data_source_id
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;

CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id
	   AND sq.question_version = qv.question_version
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;

-- *** Data changes ***
-- RLS

-- Data
-- US7961 start
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (1, 'Created');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (2, 'Updated');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (3, 'Deleted');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (4, 'Approved');
INSERT INTO SURVEYS.AUDIT_LOG_TYPE (AUDIT_LOG_TYPE_ID, NAME) VALUES (5, 'Published');
-- US7961 stop

-- ** New package grants **
create or replace package surveys.audit_pkg as end;
/
create or replace package surveys.integration_pkg as end;
/
create or replace package csr.region_api_pkg as end;
/
grant execute on surveys.audit_pkg to web_user;
grant execute on surveys.integration_pkg to web_user;
grant execute on csr.region_api_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
--@../surveys/audit_pkg
--@../surveys/survey_pkg
--@../surveys/question_library_pkg
@../region_api_pkg
--@../surveys/integration_pkg

--@../surveys/audit_body
--@../surveys/survey_body
--@../surveys/question_library_body
@../region_api_body
--@../surveys/integration_body
--@../surveys/campaign_body

@update_tail
