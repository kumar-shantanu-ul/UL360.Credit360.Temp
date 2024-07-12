-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.survey_section ADD insert_page_break NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_INSERT_PAGE_BREAK_0_1 CHECK (insert_page_break IN (0,1));
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_TITLE_PAGE_BREAK_0_1 CHECK (hide_title * insert_page_break = 0);

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
