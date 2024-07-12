-- Please update version.sql too -- this keeps clean builds in sync
define version=1855
@update_header

-- Default surveys in audit types

@..\audit_pkg
@..\audit_body

-- Mobile form paths for incident types
DECLARE
	v_column_exists number;
BEGIN
	SELECT count(*) INTO v_column_exists
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='INCIDENT_TYPE' AND column_name='MOBILE_LIST_PATH';

	IF (v_column_exists = 0) THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.INCIDENT_TYPE ADD ( MOBILE_LIST_PATH varchar(2000), MOBILE_EDIT_PATH varchar(2000), MOBILE_NEW_CASE_PATH varchar(2000) )';
	END IF;
END;
/

grant execute on cms.util_pkg to csr;

@..\..\..\aspen2\cms\db\util_pkg
@..\..\..\aspen2\cms\db\util_body

@..\incident_pkg
@..\incident_body

-- Quick Survey Scoring Expressions

ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD (
	DONT_NORMALISE_SCORE	NUMBER(1)	DEFAULT 0 NOT NULL,
	HAS_SCORE_EXPRESSION	NUMBER(1)	DEFAULT 0 NOT NULL,
	HAS_MAX_SCORE_EXPR		NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QSQ_DNT_NORM_SC_0_1 CHECK (DONT_NORMALISE_SCORE IN (0,1)),
	CONSTRAINT CHK_QSQ_HAS_SC_EXPR_0_1 CHECK (HAS_SCORE_EXPRESSION IN (0,1)),
	CONSTRAINT CHK_QSQ_MAX_SC_EXPR_0_1 CHECK (HAS_MAX_SCORE_EXPR IN (0,1))
);

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD (
	DONT_NORMALISE_SCORE	NUMBER(1)	NOT NULL,
	HAS_SCORE_EXPRESSION	NUMBER(1)	NOT NULL,
	HAS_MAX_SCORE_EXPR		NUMBER(1)	NOT NULL,
	CONSTRAINT CHK_QSQ_DNT_NORM_SC_0_1 CHECK (DONT_NORMALISE_SCORE IN (0,1)),
	CONSTRAINT CHK_QSQ_HAS_SC_EXPR_0_1 CHECK (HAS_SCORE_EXPRESSION IN (0,1)),
	CONSTRAINT CHK_QSQ_MAX_SC_EXPR_0_1 CHECK (HAS_MAX_SCORE_EXPR IN (0,1))
);

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD (
	WEIGHT_OVERRIDE			NUMBER(15,5)
);

ALTER TABLE CSRIMP.QUICK_SURVEY_ANSWER ADD (
	WEIGHT_OVERRIDE			NUMBER(15,5)
);

DROP TABLE CSR.TEMP_QUESTION;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_QUESTION (
	QUESTION_ID				NUMBER(10),
	PARENT_ID				NUMBER(10),
	POS						NUMBER(10),
	LABEL					VARCHAR2(4000),
	QUESTION_TYPE			VARCHAR2(40),
	SCORE					NUMBER(13,3),
	MAX_SCORE				NUMBER(13,3),
	UPLOAD_SCORE			NUMBER(13,3),
	LOOKUP_KEY				VARCHAR2(255),
	INVERT_SCORE			VARCHAR2(255),
	CUSTOM_QUESTION_TYPE_ID	NUMBER(10),
	WEIGHT					NUMBER(15,5),
	DONT_NORMALISE_SCORE	NUMBER(1),
	HAS_SCORE_EXPRESSION	NUMBER(1),
	HAS_MAX_SCORE_EXPR		NUMBER(1)
) ON COMMIT DELETE ROWS;

-- Quick Survey Carry Forward Answers Update

ALTER TABLE csr.qs_campaign ADD carry_forward_answers NUMBER(1);
UPDATE csr.qs_campaign SET carry_forward_answers = 0;
ALTER TABLE csr.qs_campaign MODIFY carry_forward_answers NUMBER(1) DEFAULT 0;

ALTER TABLE csr.qs_submission_file
DROP CONSTRAINT FK_QS_SUBMSN_FILE_FILE;

ALTER TABLE csr.qs_answer_file
ADD CONSTRAINT UK_QS_ANSWER_FILE UNIQUE (app_sid, qs_answer_file_id, survey_response_id);

ALTER TABLE csr.qs_submission_file ADD CONSTRAINT FK_QS_SUBMSN_FILE_FILE 
FOREIGN KEY (app_sid, qs_answer_file_id, survey_response_id)
REFERENCES csr.qs_answer_file(app_sid, qs_answer_file_id, survey_response_id);

ALTER TABLE csrimp.qs_campaign ADD carry_forward_answers NUMBER(1);

-- End Quick Survey Carry Forward Answers Update

@..\quick_survey_pkg
@..\campaign_pkg
@..\quick_survey_body
@..\issue_body
@..\csrimp\imp_body
@..\campaign_body

@update_tail