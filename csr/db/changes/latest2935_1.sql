-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, insert, update, delete on csrimp.issue_custom_field_date_val to web_user;
grant select, insert, update, delete on csrimp.quick_survey_css to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csrimp\imp_body

@update_tail
