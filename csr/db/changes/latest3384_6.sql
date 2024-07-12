-- Please update version.sql too -- this keeps clean builds in sync
define version=3384
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.integration_question_answer RENAME COLUMN answer TO answer_old;
ALTER TABLE csr.integration_question_answer ADD answer CLOB;
UPDATE csr.integration_question_answer
   SET answer = answer_old;
ALTER TABLE csr.integration_question_answer DROP COLUMN answer_old;

ALTER TABLE csrimp.integration_question_answer RENAME COLUMN answer TO answer_old;
ALTER TABLE csrimp.integration_question_answer ADD answer CLOB;
UPDATE csrimp.integration_question_answer
   SET answer = answer_old;
ALTER TABLE csrimp.integration_question_answer DROP COLUMN answer_old;

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
@../integration_question_answer_report_pkg

@../integration_question_answer_body
@../integration_question_answer_report_body
@../schema_body
@../csrimp/imp_body


@update_tail
