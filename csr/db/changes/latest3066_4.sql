-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=4
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
@../chain/filter_pkg
@../../../aspen2/cms/db/filter_pkg

@../audit_report_body
@../issue_report_body
@../non_compliance_report_body
@../property_report_body
@../quick_survey_report_body
@../chain/activity_report_body
@../chain/business_rel_report_body
@../chain/company_filter_body
@../chain/product_report_body
@../../../aspen2/cms/db/filter_body

@update_tail
