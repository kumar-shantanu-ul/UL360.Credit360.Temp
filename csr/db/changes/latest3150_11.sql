-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE surveys.survey_section ADD HIDE_TITLE NUMBER(1) DEFAULT 0 NOT NULL;

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
