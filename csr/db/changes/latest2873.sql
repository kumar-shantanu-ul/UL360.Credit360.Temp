-- Please update version.sql too -- this keeps clean builds in sync
define version=2873
define minor_version=0
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
	v_new_class_id 			security.security_pkg.T_SID_ID;
	v_act 					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	-- create csr app classes (inherits from aspenapp)
		BEGIN
			BEGIN
				security.class_pkg.CreateClass(
					in_act_id			=>  v_act,
					in_parent_class_id	=>  security.Security_Pkg.SO_CONTAINER,
					in_class_name		=>  'CmsContainer',
					in_helper_pkg		=>  NULL,
					in_helper_prog_id	=>  NULL,
					out_class_id		=>  v_new_class_id
				);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					SELECT class_id
					  INTO v_new_class_id
					  FROM security.securable_object_class
					 WHERE class_name = 'CmsContainer'
					   AND parent_class_id = security.Security_Pkg.SO_CONTAINER
					   AND helper_pkg IS NULL
					   AND helper_prog_id IS NULL;

				-- Add permissions.
				INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 65536, 'Export');
				INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 131072, 'Bulk export');
			END;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- Already exists.
				NULL;
	END;
	
	BEGIN
		BEGIN
			security.class_pkg.CreateClass(v_act, NULL, 'CMSTable', 'cms.tab_pkg', null, v_new_class_id);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				SELECT class_id
				  INTO v_new_class_id
				  FROM security.securable_object_class
				 WHERE class_name = 'CMSTable'
				   AND parent_class_id IS NULL
				   AND helper_pkg = 'cms.tab_pkg'
				   AND helper_prog_id IS NULL;

				-- Add permissions.
				INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 65536, 'Export');
				INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 131072, 'Bulk export');
		END;
	EXCEPTION WHEN
		DUP_VAL_ON_INDEX THEN
			-- Already exists.
			NULL;
	END;
		
	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'CMSFilter', 'cms.filter_pkg', null, v_new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	security.user_pkg.LogOff(v_act);
END;
/

-- ** New package grants **

-- *** Packages ***


@update_tail
