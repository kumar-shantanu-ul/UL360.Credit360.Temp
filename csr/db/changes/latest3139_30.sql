-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.answer_custom_option DROP CONSTRAINT fk_aqo_question_version;

ALTER TABLE surveys.answer_custom_option DROP COLUMN question_id;
ALTER TABLE surveys.answer_custom_option DROP COLUMN question_draft;
ALTER TABLE surveys.answer_custom_option DROP COLUMN question_version;

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
--@../surveys/survey_pkg
--@../surveys/survey_body

@update_tail
