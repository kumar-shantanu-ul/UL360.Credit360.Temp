-- Please update version.sql too -- this keeps clean builds in sync
define version=3370
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
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_www_api_security	security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;

	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		  JOIN security.website w ON c.app_sid = w.application_sid_id AND LOWER(c.host) = LOWER(w.website_name)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);

		v_act_id := security.security_pkg.getact;

		v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');

		-- web resource for the api
		BEGIN
			v_www_api_security := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.translations');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.translations', v_www_api_security);
		END;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_security), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
