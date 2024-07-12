-- Please update version.sql too -- this keeps clean builds in sync
define version=3290
define minor_version=2
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
	v_app_sid					security.security_pkg.T_SID_ID;
	v_act_id					security.security_pkg.T_ACT_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_everyone_sid				security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_beta_menu_sid			security.security_pkg.T_SID_ID;

	PROCEDURE INTERNAL_CreateOrGetResource(
		in_act_id			IN  security.security_pkg.T_ACT_ID,
		in_web_root_sid_id	IN  security.security_pkg.T_SID_ID,
		in_parent_sid_id	IN  security.security_pkg.T_SID_ID,
		in_page_name		IN  security.web_resource.path%TYPE,
		out_page_sid_id		OUT security.web_resource.sid_id%TYPE
	)
	IS
	BEGIN
		security.web_pkg.CreateResource(
			in_act_id			=> in_act_id,
			in_web_root_sid_id	=> in_web_root_sid_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_page_name		=> in_page_name,
			in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
			in_rewrite_path		=> NULL,
			out_page_sid_id		=> out_page_sid_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
	END;

	PROCEDURE INTERNAL_AddACE_NoDups(
		in_act_id			IN  security.security_pkg.T_ACT_ID,
		in_acl_id			IN  security.security_Pkg.T_ACL_ID,
		in_acl_index		IN  security.security_Pkg.T_ACL_INDEX,
		in_ace_type			IN  security.security_Pkg.T_ACE_TYPE,
		in_ace_flags		IN  security.security_Pkg.T_ACE_FLAGS,
		in_sid_id			IN  security.security_Pkg.T_SID_ID,
		in_permission_set	IN  security.security_Pkg.T_PERMISSION
	)
	IS
	BEGIN
		security.acl_pkg.RemoveACEsForSid(in_act_id, in_acl_id, in_sid_id);
		security.acl_pkg.AddACE(in_act_id, in_acl_id, in_acl_index, in_ace_type, in_ace_flags, in_sid_id, in_permission_set);
	END;
BEGIN
	FOR r IN (
		SELECT c.app_sid, c.name
		  FROM aspen2.application a
		  JOIN csr.customer c ON a.app_sid = c.app_sid
		 WHERE a.branding_service_css IS NOT NULL 
	)LOOP
		security.user_pkg.logonadmin(r.name);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

		v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
		v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.menu', v_www_beta_menu_sid);
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_beta_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_beta_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		security.user_pkg.logonadmin();
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
