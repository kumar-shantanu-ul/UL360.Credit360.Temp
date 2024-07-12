-- Please update version.sql too -- this keeps clean builds in sync
define version=3374
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (120, 'Integration Question Answer API', 'EnableIntegrationQuestionAnswerApi', 'Enable Integration Question Answer API');

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
@../enable_pkg
@../integration_question_answer_pkg
@../enable_body
@../integration_question_answer_body
@update_tail
