-- Please update version.sql too -- this keeps clean builds in sync
define version=3345
define minor_version=6
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
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (113, 'Credential Management', 'EnableCredentialManagement', 'Enable Credential Management page.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (113, 'Menu Position', 1, '-1=end, or 1 based position');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
