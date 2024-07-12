-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=42
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
@@../compliance_body
@@../compliance_register_report_body
@@../compliance_library_report_body
@@../flow_body

@update_tail
