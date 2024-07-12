-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=39
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
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_doc_lib_daclid				security.securable_object.dacl_id%TYPE;
	v_doc_folder_daclid				security.securable_object.dacl_id%TYPE;
	v_admins						security.security_pkg.T_SID_ID;
	v_registered_users				security.security_pkg.T_SID_ID;
	v_doc_folder					security.security_pkg.T_SID_ID;
	v_ehs_managers					security.security_pkg.T_SID_ID;
	v_prop_managers					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (
		SELECT c.host, co.permit_doc_lib_sid
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_doc_lib_sid IS NOT NULL
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			v_app_sid := security.security_pkg.getApp;
			v_act_id := security.security_pkg.getAct;

			v_doc_folder := security.securableobject_pkg.GetSIDFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid,
				in_path						=> 'Documents'
			);
		
			security.securableobject_pkg.ClearFlag(
				in_act_id					=> v_act_id,
				in_sid_id					=> r.permit_doc_lib_sid,
				in_flag						=> security.security_pkg.SOFLAG_INHERIT_DACL
			);
		
			-- Clear ACL
			v_doc_lib_daclid := security.acl_pkg.GetDACLIDForSID(r.permit_doc_lib_sid);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act_id,
				in_acl_id 					=> v_doc_lib_daclid
			);
			
			v_doc_folder_daclid := security.acl_pkg.GetDACLIDForSID(v_doc_folder);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act_id,
				in_acl_id 					=> v_doc_folder_daclid
			);
		
			-- Read/write for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		
			-- Add contents for EHS Managers
			v_ehs_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/EHS Managers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_folder_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_ehs_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
		
			-- Add contents for Property Manager
			v_prop_managers := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/Property Manager'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_folder_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_prop_managers,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_ADD_CONTENTS
			);
		
			-- Read only for other users (property workflow permission check will also apply)
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act_id,
				in_parent_sid_id			=> v_app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act_id,
				in_acl_id					=> v_doc_lib_daclid,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		
			security.acl_pkg.PropogateACEs(
				in_act_id					=> v_act_id,
				in_parent_sid_id			=> r.permit_doc_lib_sid
			);
			
			security.user_pkg.logonadmin();
		EXCEPTION 
			WHEN OTHERS THEN 
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
