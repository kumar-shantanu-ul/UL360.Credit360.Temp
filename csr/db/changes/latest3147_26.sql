-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE surveys.response DROP COLUMN x_survey_version CASCADE CONSTRAINTS;

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
--@../surveys/survey_body
--@../surveys/question_library_body

@update_tail
