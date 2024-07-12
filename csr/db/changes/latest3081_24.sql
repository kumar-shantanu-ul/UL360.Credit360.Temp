-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (97, 'API integrations', 'EnableApiIntegrations', '(In development - Dont run unless you know what you are doing!) Enables API integrations. Will create a user if the specified username doesnt exist yet');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'User name', 0, 'The name of the user the integration will connect as. If the name specified doesnt exist, it will be created (as a hidden user).');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'Client id', 1, 'A secure string for the client ID. Generate a GUID perhaps.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'Client secret', 2, 'Akin to a password. Should be kept secure. Generate a GUID perhaps.');
END;
/

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg

@../enable_body

@update_tail
