-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=11
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

INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
VALUES (56, 'Company Self Registration', 'EnableCompanySelfReg', 'Enables chain company self registration. Chain must already be enabled.', 0);

-- ** New package grants **

-- *** Packages ***

@..\campaign_body

@..\chain\setup_pkg
@..\chain\setup_body

@..\enable_pkg
@..\enable_body


@update_tail
