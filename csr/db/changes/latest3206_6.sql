-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=6
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
@../../../aspen2/db/utils_pkg
@../../../aspen2/db/utils_body

@../compliance_library_report_body
@../compliance_register_report_body

@update_tail
