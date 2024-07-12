-- Please update version.sql too -- this keeps clean builds in sync
define version=3142
define minor_version=0
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
DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.security_pkg.SO_WEB_RESOURCE,
			in_permission			=> 65536, -- question_library_pkg.PERMISSION_VIEW_ALL_RESULTS
			in_permission_name		=> 'View all results'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.class_pkg.GetClassID('Surveys'),
			in_permission			=> 65536, -- question_library_pkg.PERMISSION_VIEW_ALL_RESULTS
			in_permission_name		=> 'View all results'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	
	-- Reset mapping of web resource to old survey since we can set view all results on a web resource
	DELETE FROM security.permission_mapping
	 WHERE parent_class_id IN (security.security_pkg.SO_WEB_RESOURCE)
	   AND child_class_id = security.class_pkg.GetClassID('CSRQuickSurvey')
	   AND child_permission = 65536; -- question_library_pkg.PERMISSION_VIEW_ALL_RESULTS*/
	
	security.class_pkg.createmapping(
			in_act_id				=> v_act,
			in_parent_class_id		=> security.security_pkg.SO_WEB_RESOURCE,
			in_parent_permission	=> 65536, -- csr.csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS,
			in_child_class_id		=> security.class_pkg.GetClassID('CSRQuickSurvey'),
			in_child_permission		=> 65536 -- csr.csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS
		);

	BEGIN
		security.class_pkg.createmapping(
			in_act_id				=> v_act,
			in_parent_class_id		=> security.security_pkg.SO_WEB_RESOURCE,
			in_parent_permission	=> 65536, -- csr.csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS,
			in_child_class_id		=> security.class_pkg.GetClassID('Surveys'),
			in_child_permission		=> 65536 -- csr.csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS
		);
		security.class_pkg.createmapping(
			in_act_id				=> v_act,
			in_parent_class_id		=> security.security_pkg.SO_WEB_RESOURCE,
			in_parent_permission	=> 131072, -- csr.csr_data_pkg.PERMISSION_PUBLISH,
			in_child_class_id		=> security.class_pkg.GetClassID('Surveys'),
			in_child_permission		=> 131072 -- csr.csr_data_pkg.PERMISSION_PUBLISH
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	security.user_pkg.LogOff(v_act);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
