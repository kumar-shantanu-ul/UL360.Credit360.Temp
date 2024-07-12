-- Please update version.sql too -- this keeps clean builds in sync
define version=3447
define minor_version=4
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

-- Create api.audits/health where api.audits exists
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_root						security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_api_resource_sid				security.security_pkg.T_SID_ID;
	v_health_resource_sid			security.security_pkg.T_SID_ID;
	v_everyone_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act);

	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');

		BEGIN
			v_api_resource_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'api.audits');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				CONTINUE;
		END;

		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Groups/Everyone');
		security.web_pkg.CreateResource(v_act, v_www_root, v_api_resource_sid, 'health', v_health_resource_sid);

		security.acl_pkg.AddACE(
			v_act, security.acl_pkg.GetDACLIDForSID(v_health_resource_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END lOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
