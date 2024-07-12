-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\chain\filter_pkg
@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\property_report_pkg
@..\non_compliance_report_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\audit_report_pkg

@..\chain\filter_body
@..\chain\company_filter_body
@..\chain\company_body
@..\chain\business_relationship_body
@..\chain\flow_form_body
@..\chain\report_body
@..\..\..\aspen2\cms\db\filter_body
@..\property_report_body
@..\non_compliance_report_body
@..\initiative_report_body
@..\issue_report_body
@..\audit_report_body

@update_tail
