
PROMPT please enter: host

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_teamroom				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_teamroom		security.security_pkg.T_SID_ID;
	-- temp variables
	v_new_sid_id            	security.security_pkg.T_SID_ID;
	v_type_id 					number(10);
	v_customer_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_af_id						csr.alert_frame.alert_frame_id%TYPE;
	v_calendar_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	
	--security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/data'),
	--	'csr_teamroom', 'Teamrooms', '/csr/site/teamroom/TeamroomList.acds', 10, null, v_menu_teamroom);
	
	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_teamroom := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'teamroom');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_teamroom), v_reg_users_sid);
		-- add reg users to teamroom web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_teamroom), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'teamroom', v_www_csr_site_teamroom);
			-- add reg users to issues web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_teamroom), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
    security.SecurableObject_pkg.CreateSO(security.security_pkg.getact, security.security_pkg.getapp, security.security_pkg.SO_CONTAINER, 'Teamrooms', v_new_sid_id);

	-- teamroom_pkg.CreateTeamroomType('Supplier', 'supplier', v_type_id);
    -- teamroom_pkg.CreateTeamroomType('Savings', 'savings', v_type_id); 
	
	/*** ALERTS ***/
	BEGIN
		SELECT MIN(alert_frame_id)
		  INTO v_af_id
		  FROM csr.alert_frame 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		 GROUP BY app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.alert_pkg.CreateFrame('Default', v_af_id);
	END;
	
	-- teamroom invitation alert
	INSERT INTO csr.customer_alert_type(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, 54)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;

	INSERT INTO csr.alert_template(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES (SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');	
	
	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
		INSERT INTO csr.alert_template_body(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, r.lang, 
				'<template>Invitation to join teamroom <mergefield name="TEAMROOM_NAME"/></template>', 
				'<template><div>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>You have been invited to join teamroom <mergefield name="TEAMROOM_NAME"/> by <mergefield name="FROM_FRIENDLY_NAME"/>. To accept the invitation, click the link or copy and paste it into your web browser.<br/><br/><mergefield name="LINK"/><br/><br/>Message from <mergefield name="FROM_FRIENDLY_NAME"/>:<br/><mergefield name="MESSAGE"/></div></template>', 
				'<template />');
	END LOOP;
	
	-- teamroom membership termination alert
	INSERT INTO csr.customer_alert_type(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, 55)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	
	INSERT INTO csr.alert_template(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES (SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');	
	
	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
		INSERT INTO csr.alert_template_body(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, r.lang, 
				'<template>Termination of membership in teamroom <mergefield name="TEAMROOM_NAME"/></template>', 
				'<template><div>You have been removed from teamroom <mergefield name="TEAMROOM_NAME"/>.</div></template>', 
				'<template />');
	END LOOP;
	
	/*** CALENDAR ***/
	BEGIN
		csr.calendar_pkg.RegisterCalendar('teamroomEvents', '/csr/shared/calendar/includes/teamrooms.js', 'Credit360.Calendars.Teamrooms', 'Teamroom events', 1, 1, 0, 'Credit360.Plugins.PluginDto', v_calendar_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		csr.calendar_pkg.RegisterCalendar('teamroomIssues', '/csr/site/teamroom/controls/calendar/issues.js', 'Teamroom.Calendars.Issues', 'Teamroom actions', 0, 1, 0, 'Credit360.Plugins.PluginDto', v_calendar_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		csr.calendar_pkg.RegisterCalendar('initiativeEvents', '/csr/shared/calendar/includes/initiatives.js', 'Credit360.Calendars.Initiatives', 'Initiative events', 1, 0, 1, 'Credit360.Plugins.PluginDto', v_calendar_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		csr.calendar_pkg.RegisterCalendar('initiativeIssues', '/csr/site/initiatives/calendar/issues.js', 'Credit360.Initiatives.Calendars.Issues', 'Milestones', 0, 0, 1, 'Credit360.Plugins.PluginDto', v_calendar_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	/*** ISSUES ***/
	BEGIN
		INSERT INTO csr.issue_type(issue_type_id, label)
		VALUES(csr.csr_data_pkg.ISSUE_TEAMROOM, 'Teamroom action');
	END;
		
	COMMIT;
END;
/
