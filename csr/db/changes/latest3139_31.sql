-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=31
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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
