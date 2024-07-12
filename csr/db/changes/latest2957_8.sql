-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=8
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
@..\audit_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\chain\filter_pkg
@..\chain\company_filter_pkg

@..\quick_survey_body
@..\audit_body
@..\audit_report_body
@..\non_compliance_report_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\..\..\aspen2\cms\db\pivot_body

@update_tail
