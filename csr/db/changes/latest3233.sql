-- Please update version.sql too -- this keeps clean builds in sync
define version=3233
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_www_app			security.security_pkg.T_SID_ID;
	v_www_regions_api	security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;

	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		 WHERE EXISTS(
			SELECT NULL
			  FROM csr.customer_flow_alert_class cfac
			 WHERE cfac.app_sid = c.app_sid
			   AND cfac.flow_alert_class = 'campaign'
		 )
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);

		v_act_id := security.security_pkg.getact;

		v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');

		-- web resource for the app
		BEGIN
			v_www_app := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'app');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'app', v_www_app);
		END;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		-- web resource for the credit360.regions api
		BEGIN
			v_www_regions_api := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'credit360.regions');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'credit360.regions', v_www_regions_api);
		END;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_regions_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

@../enable_body

@update_tail
