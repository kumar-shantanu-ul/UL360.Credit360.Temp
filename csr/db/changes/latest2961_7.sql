-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=7
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
@../audit_report_body
@../initiative_report_body
@../issue_report_body
@../meter_report_body
@../non_compliance_report_body
@../property_report_body
@../user_report_body

@update_tail
