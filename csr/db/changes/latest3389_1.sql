-- Please update version.sql too -- this keeps clean builds in sync
define version=3389
define minor_version=1
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
@../audit_pkg
@../issue_pkg
@../audit_body
@../issue_body
@../quick_survey_body

@update_tail
