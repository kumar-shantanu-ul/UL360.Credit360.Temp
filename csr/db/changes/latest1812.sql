-- Please update version.sql too -- this keeps clean builds in sync
define version=1812
@update_header

-- SSO logon daemon needs to be a CSR user to add audit entries
DECLARE
	v_users_sid					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_sso_daemons_group_sid		security.security_pkg.T_SID_ID;
	v_csr_user_class_id			security.security_pkg.T_CLASS_ID;
	v_act_id					security.security_pkg.T_ACT_ID;
	v_registered_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	-- Sites with SSO logon daemon user that isn't a CSR user
	FOR r IN (
		SELECT so.sid_id, w.application_sid_id
		FROM security.securable_object so
		JOIN security.website w ON w.application_sid_id = so.application_sid_id
		LEFT JOIN csr.csr_user u ON u.csr_user_sid = so.sid_id
		WHERE LOWER(so.name) = 'sso'
		AND so.class_id = security.security_pkg.SO_USER
		AND u.csr_user_sid IS NULL
		GROUP BY w.application_sid_id, so.sid_id
	) LOOP
  
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.application_sid_id, v_act_id);
	
	-- Change SSO logon daemon to be a CSR user
	v_csr_user_class_id := security.class_pkg.GetClassID('CSRUser');
	  
	UPDATE security.securable_object
	SET class_id = v_csr_user_class_id
	WHERE sid_id = r.sid_id AND application_sid_id = r.application_sid_id;
  
  	INSERT INTO csr.csr_user
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email,
		hidden,
		job_title, phone_number, region_mount_point_sid, info_xml, send_alerts, enable_aria, line_manager_sid, guid)
	VALUES (
		security.security_pkg.getApp, r.sid_id, 'sso', 'Single Sign On System', 'SSO', 'support@credit360.com',
		1, -- Don't want SSO logon daemon to be visible in the UI
		NULL, NULL,	NULL, NULL, 0, 0, NULL, security.user_pkg.GenerateACT);
		
	-- Add SSO logon daemon to RegisteredUsers group
    v_registered_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getApp, 'Groups/RegisteredUsers');
    security.Group_Pkg.addMember(security.security_pkg.getACT, r.sid_id, v_registered_users_sid);	
	
	-- Give SSO Logon Daemons group write permission on users, so they can update user details
    v_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Users');
	v_groups_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Groups');
    v_sso_daemons_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, 'SSO Logon Daemons');
	
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_users_sid);
	END LOOP;
END;
/

@update_tail