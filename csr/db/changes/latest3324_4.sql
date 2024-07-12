-- Please update version.sql too -- this keeps clean builds in sync
define version=3324
define minor_version=4
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

@../audit_report_pkg
@../audit_report_body
@../non_compliance_report_pkg
@../non_compliance_report_body

@update_tail
