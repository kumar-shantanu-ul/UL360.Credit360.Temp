-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.survey_section ADD (approved NUMBER(1) DEFAULT 1 NOT NULL);
ALTER TABLE surveys.survey_section MODIFY (approved DEFAULT 0);

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
--@../surveys/question_library_pkg
--@../surveys/survey_pkg

--@../surveys/question_library_body
--@../surveys/survey_body

@update_tail
