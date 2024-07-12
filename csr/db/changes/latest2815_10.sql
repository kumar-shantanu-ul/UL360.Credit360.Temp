-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=10
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
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 20);
-- ** New package grants **

-- *** Packages ***
@..\issue_body
@..\issue_report_body

@update_tail
