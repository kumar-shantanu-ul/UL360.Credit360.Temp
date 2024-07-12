-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables 

-- Alter tables
ALTER TABLE surveys.answer ADD hidden NUMBER(1) DEFAULT 0;

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
