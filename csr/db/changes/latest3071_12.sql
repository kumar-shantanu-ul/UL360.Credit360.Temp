-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\testdata_pkg

@..\testdata_body
@..\quick_survey_body
@..\alert_body
@..\chain\chain_body
@..\csr_app_body

@update_tail
