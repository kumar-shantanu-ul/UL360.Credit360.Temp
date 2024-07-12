-- Please update version.sql too -- this keeps clean builds in sync
define version=2923
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
DROP TABLE csr.issue_type_state_perm;
DROP TABLE csr.issue_custom_field_state_perm;
DROP TABLE csr.issue_state;
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
DROP VIEW csr.v$issue_type_perm_default;
DROP VIEW csr.v$issue_type_perm;
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg;
@../audit_body;
@../issue_pkg;
@../issue_body;
@../quick_survey_body;
@update_tail

