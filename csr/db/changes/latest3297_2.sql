-- Please update version.sql too -- this keeps clean builds in sync
define version=3297
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
-- Add builtin Administrators group to api.tenants web resource for all apps so apis/tools can query group permissions as builtin admin.
DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		-- Somehow some sites don't have this web resource... So try creating it (again) first.
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.tenants', v_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.web_root_sid_id, 'api.tenants');
		END;
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, security.securableObject_pkg.GetSIDFromPath(v_act, 0, '//BuiltIn/Administrators'), security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
 
@update_tail
