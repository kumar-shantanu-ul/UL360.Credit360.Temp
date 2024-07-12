-- Please update version.sql too -- this keeps clean builds in sync
define version=3138
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT, REFERENCES ON aspen2.translation_set TO surveys;
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
