-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=20
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
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (85, 'Emission Factors Profiling', 'EnableEmFactorsProfileTool', 'Enables/Disables the Emission Factors Profile tool');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (85, 'Enable/Disable', 0, '0=disable, 1=enable');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (85, 'Menu Position', 1, '-1=end, or 1 based position');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (86, 'Emission Factors Classic', 'EnableEmFactorsClassicTool', 'Enables/Disables the Emission Factors Classic tool');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (86, 'Enable/Disable', 1, '0=disable, 1=enable');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (86, 'Menu Position', 2, '-1=end, or 1 based position, ignored if disabling');
END;
/

BEGIN
	UPDATE csr.module 
	   SET module_name = 'Emission Factor Start Date'
	 WHERE module_id = 50;
	 
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (50, 'Enable/Disable', 0, '0=disable, 1=enable');
	
	-- Remove "Emission Factor Start Date OFF"
	DELETE FROM csr.module 
	 WHERE module_id = 51;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
