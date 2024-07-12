-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.integration_question_answer ADD questionnaire_name VARCHAR2(255);
ALTER TABLE csrimp.integration_question_answer ADD questionnaire_name VARCHAR2(255);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../integration_question_answer_pkg

@../schema_body
@../integration_question_answer_body
@../integration_question_answer_report_body
@../csrimp/imp_body

@update_tail
