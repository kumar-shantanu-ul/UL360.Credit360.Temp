-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=12
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
	INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
		 VALUES (42, 'Remove matrix layout settings from a delegation', 'Removes layout settings from a delegation. See wiki for details.', 'RemoveMatrixLayout', 'W2866');
	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
		 VALUES (42, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);
	INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
		 VALUES (43, 'Create unique copy of matrix layout for delegation', 'Creates a unique copy of a matrix layout. Use this if you have copied a delegation that has a matrix layout. See wiki for details.', 'CreateUniqueMatrixLayoutCopy', 'W2866');
	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value, param_hidden)
		 VALUES (43, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
