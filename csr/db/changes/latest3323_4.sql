-- Please update version.sql too -- this keeps clean builds in sync
define version=3323
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
DELETE FROM csr.module WHERE module_id = 75;

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (112, 'Amfori Integration', 'EnableAmforiIntegration', 'Enable Amfori Integration', 1);	
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg

@../audit_body
@../enable_body

@update_tail
