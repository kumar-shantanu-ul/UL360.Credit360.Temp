-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.survey_section MODIFY HIDE_TITLE NUMBER(1,0);
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_SS_HIDE_TITLE_0_1 CHECK (HIDE_TITLE IN (0,1));

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

--@..\surveys\survey_pkg
--@..\surveys\survey_body

@update_tail
