-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE csr.temp_question_option_show_q (
	question_id				NUMBER(10),
	question_option_id		NUMBER(10),
	show_question_id		NUMBER(10)
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE csr.quick_survey_expr MODIFY expr NULL;
ALTER TABLE csr.quick_survey_expr ADD (
	question_id						NUMBER(10),
	question_option_id				NUMBER(10),
	CONSTRAINT fk_quick_survey_expr_quest_opt 
		FOREIGN KEY (app_sid, question_id, question_option_id, survey_version)
		REFERENCES csr.qs_question_option (app_sid, question_id, question_option_id, survey_version),
	CONSTRAINT chk_qs_expr_or_question CHECK (
		(expr IS NOT NULL AND question_id IS NULL AND question_option_id IS NULL) OR 
		(expr IS NULL AND question_id IS NOT NULL AND question_option_id IS NOT NULL))	
);

CREATE UNIQUE INDEX csr.uk_quick_survey_expr_question ON csr.quick_survey_expr (app_sid, survey_sid, survey_version, NVL2(expr, expr_id, NULL), question_id, question_option_id);
CREATE INDEX csr.ix_quick_survey_expr_ques_o_id ON csr.quick_survey_expr (app_sid, question_id, question_option_id, survey_version); 

ALTER TABLE csrimp.quick_survey_expr MODIFY expr NULL;
ALTER TABLE csrimp.quick_survey_expr ADD (
	question_id						NUMBER(10),
	question_option_id				NUMBER(10),
	CONSTRAINT chk_qs_expr_or_question CHECK (
		(expr IS NOT NULL AND question_id IS NULL AND question_option_id IS NULL) OR 
		(expr IS NULL AND question_id IS NOT NULL AND question_option_id IS NOT NULL))	
);

CREATE UNIQUE INDEX csrimp.uk_quick_survey_expr_question ON csrimp.quick_survey_expr (csrimp_session_id, survey_sid, survey_version, NVL2(expr, expr_id, NULL), question_id, question_option_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../quick_survey_pkg

@../quick_survey_body
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
