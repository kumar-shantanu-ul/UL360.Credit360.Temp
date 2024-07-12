-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=13
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
--@../surveys/question_library_report_pkg

--@../surveys/question_library_report_body
--@../surveys/campaign_body

@update_tail
