-- Please update version.sql too -- this keeps clean builds in sync
define version=3226
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.flow_editor_beta (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONSTRAINT pk_flow_editor_beta PRIMARY KEY (app_sid)
);

-- Don't bother with csrexp/imp - this is a feature toggle table that ought to be short lived

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
	
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos, allow_blank)
	VALUES (v_workflow_module_id, 'Use new editor (beta)?', 'y/n', 0, 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\enable_pkg
@..\flow_pkg

@..\enable_body
@..\flow_body

@update_tail
