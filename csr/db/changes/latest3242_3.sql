-- Please update version.sql too -- this keeps clean builds in sync
define version=3242
define minor_version=3
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
	-- Add missing web resources for Geo service API to all sites (missed in previous latest script).

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
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'ui.geoservice', v_sid);
			
			security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
