-- Please update version.sql too -- this keeps clean builds in sync
define version=3242
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
	v_act				security.security_pkg.T_ACT_ID;
	v_sid				security.security_pkg.T_SID_ID;
	v_superadmin_sid	security.security_pkg.T_SID_ID;
	v_app_resource_sid	security.security_pkg.T_SID_ID;
BEGIN
	-- Add menu items and web resources for Geo service API + admin page to all sites.

	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_superadmin_sid := security.securableobject_pkg.getsidfrompath(v_act, 0, 'csr/SuperAdmins');
	
		-- Web resources.
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.geoservice', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'authorization', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'app', v_app_resource_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
				
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				-- Make sure permissions aren't inheritable if resource already exists (for example if created from enabling Suggestions).
				v_app_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.web_root_sid_id, 'app');
				security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'));
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_app_resource_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
				
				-- Create suggestions UI web resource in correct location (don't bother finding any existing web resources, they won't do any harm being left there).
				BEGIN
					security.web_pkg.CreateResource(v_act, r.web_root_sid_id, v_app_resource_sid, 'ui.suggestions', v_sid);
					
					security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				EXCEPTION
					WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
						NULL;
				END;
		END;
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, v_app_resource_sid, 'ui.geoservice', v_sid);
			
			security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		
		-- Create menu item.
		DECLARE
			v_admin_menu_sid		security.security_pkg.T_SID_ID;
		BEGIN
			v_admin_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'menu/setup');
		
			security.menu_pkg.CreateMenu(
				in_act_id => v_act,
				in_parent_sid_id => v_admin_menu_sid,
				in_name => 'geoservice_admin',
				in_description => 'Geo service',
				in_action => '/app/ui.geoservice/settings',
				in_pos => NULL,
				in_context => NULL,
				out_sid_id => v_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'menu/setup/geoservice_admin');
		END;

		security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.DeleteAllACES(v_act, security.acl_pkg.GetDACLIDForSID(v_sid));
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
