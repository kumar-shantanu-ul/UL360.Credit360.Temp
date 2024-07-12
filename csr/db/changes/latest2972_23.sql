-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=23
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
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (46, 'in_setup_base_data', 'Create default initiative module projects, metrics and metric groups? (y|n default=n)', 0);
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
