-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***


-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (50, 'Emission Factor Start Date ON', 'EnableFactorStartMonth', 'Update the Emission Factor start date to match the customer reporting period start date.', 0);
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (51, 'Emission Factor Start Date OFF', 'DisableFactorStartMonth', 'Turn off the Emission Factor start date match on the customer reporting period start date.', 0);

-- ** New package grants **

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail
