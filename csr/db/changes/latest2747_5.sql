-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.quick_survey_question ADD count_question NUMBER(1) NULL;
UPDATE csr.quick_survey_question SET count_question = 0 WHERE count_question IS NULL;
ALTER TABLE csr.quick_survey_question MODIFY count_question DEFAULT 0 NOT NULL;
ALTER TABLE csr.quick_survey_question ADD CONSTRAINT chk_qsq_count_question CHECK (count_question=0 OR (count_question=1 AND question_type 
	IN('note', 'date', 'number', 'radio', 'radiorow', 'regionpicker', 'files', 'rtquestion', 'slider')));

ALTER TABLE csr.quick_survey_type ADD enable_question_count NUMBER(1) NULL;
UPDATE csr.quick_survey_type SET enable_question_count = 0 WHERE enable_question_count IS NULL;
ALTER TABLE csr.quick_survey_type MODIFY enable_question_count DEFAULT 0 NOT NULL;
ALTER TABLE csr.quick_survey_type ADD CONSTRAINT chk_qst_enable_question_count CHECK (enable_question_count IN (0,1));

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD REMEMBER_ANSWER NUMBER(1) NULL;
UPDATE CSRIMP.QUICK_SURVEY_QUESTION SET REMEMBER_ANSWER = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION MODIFY REMEMBER_ANSWER NOT NULL;

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD COUNT_QUESTION NUMBER(1);
UPDATE CSRIMP.QUICK_SURVEY_QUESTION SET COUNT_QUESTION = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION MODIFY COUNT_QUESTION NOT NULL;

ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE ADD enable_question_count NUMBER(1);
UPDATE CSRIMP.QUICK_SURVEY_TYPE SET enable_question_count = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE MODIFY enable_question_count NOT NULL;

--rename temp_table to avoid open session issues
CREATE GLOBAL TEMPORARY TABLE CSR.TEMPOR_QUESTION (
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
	HAS_MAX_SCORE_EXPR		NUMBER(1),
	REMEMBER_ANSWER			NUMBER(1),
	COUNT_QUESTION			NUMBER(1)
) ON COMMIT DELETE ROWS;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../quick_survey_pkg

@../quick_survey_body
@../schema_body
@../csrimp/imp_body

@update_tail
