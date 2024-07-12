-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=4
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
DECLARE
	v_module_id			csr.module.module_id%TYPE;
BEGIN
	SELECT module_id 
	  INTO v_module_id
	  FROM csr.module
	 WHERE module_name = 'Initiatives';
	 
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (v_module_id, 'in_setup_base_data', 'Create default initiaitve module projects, metrics and metric groups? (y|n default=n)', 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
