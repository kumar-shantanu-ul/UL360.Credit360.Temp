-- Please update version.sql too -- this keeps clean builds in sync
define version=3362
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
INSERT INTO csr.module (module_id, module_name, enable_sp, description, warning_msg, license_warning)
VALUES (119, 'Framework Disclosures', 'EnableFrameworkDisclosures', 'Enable the new frameworks disclosures module', 'WARNING: Under development. Do not use on customer sites.', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail
