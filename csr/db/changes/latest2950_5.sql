-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=5
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
	UPDATE csr.module
	   SET module_name = 'Owl Support',
	       enable_sp = 'EnableOwlSupport',
	       description = 'Enables Owl Support.'
	 WHERE module_id = 61;

	UPDATE csr.module
	   SET module_name = 'Owl Support: Support Cases',
		   description = 'Enables Support Cases. Owl Support is required.'
	 WHERE module_id = 62;

    DELETE FROM csr.module_param
     WHERE module_id = 61;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
