-- Please update version.sql too -- this keeps clean builds in sync
define version=3498
define minor_version=13
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
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
	v_www_ui			security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website w
		 WHERE application_sid_id IN (
			SELECT app_sid
			  FROM csr.customer
		  )
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout 	=> 172800,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id
		);
		
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');

		BEGIN			
			-- web resource for the ui
			v_www_ui := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'ui');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'ui', v_www_ui);
		END;

		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(v_www_ui),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_READ
		);
	END LOOP;			
END;
/

@update_tail
