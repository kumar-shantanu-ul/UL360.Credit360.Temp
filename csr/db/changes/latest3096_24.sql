-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ***********************************************
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (98, 'HR integration', 'EnableHrIntegration', 'Enables/disables the HR integration.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (98, 'Enable/Disable', 0, '0=disable, 1=enable');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg
@../enable_body
@../user_profile_pkg
@../user_profile_body
@update_tail
