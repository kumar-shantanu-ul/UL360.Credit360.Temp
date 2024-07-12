-- Please update version.sql too -- this keeps clean builds in sync
define version=3318
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

DROP TABLE csr.flow_editor_beta;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_workflow_module_id 			NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		SELECT module_id
		  INTO v_workflow_module_id
		  FROM csr.module
		 WHERE enable_sp = 'EnableWorkflow';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	DELETE FROM csr.module_param
		  WHERE module_id = v_workflow_module_id;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../flow_pkg

@../enable_body
@../flow_body

@update_tail
