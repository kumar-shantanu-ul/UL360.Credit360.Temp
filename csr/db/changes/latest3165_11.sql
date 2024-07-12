-- Please update version.sql too -- this keeps clean builds in sync
define version=3165
define minor_version=11
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

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (102, 'Chain SRM activities', 'EnableChainActivities', 'Enable SRM activities. This feature is only available for supply chain sites.', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\enable_pkg
@..\enable_body

@update_tail
