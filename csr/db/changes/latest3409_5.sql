-- Please update version.sql too -- this keeps clean builds in sync
define version=3409
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

UPDATE aspen2.application SET branding_service_enabled = 1
WHERE branding_service_css IS NOT NULL;

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

@update_tail
