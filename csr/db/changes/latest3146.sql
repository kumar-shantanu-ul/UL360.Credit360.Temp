-- Please update version.sql too -- this keeps clean builds in sync
define version=3146
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.issue_involvement DROP CONSTRAINT uk_issue_involvement;
ALTER TABLE csrimp.issue_involvement ADD CONSTRAINT uk_issue_involvement UNIQUE (csrimp_session_id, issue_id, user_sid, role_sid, company_sid);

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
@..\schema_body

@update_tail
