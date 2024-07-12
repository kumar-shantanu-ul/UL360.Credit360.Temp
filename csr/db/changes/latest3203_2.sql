-- Please update version.sql too -- this keeps clean builds in sync
define version=3203
define minor_version=2
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
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (107, 'Create OWL client', 'CreateOwlClient', 'Creates the site you are logged in to as an OWL client.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_admin_access', 'Admin access (Y/N)', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_handling_office', 'Handling office. Must exist in owl.handling_office. Cambridge, eg.', 1);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_customer_name', 'The name of the customer', 2);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_parenthost', 'The parent host. Usually www.credit360.com', 3);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
