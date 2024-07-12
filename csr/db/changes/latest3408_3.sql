-- Please update version.sql too -- this keeps clean builds in sync
define version=3408
define minor_version=3
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
UPDATE aspen2.application
   SET branding_service_css = REGEXP_REPLACE(LOWER(branding_service_css),'api\.branding.+$', 'api.branding/published-css');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
