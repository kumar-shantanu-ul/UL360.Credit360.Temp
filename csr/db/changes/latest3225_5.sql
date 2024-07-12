-- Please update version.sql too -- this keeps clean builds in sync
define version=3225
define minor_version=5
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
	v_www_api_campaigns	security.security_pkg.T_SID_ID;
	v_www_ui_campaigns	security.security_pkg.T_SID_ID;
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

		-- web resource for the api
		BEGIN
			v_www_api_campaigns := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.campaigns');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.campaigns', v_www_api_campaigns);
		END;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_campaigns), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		-- web resource for the ui
		BEGIN
			v_www_ui_campaigns := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'ui.campaigns');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'ui.campaigns', v_www_ui_campaigns);
		END;

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_ui_campaigns), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../flow_body
@../enable_body

@../campaigns/campaign_pkg
@../campaigns/campaign_body

@update_tail
