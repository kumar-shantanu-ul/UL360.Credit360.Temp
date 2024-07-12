-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant delete on chain.reference to CSR;
grant delete on chain.reference_capability to CSR;
grant delete on chain.company_reference to CSR;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, enable_class, description, license_warning)
VALUES (118, 'RBA Integration', 'EnableRBAIntegration', 'Credit360.Enable.EnableRBAIntegration', 'Enable RBA Integration', 1);	

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg

@../enable_body

@update_tail
