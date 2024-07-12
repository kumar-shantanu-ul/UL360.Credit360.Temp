CREATE OR REPLACE PACKAGE BODY CHAIN.setup_pkg
IS

PROCEDURE VerifySetupPermission (
	in_caller				IN VARCHAR2,
	in_skip_setup_check		IN BOOLEAN DEFAULT FALSE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, in_caller||' can only be run as BuiltIn/Administrator');
	END IF;

	IF NOT in_skip_setup_check AND NOT IsChainEnabled THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain has not yet been enabled. You must run EnableSite first.');
	END IF;
END;

PROCEDURE SetupPortlets (
	in_is_single_tier		IN BOOLEAN
)
AS
	v_tab_id			csr.tab.tab_id%TYPE;
	v_tab_ids			security_pkg.T_SID_IDS;
	v_chain_users_sid	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Groups/Chain Users');
	v_chain_mgrs_sid	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Groups/Supply Chain Managers');
	v_suplrs_grp_sid	security_pkg.T_SID_ID;
	v_act				security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT;
	v_app_sid			security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;

	-- helper
	PROCEDURE AddChainPortletToTab(
		in_tab_id			IN	csr.tab.tab_id%TYPE,
		in_type				IN	VARCHAR2,
		in_title			IN	VARCHAR2
	)
	AS
		v_portlet_sid		csr.portlet.portlet_id%TYPE;
		v_tab_portlet_id	csr.tab_portlet.tab_portlet_id%TYPE;
	BEGIN
		SELECT customer_portlet_sid
		  INTO v_portlet_sid
		  FROM csr.customer_portlet
		 WHERE app_sid = security_pkg.GetApp
		   AND portlet_id IN (SELECT portlet_id FROM csr.portlet WHERE TYPE = 'Credit360.Portlets.Chain.'||in_type);

		csr.portlet_pkg.AddPortletToTab(in_tab_id, v_portlet_sid, '{"portletTitle":"'||in_title||'"}', v_tab_portlet_id);
	END;
BEGIN
	DELETE FROM csr.tab_user			WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'Chain');
	DELETE FROM csr.tab_group			WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'Chain');
	DELETE FROM csr.tab_portlet_rss_feed tprf
	 WHERE tprf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tprf.tab_portlet_id IN (
		SELECT tp.tab_portlet_id
		  FROM csr.tab t
		  JOIN csr.tab_portlet tp ON tp.tab_id = t.tab_id
		 WHERE t.portal_group = 'Chain'
	);
	DELETE FROM csr.user_setting_entry usentry
	 WHERE usentry.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND usentry.tab_portlet_id IN (
		SELECT tp.tab_portlet_id
		  FROM csr.tab t
		  JOIN csr.tab_portlet tp ON tp.tab_id = t.tab_id
		 WHERE t.portal_group = 'Chain'
	);
	DELETE FROM csr.tab_portlet		WHERE app_sid = v_app_sid AND tab_id IN (SELECT tab_id FROM csr.tab WHERE portal_group = 'Chain');
	DELETE FROM csr.tab				WHERE app_sid = v_app_sid AND portal_group = 'Chain';
	DELETE FROM csr.customer_portlet	WHERE app_sid = v_app_sid AND portal_group = 'Chain';

	FOR r IN(
		SELECT portlet_id, v_app_sid, 'Chain' portal_group FROM csr.portlet WHERE type IN (
			'Credit360.Portlets.Chain.RecentActivity',
			'Credit360.Portlets.Chain.RequiredActions',
			'Credit360.Portlets.Chain.NewsFlash',
			'Credit360.Portlets.Chain.InvitationSummary')
		AND portlet_id NOT IN (SELECT portlet_id FROM csr.customer_portlet WHERE app_sid = v_app_sid)
	) LOOP
		csr.portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	csr.portlet_pkg.AddTabReturnTabId(v_app_sid, 'Dashboard', 1 /* shared */,  1 /* hideable */, 2 /* layout full width */, 'Chain', v_tab_id);

	AddChainPortletToTab(v_tab_id, 'RecentActivity', 'Latest Activity');
	AddChainPortletToTab(v_tab_id, 'InvitationSummary', 'System Summary');
	AddChainPortletToTab(v_tab_id, 'NewsFlash', 'News');
	AddChainPortletToTab(v_tab_id, 'RequiredActions', 'Items requiring your attention');

	v_tab_ids(1) := v_tab_id;
	IF in_is_single_tier THEN
		-- All chain users have the same portlets
		csr.portlet_pkg.SetTabsForGroup('Chain', v_chain_users_sid, v_tab_ids);
	ELSE
		-- Top company has summary portlet, other companies do not
		csr.portlet_pkg.SetTabsForGroup('Chain', v_chain_mgrs_sid, v_tab_ids);
		
		csr.portlet_pkg.AddTabReturnTabId(v_app_sid, 'My dashboard', 1 /* shared */,  1 /* hideable */,  2 /* layout full width */, 'Chain', v_tab_id);

		AddChainPortletToTab(v_tab_id, 'RecentActivity', 'Latest Activity');
		AddChainPortletToTab(v_tab_id, 'NewsFlash', 'News');
		AddChainPortletToTab(v_tab_id, 'RequiredActions', 'Items requiring your attention');

		v_tab_ids(1) := v_tab_id;
		v_suplrs_grp_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Groups/Suppliers');
		csr.portlet_pkg.SetTabsForGroup('Chain', v_suplrs_grp_sid, v_tab_ids);
	END IF;
END;

PROCEDURE SetupCsrAlerts
AS
	v_sat_ids					chain.T_NUMBER_LIST; -- std_alert_type ids
	v_sat_to_cat_id_map			security_pkg.T_SID_IDS; -- maps std_alert_type_ids to customer_alert_type ids
	v_af_id						csr.alert_frame.alert_frame_id%TYPE;
	v_customer_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;		
BEGIN
	v_sat_ids := chain.T_NUMBER_LIST(
		5000,
		5002,
		5003,
		5008,
		5010,
		5014,
		5016,
		5017,
		5019,
		5020,
		5022,
		5029,
		5030,
		5031,
		5032
	);
	
	FOR i IN v_sat_ids.FIRST .. v_sat_ids.LAST
	LOOP
		-- delete anything we might have already
		DELETE FROM csr.alert_template_body 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.alert_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.alert_batch_run 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.customer_alert_type 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);
	   
		-- shove in a new row
		INSERT INTO csr.customer_alert_type 
			(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, v_sat_ids(i))
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
		
		v_sat_to_cat_id_map(v_sat_ids(i)) := v_customer_alert_type_id;

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

		INSERT INTO csr.alert_template 
			(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');
		 
	END LOOP;
	
	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
	
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5000), r.lang, 
			'<template>Supplier Registrations Process</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>My name is <mergefield name="FROM_FRIENDLY_NAME"/> <mergefield name="FROM_JOBTITLE"/> and I work for <mergefield name="FROM_COMPANY_NAME"/>. As <mergefield name="TO_COMPANY_NAME"/> is one of our valued suppliers, we would like to invite you to help us out by entering details of the products you supply us.<br/><br/>To fill in this information, you''ll need to either login to, or create an account by clicking on the following link:<br/><br/><mergefield name="LINK"/><br/>(This invitation link is only valid until <mergefield name="EXPIRATION"/>.)<br/><mergefield name="PERSONAL_MESSAGE"/><br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>', 
			'<template />');
			
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5029), r.lang, 
			'<template>Supplier Registrations Process Reminder</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>My name is <mergefield name="FROM_FRIENDLY_NAME"/> <mergefield name="FROM_JOBTITLE"/> and I work for <mergefield name="FROM_COMPANY"/>. As <mergefield name="TO_COMPANY"/> is one of our valued suppliers, we would like to invite you to help us out by entering details of the products you supply us.<br/><br/>To fill in this information, you''ll need to either login to, or create an account by clicking on the following link:<br/><br/><mergefield name="LINK"/><br/>(This invitation link is only valid until <mergefield name="EXPIRATION"/>.)<br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>', 
			'<template />');

		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5031), r.lang,
			'<template>Company relationship request accepted</template>',
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>Your request for a relationship with <mergefield name="REQUESTED_COMPANY"/> from your company <mergefield name="REQUESTING_COMPANY"/> (<mergefield name="COMPANY_URL"/>) was accepted.<br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>',
			'<template />');

		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5032), r.lang,
			'<template>Company relationship request refused</template>',
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>We have rejected your relationship request from your company <mergefield name="REQUESTING_COMPANY"/> to <mergefield name="REQUESTED_COMPANY"/>.<br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>',
			'<template />');
		
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5002), r.lang, 
			'<template><mergefield name="SITE_NAME"/> Registration</template>', 
			'<template><div>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>To finish your registration process, click the link or copy and paste it into your web browser.<br/><br/><mergefield name="LINK"/><br/><br/>This link expires <mergefield name="EXPIRATION"/>.</div></template>', 
			'<template />');
		
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5003), r.lang, 
			'<template><mergefield name="ALERT_ENTRY_TYPE_DESCRIPTION"/> - <mergefield name="SITE_NAME"/></template>', 
			'<template><div>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>Below is a list of recent activity involving you on <mergefield name="SITE_NAME"/>.<br/><br/><mergefield name="CONTENT"/></div></template>', 
			'<template />');
		
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5010), r.lang, 
			'<template>Supplier Registrations Process</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>My name is <mergefield name="FROM_FRIENDLY_NAME"/> <mergefield name="FROM_JOBTITLE"/> and I work for <mergefield name="FROM_COMPANY_NAME"/>. As <mergefield name="TO_COMPANY_NAME"/> is one of our valued suppliers, we would like to invite you to help us out by entering details of the products you supply us.<br/><br/>To fill in this information, you''ll need to either login to, or create an account by clicking on the following link:<br/><br/><mergefield name="LINK"/><br/>(This invitation link is only valid until <mergefield name="EXPIRATION"/>.)<br/><br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>', 
			'<template />');
			
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5014), r.lang, 
			'<template>Supplier Invitation</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>My name is <mergefield name="FROM_FRIENDLY_NAME"/> <mergefield name="FROM_JOBTITLE"/> and I''m contacting you on behalf of <mergefield name="FROM_COMPANY_NAME"/>. As <mergefield name="TO_COMPANY_NAME"/> is one of our valued suppliers, we would like to invite you to join our supply chain management system and provide details of the products or services that you supply to us.<br/><br/>An account has been created for you on our supplier management system. Please log in to complete your account creation: <mergefield name="LINK"/> (This link is only valid until <mergefield name="EXPIRATION"/>.)<br/><br/>Many thanks,<br/><br/><mergefield name="FROM_NAME"/></template>', 
			'<template />');
			
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5016), r.lang, 
			'<template>Questionnaire reminder</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME" />,<br /><br />This a reminder that the following questionnaire will be due on <mergefield name="DUE_DATE" />.<br />We kindly ask you to complete the survey by clicking on the following link:<br /><mergefield name="QUESTIONNAIRE_LINK" /><br /><br />Thank you for your cooperation<br /></template>',
			'<template />');
			
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5017), r.lang, 
			'<template>Questionnaire overdue</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME" />,<br /><br />This a reminder that the following questionnaire is now past the due date <mergefield name="DUE_DATE" />.<br />We kindly ask you to complete the questionnaire by clicking on the following link:<br /><mergefield name="QUESTIONNAIRE_LINK" /><br /><br />Thank you for your cooperation<br /></template>',
			'<template />');
	END LOOP;
END;

PROCEDURE SetupCardManagers (
	in_enable_csr_supplier		IN	BOOLEAN
)
AS
BEGIN
	-- TODO: This needs some parameters but bascially should be a simple, usable "default"
	card_pkg.SetGroupCards('Questionnaire Invitation Wizard', T_STRING_LIST(
		--'Chain.Cards.InviteCompanyType',
		'Chain.Cards.AddCompany', -- createnew or default
		'Chain.Cards.CreateCompany',
		'Chain.Cards.AddUser',
		'Chain.Cards.CreateUser',
		'Chain.Cards.InvitationSummary'
	));
	card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'),
		T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')
	));
	card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.CreateCompany', 'Chain.Cards.CreateUser');
	card_pkg.MarkTerminate('Questionnaire Invitation Wizard', 'Chain.Cards.InvitationSummary');
	
	card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'),
		T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')
	));
	
	card_pkg.SetGroupCards('Questionnaire Invitation Landing', T_STRING_LIST(
		'Chain.Cards.CSRQuestionnaireInvitationConfirmation', 
		'Chain.Cards.Login', 
		'Chain.Cards.RejectInvitation', 
		'Chain.Cards.SelfRegistration'
	));
	card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.Login');
	card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.SelfRegistration');
	card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.RejectInvitation');
	card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.CSRQuestionnaireInvitationConfirmation', T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));
	
	card_pkg.SetGroupCards('Company Invitation Wizard', chain.T_STRING_LIST(
		'Chain.Cards.AddCompanyByCT', 
		'Chain.Cards.CreateCompanyByCT', 
		'Chain.Cards.ChooseNewOrNoContacts', 			
		'Chain.Cards.AddContacts', 
		'Chain.Cards.PersonalizeInvitationEmail', 
		'Chain.Cards.InvitationSummary')
	);
	
	card_pkg.RegisterProgression('Company Invitation Wizard', 'Chain.Cards.AddCompanyByCT', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.AddContacts'),		
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompanyByCT')
	));

	card_pkg.RegisterProgression('Company Invitation Wizard', 'Chain.Cards.ChooseNewOrNoContacts', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'),
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.AddContacts')		
	));
	
	card_pkg.RegisterProgression('Company Invitation Wizard', 'Chain.Cards.AddContacts', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'),
		chain.T_CARD_ACTION_ROW('invite', 'Chain.Cards.PersonalizeInvitationEmail')		
	));
	
	card_pkg.MakeCardConditional('Company Invitation Wizard', 'Chain.Cards.AddContacts', chain_pkg.CREATE_USER_WITHOUT_INVITE);
	card_pkg.MakeCardConditional('Company Invitation Wizard', 'Chain.Cards.ChooseNewOrNoContacts', chain_pkg.CREATE_USER_WITHOUT_INVITE);
	card_pkg.MakeCardConditional('Company Invitation Wizard', 'Chain.Cards.PersonalizeInvitationEmail', chain_pkg.CREATE_USER_WITHOUT_INVITE);
	card_pkg.MakeCardConditional('Company Invitation Wizard', 'Chain.Cards.AddCompanyByCT', chain_pkg.CREATE_USER_WITHOUT_INVITE);
	
	card_pkg.SetGroupCards('Company Invitation Landing', T_STRING_LIST(
		'Chain.Cards.CompanyInvitationConfirmation',  
		'Chain.Cards.Login',
		'Chain.Cards.RejectInvitation',
		'Chain.Cards.SelfRegistration'
	));
		
	card_pkg.MarkTerminate('Company Invitation Landing', 'Chain.Cards.Login');
	card_pkg.MarkTerminate('Company Invitation Landing', 'Chain.Cards.SelfRegistration');
	card_pkg.MarkTerminate('Company Invitation Landing', 'Chain.Cards.RejectInvitation');
	card_pkg.RegisterProgression('Company Invitation Landing', 'Chain.Cards.CompanyInvitationConfirmation', chain.T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));
	
	/*card_pkg.SetGroupCards('Stub Invitation Landing', T_STRING_LIST(
		'Chain.Cards.StubInvitationConfirmation',
		'Chain.Cards.Login',
		'Chain.Cards.RejectInvitation',
		'Chain.Cards.SelfRegistration'
	));
	
	card_pkg.MarkTerminate('Stub Invitation Landing', 'Chain.Cards.Login');
	card_pkg.MarkTerminate('Stub Invitation Landing', 'Chain.Cards.SelfRegistration');
	card_pkg.MarkTerminate('Stub Invitation Landing', 'Chain.Cards.RejectInvitation');
	card_pkg.RegisterProgression('Stub Invitation Landing', 'Chain.Cards.StubInvitationConfirmation', T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));*/
	
	card_pkg.SetGroupCards('Create Company', T_STRING_LIST('Chain.Cards.CreateCompanyByCT'));
		
	card_pkg.SetGroupCards('My Details', T_STRING_LIST('Chain.Cards.EditUser'));
	
	card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.ViewCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, TRUE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.EditCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain_pkg.CT_COMPANY, chain_pkg.CREATE_USER, FALSE);
	card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION, FALSE);
	
	card_pkg.SetGroupCards('Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.IssuesBrowser', 'Chain.Cards.SupplierRelationship'));
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.ViewCompany', chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE, TRUE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.EditCompany', chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.IssuesBrowser', chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.SupplierRelationship', chain_pkg.VIEW_RELATIONSHIPS, FALSE);
	card_pkg.MakeCardConditional('Supplier Details', 'Chain.Cards.CreateCompanyUser', chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CREATE_USER, FALSE);
	
	card_pkg.SetGroupCards('Pending Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.SupplierInvitationSummary'));
	
	card_pkg.SetGroupCards('Basic Company Filter', T_STRING_LIST('Chain.Cards.Filters.CompanyCore', 'Chain.Cards.Filters.CompanyTagsFilter',
																 'Chain.Cards.Filters.SurveyQuestionnaire', 'Chain.Cards.Filters.SurveyCampaign',
																 'Chain.Cards.Filters.CompanyRelationshipFilter', 'Chain.Cards.Filters.CompanyAuditFilterAdapter', 
																 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter', 'Chain.Cards.Filters.CompanyCmsFilterAdapter',
																 'Chain.Cards.Filters.CompanyCertificationFilterAdapter', 'Chain.Cards.Filters.CompanyProductFilterAdapter'));
	card_pkg.MakeCardConditional('Basic Company Filter', 'Chain.Cards.Filters.CompanyRelationshipFilter', chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_RELATIONSHIPS);
	card_pkg.MakeCardConditional('Basic Company Filter', 'Chain.Cards.Filters.CompanyAuditFilterAdapter', chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_COMPANY_AUDITS);
	card_pkg.MakeCardConditional('Basic Company Filter', 'Chain.Cards.Filters.CompanyCmsFilterAdapter', chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_CMS_COMPANIES);
	
	card_pkg.SetGroupCards('Certification Filter', T_STRING_LIST('Chain.Cards.Filters.CertificationFilter', 'Chain.Cards.Filters.CertificationCompanyFilterAdapter'));
	
	card_pkg.SetGroupCards('Business Relationship Filter', T_STRING_LIST('Chain.Cards.Filters.BusinessRelationshipFilter','Chain.Cards.Filters.BusinessRelationshipFilterAdapter'));
	
	card_pkg.SetGroupCards('Add Existing Contacts Wizard', chain.T_STRING_LIST('Chain.Cards.AddExistingSuppliers','Chain.Cards.AddExistingUsers'));
	
	/*IF in_enable_csr_supplier THEN
		chain.card_pkg.SetGroupCards('Supplier Extras', chain.T_STRING_LIST('Chain.Cards.CsrSupplierExtras'));
	END IF;*/
	
	card_pkg.SetGroupCards('Invite the Uninvited Wizard', T_STRING_LIST(
			'Chain.Cards.CreateCompany',
			'Chain.Cards.CreateUser',
			'Chain.Cards.InvitationSummary'
		));
	
	chain.card_pkg.SetGroupCards('Dedupe Processed Record Filter', chain.T_STRING_LIST('Chain.dedupe.filters.ProcessedRecordFilter'));

	/*chain.card_pkg.SetGroupCards('Purchased Component Wizard', chain.T_STRING_LIST(
		--'Chain.Cards.AddCompanyByCT',
		'Chain.Cards.EditComponent',
		'Chain.Cards.QuestionnaireTypeSelect',
		'Chain.Cards.SearchComponentSupplier',
		'Chain.Cards.CreateUninvitedCompany',
		'Chain.Cards.ComponentSupplierWantToInvite',
		'Chain.Cards.AddComponentSupplierUsers',
		'Chain.Cards.CreateUser',
		'Chain.Cards.PurchasedComponentSummary'
	));
	
	chain.card_pkg.RegisterProgression('Purchased Component Wizard', 'Chain.Cards.SearchComponentSupplier', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.ComponentSupplierWantToInvite'),
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUninvitedCompany')
	));
	
	chain.card_pkg.RegisterProgression('Purchased Component Wizard', 'Chain.Cards.ComponentSupplierWantToInvite', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('existing-comp-invite', 'Chain.Cards.AddComponentSupplierUsers'),
		chain.T_CARD_ACTION_ROW('new-comp-invite', 'Chain.Cards.CreateUser'),
		chain.T_CARD_ACTION_ROW('no-invite', 'Chain.Cards.PurchasedComponentSummary')
	));
	
	chain.card_pkg.RegisterProgression('Purchased Component Wizard', 'Chain.Cards.AddComponentSupplierUsers', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.PurchasedComponentSummary'),
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')
	));
	
	chain.card_pkg.MarkTerminate('Purchased Component Wizard', 'Chain.Cards.PurchasedComponentSummary');
	
	chain.card_pkg.SetCardInitParam('Chain.Cards.QuestionnaireTypeSelect','hideSupplierQT','true', chain.chain_pkg.CIPT_SPECIFIC,'Purchased Component Wizard');
	*/
END;

/*PROCEDURE SetupComponents
AS
	PRODUCT_COMPONENT 			chain.chain_pkg.T_COMPONENT_TYPE DEFAULT chain.chain_pkg.PRODUCT_COMPONENT;
	PURCHASED_COMPONENT			chain.chain_pkg.T_COMPONENT_TYPE DEFAULT chain.chain_pkg.PURCHASED_COMPONENT;
BEGIN
	--SETUP CONTAINMENT AND UI PERMISSIONS
	chain.component_pkg.ClearTypeContainment();
	chain.component_pkg.SetTypeContainment(PRODUCT_COMPONENT, PURCHASED_COMPONENT, chain.chain_pkg.ALLOW_ADD_NEW);
	
	--SETUP CONTAINMENT SOURCE DATA FOR WIZARDS
	chain.component_pkg.ClearSources();
	
	chain.component_pkg.AddSource(
		PURCHASED_COMPONENT, 'purchased', 'I buy this from one supplier', 
		''
	);
	
	chain.component_pkg.CreateComponentAmountUnit(1, 'kg', chain.chain_pkg.AUT_MASS, 1);
	
END;*/

PROCEDURE SetupCore (
	in_site_name				customer_options.site_name%TYPE,
	in_support_email			customer_options.support_email%TYPE,
	in_overwrite_home_page		BOOLEAN DEFAULT TRUE,
	in_lock_tree				BOOLEAN DEFAULT TRUE
)
AS
	v_primary_root_sid			security_pkg.T_SID_ID;
	v_suppliers_sid				security_pkg.T_SID_ID;
	v_user_creator_daemon_sid	security_pkg.T_SID_ID;
	v_delegations_sid			security_pkg.T_SID_ID;
	v_recipients_sid			security_pkg.T_SID_ID;
	v_chain_users_sid			security_pkg.T_SID_ID;
	v_chain_managers_sid		security_pkg.T_SID_ID;
	v_suppliers_role_sid		security_pkg.T_SID_ID;
	v_www_csr_site_delegation	security_pkg.T_SID_ID;
	v_www_csr_site_issues		security_pkg.T_SID_ID;
	v_host						VARCHAR2(1024) DEFAULT securableobject_pkg.getname(security_pkg.getACT, security_pkg.getApp);
	v_chain						security_pkg.T_SID_ID;
	v_built_in					security_pkg.T_SID_ID;
	v_respondent				security_pkg.T_SID_ID;
	v_cap_sid					security_pkg.T_SID_ID;
BEGIN
	v_user_creator_daemon_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Users/UserCreatorDaemon');
	BEGIN
		INSERT INTO csr.customer_region_type (app_sid, region_type) VALUES (security_pkg.getApp, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null; -- already exists so no problem
	END;
	
	SELECT region_tree_root_sid
	  INTO v_primary_root_sid
	  FROM csr.region_tree
	 WHERE app_sid = security_pkg.GetApp and is_primary = 1;
	-- create a suppliers region + give UCD permissionson various things
	BEGIN
		v_suppliers_sid := securableobject_pkg.getSidFromPath(security_pkg.getAct, v_primary_root_sid, 'Suppliers');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			csr.region_pkg.CreateRegion(
				in_parent_sid => v_primary_root_sid,
				in_name => 'Suppliers',
				in_description => 'Suppliers',
				out_region_sid => v_suppliers_sid
			);
			-- grant ucd permissions on Suppliers region
			acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_suppliers_Sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL + csr.csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	END;
	
	--lock main suppliers region tree
	IF in_lock_tree THEN
		chain.helper_pkg.LockRegionTree(v_suppliers_sid);
	END IF;
	
	-- grant ucd permissions on /Delegations and the /Suppliers region
	v_delegations_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Delegations');
	acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_delegations_Sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL);
	-- push down
	acl_pkg.PropogateACEs(security_pkg.getACT, v_delegations_Sid);
	
	-- grant ucd permissions on /Donations/Recipients
	BEGIN
		v_recipients_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Donations/Recipients');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_recipients_sid := null;
	END;
	
	IF v_recipients_sid IS NOT NULL THEN
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_recipients_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL);
		-- push down
		acl_pkg.PropogateACEs(security_pkg.getACT, v_recipients_sid);
	END IF;
	
	v_chain_users_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/Chain Users');

	-- grant "Chain users" permissions on wwwroot/csr/site/delegation
	BEGIN
		v_www_csr_site_delegation := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'wwwroot/csr/site/delegation');
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_www_csr_site_delegation), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_chain_users_sid, security_pkg.PERMISSION_STANDARD_ALL);
		acl_pkg.PropogateACEs(security_pkg.getACT, v_www_csr_site_delegation);
	EXCEPTION
		WHEN  security_pkg.OBJECT_NOT_FOUND THEN
			-- ignore
			NULL;
	END;
	
	-- grant "Chain users" permissions on wwwroot/csr/site/issues
	BEGIN
		v_www_csr_site_issues := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'wwwroot/csr/site/issues');
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_www_csr_site_issues), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_chain_users_sid, security_pkg.PERMISSION_STANDARD_ALL);	
		acl_pkg.PropogateACEs(security_pkg.getACT, v_www_csr_site_issues);
	EXCEPTION
		WHEN  security_pkg.OBJECT_NOT_FOUND THEN
			-- ignore
			NULL;
	END;
	
	BEGIN
		v_suppliers_role_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.GetApp, 'Groups/Suppliers');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			csr.role_pkg.SetRole(
				security_pkg.getACT,
				security_pkg.GetApp,
				'Suppliers',
				'SUPPLIERS',
				v_suppliers_role_sid
				);

			UPDATE csr.role
			   SET is_supplier = 1
			 WHERE role_sid = v_suppliers_role_sid;
	END;
	
	IF in_overwrite_home_page THEN
		security.web_pkg.SetHomePage(security_pkg.getACT, security_pkg.GetApp, v_suppliers_role_sid, '/csr/site/chain/dashboard.acds', v_host);
	END IF;
	
	BEGIN
		v_chain_managers_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.GetApp, 'Groups/Supply Chain Managers');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(
				security_pkg.getACT,
				securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups'),
				security_pkg.GROUP_TYPE_SECURITY,
				'Supply Chain Managers',
				v_chain_managers_sid
				);

			group_pkg.AddMember(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Administrators'), v_chain_managers_sid);
			group_pkg.AddMember(security_pkg.GetAct, v_chain_managers_sid, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Chain Users'));
	END;
	
	BEGIN
		INSERT INTO customer_options (app_sid) VALUES (SYS_CONTEXT('SECURITY','APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- ignore
			NULL;
	END;

	UPDATE customer_options
	   SET site_name = COALESCE(in_site_name, site_name, 'Supply chain management'), 
		   support_email = COALESCE(in_support_email, support_email, 'no-reply@cr360.com'),
		   default_url = NVL(default_url, '/csr/site/chain/dashboard.acds')
	 WHERE app_sid = security_pkg.GetApp;
	
	v_chain := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Chain');

	BEGIN
		v_built_in := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_chain, 'BuiltIn');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(security_pkg.GetACT, v_chain, class_pkg.GetClassID('Container'), 'BuiltIn', v_built_in);
	END;

	BEGIN
		v_respondent := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_built_in, 'Invitation Respondent');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN

			user_pkg.CreateUser(
				in_act_id						=> security_pkg.GetACT,
				in_parent_sid				=> v_built_in,
				in_login_name				=> 'Invitation Respondent',
				in_class_id					=> class_pkg.GetClassID('User'),
				in_account_expiry_enabled	=> 0,
				out_user_sid				=> v_respondent
			);
	END;
	
	BEGIN
		INSERT INTO csr.issue_type (issue_type_id, label)
		VALUES(csr.csr_data_pkg.ISSUE_SUPPLIER, 'Supplier action');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	csr.csr_data_pkg.EnableCapability('Manage chain capabilities', 1);
	v_cap_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Manage chain capabilities');
	
	securableobject_pkg.SetFlags(SYS_CONTEXT('SECURITY','ACT'), v_cap_sid, 0);
	acl_pkg.DeleteAllACEs(SYS_CONTEXT('SECURITY','ACT'), Acl_pkg.GetDACLIDForSID(v_cap_sid));
	
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), Acl_pkg.GetDACLIDForSID(v_cap_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), security_pkg.SID_ROOT, 'csr/SuperAdmins'), security_pkg.PERMISSION_WRITE);	
	
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), Acl_pkg.GetDACLIDForSID(SYS_CONTEXT('SECURITY','APP')), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, csr.csr_data_pkg.PERMISSION_ALTER_SCHEMA);		
END;

/****************************************************************************************
	CREATE SECURABLE OBJECTS
****************************************************************************************/
PROCEDURE CreateSOs (
	in_overwrite_default_url		BOOLEAN,
	in_is_single_tier				BOOLEAN,
	in_overwrite_logon_url			BOOLEAN,
	in_create_menu_items			BOOLEAN,
	in_alter_existing_attributes	BOOLEAN
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'RegisteredUsers');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_app_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Administrators');
	v_admins_sid			security_pkg.T_SID_ID; -- chain admins
	v_users_sid				security_pkg.T_SID_ID;
	v_suppliers_role_sid	security_pkg.T_SID_ID; -- Groups/Suppliers	
	v_user_container_sid	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users');
	v_ucd_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_user_container_sid, 'UserCreatorDaemon');
	v_indicators_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Indicators');
	v_chain_sid				security_pkg.T_SID_ID;
	v_companies_sid			security_pkg.T_SID_ID;
	v_www_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_www_sid, 'csr');
	v_www_csr_site_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_www_sid, 'csr/site');
	v_www_my_details_sid	security_pkg.T_SID_ID;
	v_csr_site_chain_sid    security_pkg.T_SID_ID;
	v_csr_site_alerts_sid   security_pkg.T_SID_ID;
	v_chain_cards_sid 		security_pkg.T_SID_ID;
	v_chain_components_sid 	security_pkg.T_SID_ID;
	v_chain_public_sid 		security_pkg.T_SID_ID;
	v_www_csr_shared_sid	security_pkg.T_SID_ID;
	v_alerts_mergeFld_sid   security_pkg.T_SID_ID;
	v_csr_site_company_sid  security_pkg.T_SID_ID;
	
	v_dacl_id    			security_Pkg.T_ACL_ID;
	
	v_menu  				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu'); 
	v_login_menu  			security_pkg.T_SID_ID;
	v_logout_menu  			security_pkg.T_SID_ID;
	v_chain_menu			security_pkg.T_SID_ID;
	v_admin_menu			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
	v_setup_menu			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'setup');
	v_superadmins_sid 		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_new_menu				security_pkg.T_SID_ID;
	v_built_in				security_pkg.T_SID_ID;
	v_respondent			security_pkg.T_SID_ID;
	
	v_count					NUMBER(10);
BEGIN
	/**************************************************************************************
		CREATE GROUPS
	**************************************************************************************/
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, v_group_sid, security_pkg.GROUP_TYPE_SECURITY, chain.chain_pkg.CHAIN_ADMIN_GROUP, v_admins_sid);

			-- give the group ALL permission on itself
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_admins_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
			
			-- give the group ALL permission on INDICATORS so that we can create users
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_indicators_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END;
	
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_USER_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, v_group_sid, security_pkg.GROUP_TYPE_SECURITY, chain.chain_pkg.CHAIN_USER_GROUP, v_users_sid);

			-- give the group READ permission on itself
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_users_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	IF in_is_single_tier THEN
		BEGIN
			v_suppliers_role_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Suppliers');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				csr.role_pkg.SetRole(
					security_pkg.getACT,
					security_pkg.GetApp,
					'Suppliers',
					'SUPPLIERS',
					v_suppliers_role_sid
					);
				UPDATE csr.role
				   SET is_supplier = 1
				 WHERE role_sid = v_suppliers_role_sid;
		END;
	END IF;
	
	/**************************************************************************************
		ADD OBJECTS TO GROUPS
	**************************************************************************************/
	-- add the Chain Administrators group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	
	-- add the Administrators group to the Chain Administrators group
	group_pkg.AddMember(v_act_id, v_app_admins_sid, v_admins_sid);
	
	-- add UserCreatorDaemon to the Chain Administratos group so that it can create companies and users
	group_pkg.AddMember(v_act_id, v_ucd_sid, v_admins_sid);
	
	/**************************************************************************************
		CREATE CONTAINERS
	**************************************************************************************/
	BEGIN
		v_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Chain', v_chain_sid);

			securableobject_pkg.SetFlags(v_act_id, v_chain_sid, 0);			
			
			security.ACL_Pkg.GetNewID(v_dacl_id);
			
			acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
			
			acl_pkg.SetDACL(v_act_id, v_chain_sid, v_dacl_id);
	END;
	
	BEGIN
		v_companies_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_chain_sid, 'Companies');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, v_chain_sid, security_pkg.SO_CONTAINER, 'Companies', v_companies_sid);
	END;	

	BEGIN
		v_built_in := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_chain_sid, 'BuiltIn');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND then
			securableobject_pkg.CreateSO(security_pkg.GetACT, v_chain_sid, class_pkg.GetClassID('Container'), 'BuiltIn', v_built_in);
	END;
	
	/**************************************************************************************
		CREATE BUILT IN DAEMON USER
	**************************************************************************************/

	BEGIN
		v_respondent := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_built_in, 'Invitation Respondent');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND then

			user_pkg.CreateUser(
				in_act_id						=> security_pkg.GetACT,
				in_parent_sid				=> v_built_in,
				in_login_name				=> 'Invitation Respondent',
				in_class_id					=> class_pkg.GetClassID('User'),
				in_account_expiry_enabled	=> 0,
				out_user_sid				=> v_respondent
			);

			-- we need to stuff this user into the csr user so that we can use it within chain as well
			INSERT INTO csr.csr_user
			(csr_user_sid, guid, user_name, friendly_name, send_alerts, show_portal_help, hidden)
			VALUES
			(v_respondent, user_pkg.GenerateAct, 'Invitation Respondent', 'Chain Invitation Respondent', 0, 0, 1);
			
			-- add the user to chain
			helper_pkg.AddUserToChain(v_respondent);
			
			security.group_pkg.AddMember(security_pkg.GetAct, v_respondent, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Chain Users'));
			
			-- grant all on the user container
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_user_container_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_respondent, security_pkg.PERMISSION_STANDARD_ALL);	
	END;	
	
	/**************************************************************************************
		CREATE WEB RESOURCES
	**************************************************************************************/
	BEGIN
		v_csr_site_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'chain');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_sid, 'chain', v_csr_site_chain_sid);	
			
			-- give the Chain Users group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_csr_site_chain_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		v_www_my_details_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'myDetails.acds');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'myDetails.acds', v_www_my_details_sid);
			
			-- give the RegisteredUsers group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_www_my_details_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	BEGIN
		v_chain_public_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'public');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'public', v_chain_public_sid);	
			
			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_public_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		v_chain_components_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'components');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'components', v_chain_components_sid);	

			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_components_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		-- This is created by createsite now, but may be needed if upgrading an existing site that doesn't have it.
		v_www_csr_shared_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_sid, 'shared');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_sid, 'shared', v_www_csr_shared_sid);
	END;
	FOR r IN (
		SELECT 1
		  FROM dual
		-- WHERE NOT EXISTS (SELECT 1 FROM security.acl WHERE sid_id = v_everyone_sid AND acl_id IN (SELECT dacl_id FROM security.securable_object WHERE sid_id = v_www_csr_shared_sid))
	) LOOP
		-- give the Everyone group READ permission on the resource if it doesn't have it already
		acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_www_csr_shared_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END LOOP;
	
	BEGIN
		v_chain_cards_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'cards');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'cards', v_chain_cards_sid);	

			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_cards_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	v_csr_site_alerts_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'alerts');
	BEGIN
		v_alerts_mergeFld_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_alerts_sid, 'renderMergeField.ashx');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_alerts_sid, 'renderMergeField.ashx', v_alerts_mergeFld_sid);	

			-- give the Chain Users group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_alerts_mergeFld_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		v_csr_site_company_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'company');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_sid, 'company', v_csr_site_company_sid);	
			
			-- give the Chain Users group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_csr_site_company_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	/**************************************************************************************
		CREATE MENUS
	**************************************************************************************/
	
	IF in_create_menu_items THEN
	-- chain top level
		BEGIN
			v_chain_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_menu, 'chain',  'Supply Chain',  '/csr/site/chain/dashboard.acds',  1, null, v_chain_menu);
		
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_chain_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- chain dashboard
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_dashboard');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_dashboard',  'Dashboard',  '/csr/site/chain/dashboard.acds',  102, null, v_new_menu);
			
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Manage company
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_company_management');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_company_management',  'Company management',  '/csr/site/chain/manageCompany/manageCompany.acds',  103, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Actions
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_actions');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_actions',  'Activity browser',  '/csr/site/chain/activityBrowser.acds',  104, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Questionnaire Management
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_q_management');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_q_management',  'Questionnaires',  '/csr/site/chain/questionnaireManagement.acds',  105, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Search for supplier
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_filter_suppliers');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_filter_suppliers',  'Search suppliers',  '/csr/site/chain/filterSuppliers.acds',  106, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Super admin menu
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'chain_super_admin_menu');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'chain_super_admin_menu',  'Super admin menu',  '/csr/site/chain/admin/menu.acds',  106, null, v_new_menu);
				
				security.securableObject_pkg.ClearFlag(v_act_id, v_new_menu, security.security_pkg.SOFLAG_INHERIT_DACL); 
				security.acl_pkg.DeleteAllACEs(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu));
				security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_superadmins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Change my user details
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_my_details');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_my_details',  'My details',  '/csr/site/chain/myDetails.acds',  21, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Change my company details
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_my_company');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_my_company',  'My company',  '/csr/site/chain/myCompany.acds',  22, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- Manage Company plugins setup
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_manage_company_plugins');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_manage_company_plugins',  'Supply Chain plugins',  '/csr/site/chain/manageCompany/admin/managePlugins.acds',  23, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_superadmins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Company type management
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_admin_company_type');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_admin_company_type',  'Company types',  '/csr/site/chain/admin/companyType.acds',  24, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_superadmins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Supply Chain permissions
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_admin_permissions');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_admin_permissions',  'Supply Chain permissions',  '/csr/site/chain/admin/permissions.acds',  25, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_superadmins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		/* BEGIN
			v_chain_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
		EXCEPTION  --Do all chain host support chain menu?
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				v_chain_menu := NULL;
		END; */
		
		--Invite a company
		BEGIN	
			v_new_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'invite_company');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'invite_company',  'Invite a company',  '/csr/site/chain/companyInvitation.acds',  106, null, v_new_menu);
				security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		/* 
		-- Company types
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_company_type');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_company_type',  'Company types',  '/csr/site/chain/admin/companyType.acds',  24, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END; */
		
		-- dev page
		/*BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_dev_open_invites');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_dev_open_invites',  'DEV - Open Invitations',  '/csr/site/chain/dev/OpenInvitations.acds',  100, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_app_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		-- dev page
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_dev_manage_companies');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_dev_manage_companies',  'DEV - Manage Companies',  '/csr/site/chain/dev/ManageCompanies.acds',  101, null, v_new_menu);
				
				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_app_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;*/
	END IF;
	
	/**************************************************************************************
			ALTER EXISTING SO ATTRIBUTES
	**************************************************************************************/

	IF in_alter_existing_attributes THEN
		IF in_overwrite_logon_url THEN
			v_login_menu := securableobject_pkg.GetSIDFromPath(v_act_id, v_menu, 'login'); 
			v_logout_menu := securableobject_pkg.GetSIDFromPath(v_act_id, v_menu, 'logout'); 
			security.menu_pkg.SetMenuAction(v_act_id, v_login_menu, '/csr/site/chain/public/login.acds');
			security.menu_pkg.SetMenuAction(v_act_id, v_logout_menu, '/fp/aspen/public/logout.asp?page=%2fcsr%2fsite%2fchain%2fpublic%2flogin.acds%3floggedoff%3d1');

			UPDATE aspen2.application 
			   SET logon_url = '/csr/site/chain/public/login.acds'
			 WHERE app_sid = v_app_sid;

		END IF;
		IF in_overwrite_default_url THEN
			UPDATE aspen2.application 
			   SET default_url = '/csr/site/chain/dashboard.acds'
			 WHERE app_sid = v_app_sid;
		END IF;
	END IF;
	
	/**************************************************************************************
			SET OPTIONS
	**************************************************************************************/
	-- update the self reg group unless it's already been set
	UPDATE csr.customer
	   SET self_reg_group_sid = v_reg_users_sid
	 WHERE app_Sid = security_pkg.GetApp
	   AND self_reg_group_sid IS NULL;
	
	-- ensure that self reg doesn't need approval
	UPDATE csr.customer
	   SET self_reg_needs_approval = 0
	 WHERE app_Sid = security_pkg.GetApp;

	UPDATE csr.customer
	   SET show_additional_audit_info = 0
	 WHERE app_sid = security_pkg.GetApp;
	
	BEGIN
		INSERT INTO chain.customer_options (app_sid) VALUES (v_app_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
	
	-- add the ucd to chain 
	chain.helper_pkg.AddUserToChain(v_ucd_sid);
	
	/**************************************************************************************
			MISC
	**************************************************************************************/
	
	-- this is required for rejecting invitations
	FOR s IN (
		SELECT v_user_container_sid sid_id FROM DUAL
		 UNION ALL
		SELECT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Trash') sid_id FROM DUAL
		 UNION ALL
		SELECT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'chain/companies') sid_id FROM DUAL
	) LOOP

		acl_pkg.AddACE(
			v_act_id, 
			acl_pkg.GetDACLIDForSID(s.sid_id), 
			security_pkg.ACL_INDEX_LAST, 
			security_pkg.ACE_TYPE_ALLOW, 
			security_pkg.ACE_FLAG_DEFAULT, 
			v_ucd_sid, 
			security_pkg.PERMISSION_STANDARD_ALL
		);	

		acl_pkg.PropogateACEs(v_act_id, s.sid_id);
	END LOOP;
END;

PROCEDURE SetupPlugin(
	in_page_company_type_id		company.company_type_id%TYPE,
	in_user_company_type_id		company.company_type_id%TYPE,
	in_label					company_tab.label%TYPE,
	in_js_class					csr.plugin.js_class%TYPE,
	in_viewing_own_company		company_tab.viewing_own_company%TYPE DEFAULT 1
)
AS
	v_plugin_id 		NUMBER := csr.plugin_pkg.GetPluginId(in_js_class);
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_tab
	 WHERE page_company_type_id = in_page_company_type_id
	   AND user_company_type_id = in_user_company_type_id
	   AND viewing_own_company = in_viewing_own_company
	   AND plugin_id = v_plugin_id;

	IF v_count = 0 THEN
		plugin_pkg.AddCompanyTab(
			in_plugin_id			=>	v_plugin_id,
			in_pos					=>	-1,
			in_label				=>	in_label,
			in_page_company_type_id	=>	in_page_company_type_id,
			in_user_company_type_id	=>	in_user_company_type_id,
			in_viewing_own_company	=>  in_viewing_own_company,
			in_options				=>  NULL
		);
	END IF;
END;

PROCEDURE SetupDefaultPlugins (
	in_top_company_type			IN  VARCHAR2
)
AS
	v_top_company_type_id		company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId(in_top_company_type);
BEGIN

	SetupPlugin(
		in_page_company_type_id	=> v_top_company_type_id,
		in_user_company_type_id	=> v_top_company_type_id,
		in_label				=> 'Suppliers',
		in_js_class				=> 'Chain.ManageCompany.SupplierListTab'
	);

	FOR r IN (
		SELECT company_type_id
		  FROM company_type
		 WHERE is_top_company = 0
	)
	LOOP
		SetupPlugin(
			in_user_company_type_id	=> r.company_type_id,
			in_page_company_type_id	=> r.company_type_id,
			in_label				=> 'Company details',
			in_js_class				=> 'Chain.ManageCompany.CompanyDetails',
			in_viewing_own_company	=> 1
		);
	END LOOP;

	FOR r IN (
		SELECT primary_company_type_id, secondary_company_type_id
		  FROM company_type_relationship
	)
	LOOP
		SetupPlugin(
			in_user_company_type_id	=> r.primary_company_type_id,
			in_page_company_type_id	=> r.secondary_company_type_id,
			in_label				=> 'Company details',
			in_js_class				=> 'Chain.ManageCompany.CompanyDetails',
			in_viewing_own_company	=> 0
		);
	END LOOP;
END;

PROCEDURE SetupSupplierFlow
AS
	v_purchaser_inv_type_id			csr.flow_involvement_type.flow_involvement_type_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class) VALUES ('supplier');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	
	
	--FB68192: involvement types now linked to app, so create the standard supplier types
	BEGIN
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class, lookup_key)
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER, 'supplier', 'Purchaser', 'CSRUser', chain_pkg.PURCHASER_INV_TYPE_KEY);

		INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER, 'supplier');

		chain.supplier_flow_pkg.SetSupplierInvolvementType(
			in_involvement_type_id			=> csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER,
			in_user_company_type_id			=> NULL,
			in_page_company_type_id			=> NULL,
			in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
			in_restrict_to_role_sid			=> NULL
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	BEGIN	
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER, 'supplier', 'Supplier', 'CSRUser');

		INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
		VALUES (SYS_CONTEXT('SECURITY','APP'), csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER, 'supplier');

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	INSERT INTO csr.flow_inv_type_alert_class(flow_involvement_type_id, flow_alert_class)
	SELECT csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER, cfac.flow_alert_class
	  FROM csr.customer_flow_alert_class cfac
	 WHERE cfac.flow_alert_class IN ('audit', 'campaign')
	   AND NOT EXISTS(
			SELECT 1
			  FROM csr.flow_inv_type_alert_class fitac
			 WHERE fitac.app_sid = cfac.app_sid
			   AND fitac.flow_alert_class = cfac.flow_alert_class
			   AND fitac.flow_involvement_type_id = csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER
	   );

END;

PROCEDURE EnableSiteINTERNAL (
	in_site_name					customer_options.site_name%TYPE,
	in_support_email				customer_options.support_email%TYPE,
	in_overwrite_default_url		BOOLEAN,
	in_create_sectors				BOOLEAN,
	in_is_single_tier				BOOLEAN,
	in_overwrite_logon_url			BOOLEAN,
	in_enable_csr_supplier			BOOLEAN,
	in_enable_type_capabilities		BOOLEAN,
	in_create_menu_items			BOOLEAN,
	in_alter_existing_attributes	BOOLEAN,
	in_overwrite_home_page			BOOLEAN,
	in_lock_tree					BOOLEAN,
	in_supplier_flow				BOOLEAN,
	in_force_login_as_company		NUMBER DEFAULT 1
)
AS
	v_system_import_source_id		import_source.import_source_id%TYPE;
BEGIN
	CreateSOs(in_overwrite_default_url, in_is_single_tier, in_overwrite_logon_url, in_create_menu_items, in_alter_existing_attributes);
	
	SetupCore(in_site_name, in_support_email, in_overwrite_home_page, in_lock_tree);
	
	IF in_enable_type_capabilities THEN
		type_capability_pkg.EnableSite;
	END IF;
	
	IF in_enable_csr_supplier THEN
		AddSupplierImplementation();
		-- only used as a lookup key - may not actually be needed going forward but still here for now
		IF NOT HasImplementation('CSR.'||NVL(in_site_name, 'STANDARD')) THEN
			AddImplementation('CSR.'||NVL(in_site_name, 'STANDARD'), NULL);
		END IF;
	END IF;

	IF in_supplier_flow THEN
		SetupSupplierFlow();
	END IF;
	
	SetupPortlets(in_is_single_tier);
	SetupCsrAlerts();
	SetupCardManagers(in_enable_csr_supplier);
	--SetupComponents();
	
	IF in_create_sectors THEN
		CreateSectors();
	END IF;
	
	BEGIN
		INSERT INTO import_source (app_sid, import_source_id, name, position, dedupe_no_match_action_id, lookup_key, is_owned_by_system)
		VALUES (security_pkg.GetApp, import_source_id_seq.nextval, 'User interface', 0, 1, 'SystemUI', 1)
		RETURNING import_source_id INTO v_system_import_source_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT import_source_id
			  INTO v_system_import_source_id
			  FROM import_source
			 WHERE is_owned_by_system = 1;
	END;
	
	dedupe_admin_pkg.SetSystemDefaultMapAndRules;
	
	UPDATE chain.customer_options
	   SET force_login_as_company = in_force_login_as_company;
END;

FUNCTION CreateCompanyINTERNAL (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE,
	in_is_top_company				IN BOOLEAN,
	in_skip_menus					IN BOOLEAN DEFAULT FALSE
) RETURN security_pkg.T_SID_ID
AS
	v_act_id						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid						security_pkg.T_ACT_ID DEFAULT security_pkg.GetApp;
	v_admin_menu					security_pkg.T_ACT_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin');
	v_company_sid					security_pkg.T_SID_ID;
	
	v_company_admin_group_sid		security_pkg.T_SID_ID;
	v_company_users_group_sid		security_pkg.T_SID_ID;
	--v_chain_users_group_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Chain Users'); -- commented this out as it's only used on line 1048, which is also commented out...
	v_menu_sid						security_pkg.T_SID_ID;
	
	v_nullStringArray 				chain_pkg.T_STRINGS; --cannot pass NULL so need an empty varchar2 array instead
BEGIN		
	BEGIN
		company_pkg.CreateUniqueCompany(in_company_name, in_country_code, chain.company_type_pkg.GetCompanyTypeId(in_company_type), NULL, v_nullStringArray, v_nullStringArray, v_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_company_sid := securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Chain/Companies/'||in_company_name||' ('||in_country_code||')');
	END;
	
	company_pkg.ActivateCompany(v_company_sid);
	
	-- get the company Admin and Users group and add permissions to certain menu items
	v_company_admin_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_company_sid, 'Administrators');
	v_company_users_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_company_sid, 'Users');
	-- this relies on enableChain having been run but that is checked for elsewhere first
	IF NOT in_skip_menus THEN
		v_menu_sid := securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.GetApp, 'menu/chain/chain_filter_suppliers');
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security_pkg.ACE_TYPE_ALLOW, 
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_company_admin_group_sid, security_pkg.PERMISSION_STANDARD_READ);
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security_pkg.ACE_TYPE_ALLOW, 
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_company_users_group_sid, security_pkg.PERMISSION_STANDARD_READ);
	END IF;
	
	-- TODO: Why are we doing this? (comment it out for now as it doesn't seem right)
	-- XPJ Response: The reason for this (as part of the original setup when this only created
	-- the top company) was to restrict access to the chain module from "normal" CSR users
	-- where we have CSR / Chain systems running in the same site. Instead, any users at the
	-- top company would need to be in the "Supply chain managers" group to get access to the module.
	--group_pkg.DeleteMember(security_pkg.GetAct, v_company_users_group_sid, v_chain_users_group_sid);
	
	IF in_is_top_company THEN
		UPDATE customer_options
		   SET top_company_sid = v_company_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		IF helper_pkg.UseTraditionalCapabilities THEN		
			capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.IS_TOP_COMPANY);
			ApplyExtendedCapabilities(v_company_sid);
		END IF;	
		
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_dedupe_records', 'De-dupe records', '/csr/site/chain/dedupe/processedRecords.acds', 2, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_company_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_company_requests', 'Review company requests', '/csr/site/chain/companyRequest/companyRequestList.acds', 2, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_company_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;
	
	RETURN v_company_sid;
END;

FUNCTION CreateSubCompanyINTERNAL (
	in_parent_sid					IN security_pkg.T_ACT_ID,
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_act_id						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid					security_pkg.T_SID_ID;
	
	v_company_admin_group_sid		security_pkg.T_SID_ID;
	v_company_users_group_sid		security_pkg.T_SID_ID;
	--v_chain_users_group_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Chain Users'); -- commented this out as it's only used on line 1048, which is also commented out...
	v_menu_sid						security_pkg.T_SID_ID;
	
	v_nullStringArray 				chain_pkg.T_STRINGS; --cannot pass NULL so need an empty varchar2 array instead
BEGIN		
	BEGIN
		company_pkg.CreateSubCompany(in_parent_sid, in_company_name, in_country_code, chain.company_type_pkg.GetCompanyTypeId(in_company_type), NULL, v_nullStringArray, v_nullStringArray, v_company_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT company_sid
			  INTO v_company_sid
			  FROM company
			 WHERE parent_sid = in_parent_sid
			   AND LOWER(name) = LOWER(in_company_name);
	END;
	
	company_pkg.ActivateCompany(v_company_sid);
	
	RETURN v_company_sid;
END;

/*********************************************************************************

	PUBLIC

*********************************************************************************/

PROCEDURE EnableSiteLightweight
AS
BEGIN
	VerifySetupPermission('EnableSite', TRUE);
	
	EnableSiteINTERNAL(
		in_site_name => NULL,
		in_support_email => NULL,
		in_overwrite_default_url => FALSE,
		in_create_sectors => FALSE,
		in_is_single_tier => TRUE,
		in_overwrite_logon_url => FALSE, 
		in_enable_csr_supplier => TRUE,
		in_enable_type_capabilities => TRUE,
		in_create_menu_items => FALSE,
		in_alter_existing_attributes => FALSE,
		in_overwrite_home_page => FALSE,
		in_lock_tree => FALSE,
		in_supplier_flow => TRUE,
		in_force_login_as_company => 0
	);
END;

PROCEDURE EnableSite (
	in_site_name					customer_options.site_name%TYPE DEFAULT NULL,
	in_support_email				customer_options.support_email%TYPE DEFAULT NULL,
	in_overwrite_default_url		BOOLEAN DEFAULT FALSE,
	in_create_sectors				BOOLEAN DEFAULT FALSE,
	in_is_single_tier				BOOLEAN DEFAULT TRUE,
	in_overwrite_logon_url			BOOLEAN DEFAULT TRUE,
	in_enable_csr_supplier			BOOLEAN DEFAULT TRUE
)
AS
BEGIN
	VerifySetupPermission('EnableSite', TRUE);
	
	EnableSiteINTERNAL(
		in_site_name => in_site_name,
		in_support_email => in_support_email, 
		in_overwrite_default_url => in_overwrite_default_url, 
		in_create_sectors => in_create_sectors, 
		in_is_single_tier => in_is_single_tier, 
		in_overwrite_logon_url => in_overwrite_logon_url, 
		in_enable_csr_supplier => in_enable_csr_supplier,
		in_enable_type_capabilities => TRUE, -- all new sites should use type capabilities
		in_create_menu_items => TRUE,
		in_alter_existing_attributes => TRUE,
		in_overwrite_home_page => TRUE,
		in_lock_tree => TRUE,
		in_supplier_flow => TRUE
	);
END;

PROCEDURE ReApplyEnableSite (
	in_is_single_tier			BOOLEAN DEFAULT TRUE
)
AS
BEGIN
	VerifySetupPermission('ReApplyEnableSite');
	
	IF NOT IsChainEnabled THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain has not yet been enabled. Consider running EnableSite instead.');
	END IF;

	EnableSiteINTERNAL(
		in_site_name => NULL,
		in_support_email => NULL, 
		in_overwrite_default_url => FALSE, 
		in_create_sectors => FALSE, 
		in_is_single_tier => in_is_single_tier, 
		in_overwrite_logon_url => FALSE, 
		in_enable_csr_supplier => FALSE,
		in_enable_type_capabilities => FALSE, -- keep it what ever it's currently set to
		in_create_menu_items => FALSE,
		in_alter_existing_attributes => FALSE,
		in_overwrite_home_page => FALSE,
		in_lock_tree => FALSE,
		in_supplier_flow => FALSE
	);
END;

PROCEDURE EnableOneTier (
	in_top_company_singular			IN company_type.singular%TYPE DEFAULT 'Top company',
	in_top_company_plural			IN company_type.plural%TYPE DEFAULT 'Top companies',
	in_top_company_allow_lower		IN BOOLEAN DEFAULT TRUE,
	in_top_company_key				IN company_type.lookup_key%TYPE DEFAULT 'TOP'
)
AS
BEGIN
	VerifySetupPermission('EnableOneTier');

	company_type_pkg.AddCompanyType(in_top_company_key, in_top_company_singular, in_top_company_plural, in_top_company_allow_lower, TRUE, NULL, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
	company_type_pkg.SetTopCompanyType(in_top_company_key);
	
	ApplyExtendedCapabilities(in_top_company_key);
	
	SetupDefaultPlugins(in_top_company_key);
END;

PROCEDURE EnableTwoTier (
	in_top_company_singular			IN company_type.singular%TYPE DEFAULT 'Company',
	in_top_company_plural			IN company_type.plural%TYPE DEFAULT 'Companies',
	in_top_company_allow_lower		IN BOOLEAN DEFAULT TRUE,
	in_top_company_key				IN company_type.lookup_key%TYPE DEFAULT 'TOP',
	in_supplier_singular			IN company_type.singular%TYPE DEFAULT 'Supplier',
	in_supplier_plural				IN company_type.plural%TYPE DEFAULT 'Suppliers',
	in_supplier_allow_lower			IN BOOLEAN DEFAULT TRUE,
	in_supplier_key					IN company_type.lookup_key%TYPE DEFAULT 'SUPPLIERS'
)
AS
BEGIN
	VerifySetupPermission('EnableTwoTier');

	company_type_pkg.AddDefaultCompanyType(in_supplier_key, in_supplier_singular, in_supplier_plural, in_supplier_allow_lower, TRUE, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
	company_type_pkg.AddCompanyType(in_top_company_key, in_top_company_singular, in_top_company_plural, in_top_company_allow_lower, TRUE, NULL, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
	company_type_pkg.AddCompanyTypeRelationship(in_top_company_key, in_supplier_key);
	company_type_pkg.SetTopCompanyType(in_top_company_key);
	
	company_type_pkg.SetCompanyTypePositions(T_STRING_LIST(in_top_company_key, in_supplier_key));
	
	ApplyExtendedCapabilities(in_top_company_key);
	
	SetupDefaultPlugins(in_top_company_key);
END;

PROCEDURE EnableThreeTierHolding (
	in_top_company_singular				IN company_type.singular%TYPE DEFAULT 'Company',
	in_top_company_plural				IN company_type.plural%TYPE DEFAULT 'Companies',
	in_top_company_allow_lower			IN BOOLEAN DEFAULT TRUE,
	in_top_company_key					IN company_type.lookup_key%TYPE DEFAULT 'TOP',
	in_holding_singular					IN company_type.singular%TYPE DEFAULT 'Holding company',
	in_holding_plural					IN company_type.plural%TYPE DEFAULT 'Holding companies',
	in_holding_allow_lower				IN BOOLEAN DEFAULT TRUE,
	in_holding_key						IN company_type.lookup_key%TYPE DEFAULT 'HOLDING',
	in_site_singular					IN company_type.singular%TYPE DEFAULT 'Site',
	in_site_plural						IN company_type.plural%TYPE DEFAULT 'Sites',
	in_site_allow_lower					IN BOOLEAN DEFAULT TRUE,
	in_site_key							IN company_type.lookup_key%TYPE DEFAULT 'SITES'
)
AS
BEGIN
	VerifySetupPermission('EnableThreeTierHolding');
	
	company_type_pkg.AddDefaultCompanyType(in_site_key, in_site_singular, in_site_plural, in_site_allow_lower, TRUE, csr.csr_data_pkg.REGION_TYPE_PROPERTY);
	company_type_pkg.AddCompanyType(in_top_company_key, in_top_company_singular, in_top_company_plural, in_top_company_allow_lower, TRUE, NULL, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
	company_type_pkg.AddCompanyType(in_holding_key, in_holding_singular, in_holding_plural, in_holding_allow_lower, TRUE, NULL, csr.csr_data_pkg.REGION_TYPE_SUPPLIER);
		
	company_type_pkg.AddCompanyTypeRelationship(in_top_company_key, in_site_key);
	company_type_pkg.AddCompanyTypeRelationship(in_top_company_key, in_holding_key);
	company_type_pkg.AddCompanyTypeRelationship(in_holding_key, in_site_key);
	
	company_type_pkg.SetTopCompanyType(in_top_company_key);
	
	company_type_pkg.SetCompanyTypePositions(T_STRING_LIST(in_top_company_key, in_holding_key, in_site_key));

	ApplyExtendedCapabilities(in_top_company_key);
	ApplyExtendedCapabilities(in_holding_key);
	
	-- Admins to send invites
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_INVITE_ON_BEHALF_OF);
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_COMPANY_INVITE);

	-- Category users can't send invites
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_INVITE_ON_BEHALF_OF, FALSE);
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_COMPANY_INVITE, FALSE);

	-- Can't send questionnaires to holding companies
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE, FALSE);
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE, FALSE);

	-- Admins to send questionnaires to sites
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE, TRUE);
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE, FALSE);

	-- Remove access to holding company users to set their own username
	type_capability_pkg.SetPermission(in_holding_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMPANY, chain_pkg.SPECIFY_USER_NAME, FALSE);

	-- Give admins access to delete supplier sites
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.ADMIN_GROUP, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE+ security_pkg.PERMISSION_DELETE);

	-- Remove MnS normal users access to promote supplier users
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER, FALSE);
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER, FALSE);

	-- Remove MnS normal users access to change supplier details 
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.USER_GROUP, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);

	-- Remove MnS normal users access to invite suppliers 
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, chain_pkg.USER_GROUP, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);
	type_capability_pkg.SetPermission(in_top_company_key, in_site_key, chain_pkg.USER_GROUP, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ);

	-- Grant access for site users to submit surveys
	type_capability_pkg.SetPermission(in_site_key, chain.chain_pkg.USER_GROUP, chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SUBMIT_QUESTIONNAIRE);
	
	-- Grant access for top company users to send questionnaire invitations to sites on behalf of holding companies
	type_capability_pkg.SetPermission(in_top_company_key, in_holding_key, in_site_key, chain.chain_pkg.USER_GROUP, chain.chain_pkg.QNR_INVITE_ON_BEHALF_OF);
	
	chain.card_pkg.SetGroupCards('Questionnaire Invitation Wizard', chain.T_STRING_LIST(
		'Chain.Cards.InviteCompanyType', 
		'Chain.Cards.AddCompany', -- createnew or default
		'Chain.Cards.CreateCompany',
		'Chain.Cards.AddUser',
		'Chain.Cards.CreateUser',
		'Chain.Cards.InvitationSummary'
	));
	
	chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'),
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')
	));
	chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.CreateCompany', 'Chain.Cards.CreateUser');
	chain.card_pkg.MarkTerminate('Questionnaire Invitation Wizard', 'Chain.Cards.InvitationSummary');

	chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'),
		chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')
	));
	
	SetupDefaultPlugins(in_top_company_key);
END;

FUNCTION CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS		
BEGIN		
	VerifySetupPermission('CreateCompany');

	IF helper_pkg.UseTraditionalCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'This site does NOT use type capabilities - in_is_top_company (boolean) must be explicitly set as the last parameter.');
	END IF;
	
	RETURN CreateCompanyINTERNAL(in_company_name, in_country_code, in_company_type, company_type_pkg.IsTopCompanyType(in_company_type));
END;

FUNCTION CreateSubCompany (
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS		
BEGIN		
	VerifySetupPermission('CreateCompany');

	IF helper_pkg.UseTraditionalCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'This site does NOT use type capabilities - in_is_top_company (boolean) must be explicitly set as the last parameter.');
	END IF;
	
	RETURN CreateSubCompanyINTERNAL(in_parent_sid, in_company_name, in_country_code, in_company_type);
END;

FUNCTION CreateCompanyLightweight (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	VerifySetupPermission('CreateCompany');

	IF helper_pkg.UseTraditionalCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'This site does NOT use type capabilities - in_is_top_company (boolean) must be explicitly set as the last parameter.');
	END IF;
	
	RETURN CreateCompanyINTERNAL(
		in_company_name => in_company_name, 
		in_country_code => in_country_code, 
		in_company_type => in_company_type,
		in_is_top_company => company_type_pkg.IsTopCompanyType(in_company_type),
		in_skip_menus => true
	);
END;

PROCEDURE CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE
)
AS
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	v_company_sid := CreateCompany(in_company_name, in_country_code, in_company_type);
END;

FUNCTION CreateCompany (
	in_company_name					IN company.name%TYPE,
	in_country_code					IN company.country_code%TYPE,
	in_company_type					IN company_type.lookup_key%TYPE,
	in_is_top_company				IN BOOLEAN
) RETURN security_pkg.T_SID_ID
AS
BEGIN		
	VerifySetupPermission('CreateCompany');

	IF helper_pkg.UseTypeCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'This site uses type capabilities and does not support explicit definition of in_is_top_company. This variable needs to be removed.');
	END IF;
	
	RETURN CreateCompanyINTERNAL(in_company_name, in_country_code, in_company_type, in_is_top_company);
END;

PROCEDURE AddUsersToCompany (
	in_company_sid					IN security_pkg.T_SID_ID,
	in_filter_by_email_ends_in		IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	VerifySetupPermission('AddUsersToCompany');

	-- set the company sid in the sys context
	security_pkg.SetContext('CHAIN_COMPANY', in_company_sid);

	FOR r IN (
		SELECT cu.csr_user_sid, cu.user_name
		  FROM csr.csr_user cu, security.securable_object so, csr.customer c
		 WHERE cu.app_sid = c.app_sid
		   AND cu.csr_user_sid = so.sid_id
		   AND so.parent_sid_id != c.trash_sid
		   AND cu.hidden = 0
		   AND cu.email LIKE '%'||in_filter_by_email_ends_in
		   AND csr_user_sid NOT IN (
			SELECT user_sid FROM chain.chain_user
		 ) AND csr_user_sid NOT IN (
			SELECT csr_user_sid FROM csr.superadmin
		 )
	) LOOP
		INSERT INTO chain.chain_user
		(user_sid, visibility_id, registration_status_id, default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
		VALUES (
			r.csr_user_sid, chain_pkg.NAMEJOBTITLE, 
			chain_pkg.REGISTERED, 
			in_company_sid, 
			chain_pkg.ACTIVE, 
			1
		);

		-- make them members of topco
		chain.company_user_pkg.AddUserToCompany(in_company_sid, r.csr_user_sid);

		-- already done by AddUserToCompany but a comment in the AddUserToCompany code 
		-- looks like it might get removed at some point so let's play safe
		chain.company_user_pkg.ApproveUser(in_company_sid, r.csr_user_sid);
	END LOOP;

	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

FUNCTION CreateUserGroupForCompany (
	in_company_sid					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	-- Create a group for top company users to sit in
	security.group_pkg.CreateGroup(
		v_act_id,
		securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.getApp, 'Groups'),
		security_pkg.GROUP_TYPE_SECURITY,
		'Top company users',
		v_group_sid
	);
	
	-- Add the company's users group to the new group
	security.group_pkg.AddMember(
		v_act_id,
		securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, 'Users'),
		v_group_sid
	);
	
	-- alter permissions so that no one else can add to the group
	security.acl_pkg.DeleteAllACEs(
		v_act_id,
		security.acl_pkg.GetDACLIDForSID(v_group_sid)
	);
	security.securableObject_pkg.ClearFlag(
		v_act_id, 
		v_group_sid, 
		security.security_pkg.SOFLAG_INHERIT_DACL
	);
	security.acl_pkg.AddACE(
		v_act_id, 
		security.acl_pkg.GetDACLIDForSID(v_group_sid), 
		-1, 
		security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, 
		securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.getApp, 'Groups/Administrators'), 
		security.security_pkg.PERMISSION_READ
	);	
	
	RETURN v_group_sid;
END;

PROCEDURE ApplyExtendedCapabilities (
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	VerifySetupPermission('ApplyExtendedCapabilities');
	
	IF helper_pkg.UseTypeCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'Capabilities cannot be set against individual companies when type capabilities are enabled');
	END IF;
	
	-- allow this company to invite suppliers
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE);
	-- allow all users of this company only to write to supplier details
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_ROOT, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	-- allow company admins to setup email stub registration
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION);
	-- allow company admins to setup survey questionnaires
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMPANY, chain_pkg.CREATE_QUESTIONNAIRE_TYPE);
	-- allow company admins to send newsflashes
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_NEWSFLASH);
	-- allow company admins and users to receive user-targeted newsflashes
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.RECEIVE_USER_TARGETED_NEWS);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.RECEIVE_USER_TARGETED_NEWS);
	-- allow company admins to reset supplier passwords
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.RESET_PASSWORD);
	-- If company users have permission to create users, then also let them specify a user name.
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_COMPANY, chain_pkg.SPECIFY_USER_NAME);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);

	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.SetCapabilityPermission(in_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
END;

PROCEDURE ApplyExtendedCapabilities (
	in_company_type_key			IN company_type.lookup_key%TYPE
)
AS
BEGIN
	VerifySetupPermission('ApplyExtendedCapabilities');
	
	IF helper_pkg.UseTraditionalCapabilities THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company Type Capabilities cannot be set when type capabilities are enabled');
	END IF;
	
	-- set supplier capabilities for all secondary company types
	FOR r IN (
		SELECT sct.lookup_key
		  FROM company_type_relationship ctr
		  JOIN company_type pct ON ctr.primary_company_type_id = pct.company_type_id
		  JOIN company_type sct ON ctr.secondary_company_type_id = sct.company_type_id
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(pct.lookup_key) = LOWER(in_company_type_key)
	)
	LOOP
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_QUESTIONNAIRE_INVITE);
		-- allow all users of this company only to write to supplier details
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_ROOT, chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		-- allow company admins to reset supplier passwords
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.RESET_PASSWORD);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.APPROVE_QUESTIONNAIRE);

		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);

		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);

		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);

		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		-- allow company admins to create/edit supplier users
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.CREATE_USER);
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		
		type_capability_pkg.SetPermission(in_company_type_key, r.lookup_key, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ);
	END LOOP;
	
	-- allow company admins to setup email stub registration
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION);
	-- allow company admins to setup survey questionnaires
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMPANY, chain_pkg.CREATE_QUESTIONNAIRE_TYPE);
	-- allow company admins to send newsflashes
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.SEND_NEWSFLASH);
	-- allow company admins and users to receive user-targeted newsflashes
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.CT_COMMON, chain_pkg.RECEIVE_USER_TARGETED_NEWS);
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMMON, chain_pkg.RECEIVE_USER_TARGETED_NEWS);
	
	--allow company admins to edit their company users
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	--allow company users to access their company users
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.COMPANY_USER, security_pkg.PERMISSION_READ);

	IF company_type_pkg.IsTopCompanyType(in_company_type_key) THEN
		-- allow company users and admins to read and write user details
		type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.IS_TOP_COMPANY);
	END IF;
	
	-- If company users have permission to create users, then also let them specify a user name.
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.CT_COMPANY, chain_pkg.SPECIFY_USER_NAME);

	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);

	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.USER_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);
	type_capability_pkg.SetPermission(in_company_type_key, chain_pkg.ADMIN_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);
END;

FUNCTION HasImplementation (
	in_name						IN implementation.name%TYPE
)RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	VerifySetupPermission('HasImplementation', TRUE);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM implementation
	 WHERE name = UPPER(in_name)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_count <> 0;
END;

FUNCTION HasImplementationPackage (
	in_link_pkg					IN implementation.link_pkg%TYPE
)RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	VerifySetupPermission('HasImplementationPackage', TRUE);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM implementation
	 WHERE link_pkg = LOWER(in_link_pkg)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_count <> 0;
END;

PROCEDURE AddSupplierImplementation 
AS
BEGIN
	IF NOT HasImplementation('CSR_SUPPLIER') THEN
		AddImplementation('CSR_SUPPLIER', 'csr.supplier_pkg');
	END IF;
END;

PROCEDURE AddImplementation (
	in_name						IN implementation.name%TYPE,	
	in_link_pkg					IN implementation.link_pkg%TYPE
)
AS
BEGIN
	VerifySetupPermission('AddImplementation', TRUE);
	
	BEGIN
		INSERT INTO implementation (name, link_pkg, execute_order)
		SELECT UPPER(in_name), LOWER(in_link_pkg), NVL(MAX(execute_order), 0) + 1
		  FROM implementation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION IsChainEnabled
RETURN BOOLEAN
AS
	v_count							NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM implementation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_count > 0;
END;

FUNCTION SQL_IsChainEnabled
RETURN NUMBER
AS
	v_count							NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM implementation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	IF v_count > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE CreateSectors
AS
BEGIN
	VerifySetupPermission('CreateSectors');
	
	helper_pkg.UpdateSector(1, 'Aerospace and Defense'); 
	helper_pkg.UpdateSector(2, 'Alternative Energy'); 
	helper_pkg.UpdateSector(3, 'Apparel'); 
	helper_pkg.UpdateSector(4, 'Automobiles and Parts'); 
	helper_pkg.UpdateSector(5, 'Banks'); 
	helper_pkg.UpdateSector(6, 'Beverages'); 
	helper_pkg.UpdateSector(7, 'Chemicals'); 
	helper_pkg.UpdateSector(8, 'Communications'); 
	helper_pkg.UpdateSector(9, 'Construction and Materials'); 
	helper_pkg.UpdateSector(10, 'Consultancy'); 
	helper_pkg.UpdateSector(11, 'Education'); 
	helper_pkg.UpdateSector(12, 'Electricity'); 
	helper_pkg.UpdateSector(13, 'Electronic and Electrical Equipment'); 
	helper_pkg.UpdateSector(14, 'Equity Investment Instruments'); 
	helper_pkg.UpdateSector(15, 'Food and Drug Retailers'); 
	helper_pkg.UpdateSector(16, 'Food Producers'); 
	helper_pkg.UpdateSector(17, 'Forestry and Paper'); 
	helper_pkg.UpdateSector(18, 'Gas Distribution'); 
	helper_pkg.UpdateSector(19, 'General Financial'); 
	helper_pkg.UpdateSector(20, 'General Industrials'); 
	helper_pkg.UpdateSector(21, 'General Retailers'); 
	helper_pkg.UpdateSector(22, 'Government'); 
	helper_pkg.UpdateSector(23, 'Health Care Equipment and Services'); 
	helper_pkg.UpdateSector(24, 'Household Goods'); 
	helper_pkg.UpdateSector(25, 'Industrial Engineering'); 
	helper_pkg.UpdateSector(26, 'Industrial Metals'); 
	helper_pkg.UpdateSector(27, 'Industrial Transportation'); 
	helper_pkg.UpdateSector(28, 'Insurance'); 
	helper_pkg.UpdateSector(29, 'Entertainment'); 
	helper_pkg.UpdateSector(30, 'Leisure Goods'); 
	helper_pkg.UpdateSector(31, 'Media'); 
	helper_pkg.UpdateSector(32, 'Mining'); 
	helper_pkg.UpdateSector(33, 'Nonequity Investment Instruments'); 
	helper_pkg.UpdateSector(34, 'Oil and Gas Producers'); 
	helper_pkg.UpdateSector(35, 'Oil Equipment Services and Distribution'); 
	helper_pkg.UpdateSector(36, 'Other'); 
	helper_pkg.UpdateSector(37, 'Personal Goods'); 
	helper_pkg.UpdateSector(38, 'Pharmaceuticals and Biotechnology'); 
	helper_pkg.UpdateSector(39, 'Real Estate'); 
	helper_pkg.UpdateSector(40, 'Software and Computer Services'); 
	helper_pkg.UpdateSector(41, 'Support Services'); 
	helper_pkg.UpdateSector(42, 'Technology Hardware and Equipment'); 
	helper_pkg.UpdateSector(43, 'Telecommunications'); 
	helper_pkg.UpdateSector(44, 'Tobacco'); 
	helper_pkg.UpdateSector(45, 'Travel and Leisure'); 
	helper_pkg.UpdateSector(46, 'Water'); 
END;

FUNCTION GetSidFromPath (
	in_path							IN	VARCHAR2,
	in_root_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP')
)
RETURN security_pkg.T_SID_ID
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	RETURN security.securableobject_pkg.GetSidFromPath(v_act, in_root_sid, in_path);
END;

PROCEDURE GrantAccess (
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_group_sid					IN	security_pkg.T_SID_ID,
	in_access						IN	NUMBER,
	in_flags						IN	NUMBER DEFAULT security_pkg.ACE_FLAG_DEFAULT
)
AS
	v_app							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
BEGIN
	security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(in_object_sid), in_group_sid);
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(in_object_sid), -1,
		security.security_pkg.ACE_TYPE_ALLOW, in_flags, in_group_sid, in_access);
	security.acl_pkg.PropogateACEs(v_act, in_object_sid);
END;

PROCEDURE GrantAccess (
	in_path							IN	VARCHAR2,
	in_group_sid					IN	security_pkg.T_SID_ID,
	in_access						IN	NUMBER,
	in_flags						IN	NUMBER DEFAULT security_pkg.ACE_FLAG_DEFAULT
)
AS
	v_app							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_object_sid					security_pkg.T_SID_ID := GetSidFromPath(in_path);
BEGIN
	GrantAccess(v_object_sid, in_group_sid, in_access, in_flags);
END;

PROCEDURE SetupChainAdminGroup (
	in_survey_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_workflow_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_READ,
	in_reporting_access				IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_csr_users_access				IN	security_pkg.T_PERMISSION DEFAULT 0,
	in_audit_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_alert_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_trash_access					IN	security_pkg.T_PERMISSION DEFAULT security_pkg.PERMISSION_STANDARD_ALL,
	in_cms_access					IN	security_pkg.T_PERMISSION DEFAULT 0
)
AS
	v_chain_admin_sid				security_pkg.T_SID_ID := GetSidFromPath('Groups/Chain Administrators');
BEGIN
	IF in_survey_access != 0 THEN
		GrantAccess('Menu/admin/csr_quicksurvey_admin', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('wwwroot/surveys', v_chain_admin_sid, in_survey_access);
		GrantAccess('wwwroot/csr/site/quickSurvey/admin', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('wwwroot/csr/site/quickSurvey/results', v_chain_admin_sid, security_pkg.PERMISSION_READ);
	END IF;
	
	IF in_audit_access != 0 THEN
		GrantAccess('wwwroot/csr/site/audit', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Audits', v_chain_admin_sid, in_audit_access);
		IF BITAND(in_audit_access, security_pkg.PERMISSION_TAKE_OWNERSHIP) = security_pkg.PERMISSION_TAKE_OWNERSHIP THEN
			GrantAccess('Menu/ia', v_chain_admin_sid, security_pkg.PERMISSION_READ);
			GrantAccess('Capabilities/Close audits', v_chain_admin_sid, security_pkg.PERMISSION_WRITE);
		ELSE
			GrantAccess('Menu/ia', v_chain_admin_sid, security_pkg.PERMISSION_READ, 0);
			GrantAccess('Menu/ia/csr_audit_browse', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		END IF;
	END IF;
	
	IF in_trash_access != 0 THEN
		GrantAccess('Trash', v_chain_admin_sid, in_trash_access);
		GrantAccess('Menu/admin/csr_trash', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('wwwroot/csr/site/admin', v_chain_admin_sid, security_pkg.PERMISSION_READ);
	END IF;
	
	IF in_workflow_access != 0 THEN
		GrantAccess('Workflows', v_chain_admin_sid, in_workflow_access);
		GrantAccess('wwwroot/csr/site/flow/admin', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Menu/admin/csr_flow_admin', v_chain_admin_sid, security_pkg.PERMISSION_READ);
	END IF;
	
	IF in_alert_access != 0 THEN
		GrantAccess('wwwroot/csr/site/alerts', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('wwwroot/csr/site/mail', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Menu/admin/csr_alerts_bounces', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Menu/admin/csr_alerts_messages', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Menu/admin/csr_alerts_sent', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Capabilities/View alert bounces', v_chain_admin_sid, security_pkg.PERMISSION_WRITE);
		GrantAccess(csr.alert_pkg.GetSystemMailbox('Sent'), v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess(csr.alert_pkg.GetSystemMailbox('Outbox'), v_chain_admin_sid, security_pkg.PERMISSION_READ);
		IF BITAND(in_audit_access, security_pkg.PERMISSION_WRITE) = security_pkg.PERMISSION_WRITE THEN
			GrantAccess('', v_chain_admin_sid, csr.csr_data_Pkg.PERMISSION_ALTER_SCHEMA);
			GrantAccess('Menu/admin/csr_alerts_template', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		END IF;
	END IF;
	
	IF in_reporting_access != 0 THEN
		GrantAccess('Menu/analysis', v_chain_admin_sid, security_pkg.PERMISSION_READ);

		BEGIN
			GrantAccess('wwwroot/csr/site/dataExplorer5', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		GrantAccess('wwwroot/csr/site/reports', v_chain_admin_sid, security_pkg.PERMISSION_READ);

		BEGIN
			GrantAccess('wwwroot/csr/site/dashboard', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		BEGIN
			GrantAccess('wwwroot/csr/site/imagechart', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		GrantAccess('Dataviews', v_chain_admin_sid, in_reporting_access);
		GrantAccess('TemplatedReports', v_chain_admin_sid, in_reporting_access);
	END IF;
	
	IF in_csr_users_access != 0 THEN
		GrantAccess('Menu/admin/csr_users_list', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('wwwroot/csr/site/users', v_chain_admin_sid, security_pkg.PERMISSION_READ);
		GrantAccess('Users', v_chain_admin_sid, in_csr_users_access);
		GrantAccess('Groups', v_chain_admin_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_WRITE);
		IF BITAND(in_csr_users_access, security_pkg.PERMISSION_ADD_CONTENTS) = security_pkg.PERMISSION_ADD_CONTENTS THEN
			GrantAccess(csr.alert_pkg.GetSystemMailbox('Users'), v_chain_admin_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		END IF;
		IF BITAND(in_csr_users_access, security_pkg.PERMISSION_WRITE) = security_pkg.PERMISSION_WRITE THEN
			GrantAccess('Regions', v_chain_admin_sid, security_pkg.PERMISSION_WRITE);
		END IF;
	END IF;
	
	IF in_cms_access != 0 THEN
		GrantAccess('CMS', v_chain_admin_sid, in_cms_access);
	END IF;
END;

PROCEDURE EnableActivities
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_users_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_top_menu_sid				security.security_pkg.T_SID_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	-- web resources	
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_profile		security.security_pkg.T_SID_ID;
	-- temp variables
	v_sid						security.security_pkg.T_SID_ID;
	v_id						NUMBER(10);
	v_pos						NUMBER(10);
BEGIN
	VerifySetupPermission('EnableActivities');

	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_users_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	
	BEGIN
		v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Chain');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Home');
	END;
	
	--
	/*** ADD MENU ITEMS ***/	
	
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_top_menu_sid, 'chain_activity_list', 'Contact history', '/csr/site/chain/activities/activityList.acds', 2, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_top_menu_sid,  'chain_contact_summary', 'Contact summary', '/csr/site/chain/activities/targetSummary.acds', 3, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	--
	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_profile := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'profile');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'profile', v_www_csr_site_profile);
	END;
	
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_profile), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
		v_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		
	-- Enable alert type (if not enabled already)
	BEGIN
		INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
		VALUES (csr.customer_alert_type_id_seq.nextval, 5022);

		INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
		  FROM csr.alert_frame af
		  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
		 WHERE af.app_sid = security.security_pkg.GetApp
		   AND cat.std_alert_type_id = 5022
		 GROUP BY cat.customer_alert_type_id
		HAVING MIN(af.alert_frame_id) > 0;
		
		INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
		  FROM csr.default_alert_template_body d
		  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
		  CROSS JOIN aspen2.translation_set t
		 WHERE d.std_alert_type_id = 5022
		   AND d.lang='en'
		   AND t.application_sid = security.security_pkg.GetApp
		   AND cat.app_sid = security.security_pkg.GetApp;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- Create calendar object if calendars are enabled
	BEGIN
		v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Calendars');
		csr.calendar_pkg.RegisterCalendar(
			in_name				=> 'Activities Calendar',
			in_js_include		=> '/csr/shared/calendar/includes/activities.js',
			in_js_class_type	=> 'Credit360.Calendars.Activities',
			in_description		=> 'Activities',
			out_calendar_sid	=> v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- Skip sites that don't have calendars enabled
	END;

	card_pkg.SetGroupCards('Activity Filter', T_STRING_LIST('Chain.Cards.Filters.ActivityFilter','Chain.Cards.Filters.ActivityFilterAdapter'));

END;

/*
-- This appears to be out of date, and is only referenced by a util script (db\utils\EnableChainSupplierProductTypes).

PROCEDURE EnableSupplierProductTypes (
	in_top_company_type			IN  VARCHAR2,
	in_secondary_company_type	IN  VARCHAR2
)
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_users_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_top_menu_sid				security.security_pkg.T_SID_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	-- temp variables
	v_sid						security.security_pkg.T_SID_ID;
	v_plugin_id					NUMBER(10);
	v_id						NUMBER(10);
	v_pos						NUMBER(10);
BEGIN
	VerifySetupPermission('EnableSupplierProductTypes');

	-- log on
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_users_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	
	
	--*** ADD MENU ITEMS ***
	BEGIN
		v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Chain');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Home');
	END;
	
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_top_menu_sid, 'chain_company_management', 'Company management', '/csr/site/chain/manageCompany/managecompany.acds', 1, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
	
	BEGIN
		v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_top_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/Administration');
	END;
	
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_top_menu_sid, 'chain_import_product_types', 'Import product types', '/csr/site/chain/products/admin/importProductTypes.acds', -1, null, v_menu_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
	
	-- Position 4 because that was last one when this feature was added
	card_pkg.InsertGroupCard(
		in_group_name				=> 'Basic Company Filter',
		in_card_js_type				=> 'Chain.Cards.Filters.CompanyProductFilter',
		in_pos						=> 4
	);
	
	v_plugin_id := csr.plugin_pkg.GetPluginId('Chain.ManageCompany.ProductTypesTab');
	
	BEGIN
		SELECT company_tab_id
		  INTO v_id
		  FROM chain.company_tab
		 WHERE plugin_id = v_plugin_id
		   AND page_company_type_id = chain.company_type_pkg.GetCompanyTypeId(in_secondary_company_type)
		   AND user_company_type_id = chain.company_type_pkg.GetCompanyTypeId(in_top_company_type);
	EXCEPTION
		WHEN no_data_found THEN
			SELECT MAX(pos)
			  INTO v_pos
			  FROM chain.company_tab
			 WHERE page_company_type_id = chain.company_type_pkg.GetCompanyTypeId(in_secondary_company_type)
			   AND user_company_type_id = chain.company_type_pkg.GetCompanyTypeId(in_top_company_type);		
			
		chain.plugin_pkg.AddCompanyTab(
			in_plugin_id			=>	v_plugin_id,
			in_pos					=>	NVL(v_pos, 0),
			in_label				=>	'Product types',
			in_page_company_type_id	=>	chain.company_type_pkg.GetCompanyTypeId(in_secondary_company_type),
			in_user_company_type_id	=>	chain.company_type_pkg.GetCompanyTypeId(in_top_company_type)
		);
	END;
	
	chain.type_capability_pkg.SetPermission(
		in_primary_company_type		=> in_top_company_type,
		in_secondary_company_type	=> in_secondary_company_type,
		in_group					=> chain.chain_pkg.ADMIN_GROUP,
		in_capability				=> chain.chain_pkg.PRODUCTS,
		in_permission_set			=> 0 + security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
END;*/

PROCEDURE EnableCompanySelfReg
AS
BEGIN
	card_pkg.SetGroupCards('Self Registration Questionnaire Manager', T_STRING_LIST(
		'Chain.Cards.QuestionnaireSelfRegConfirmation', 
		'Chain.Cards.Login',
		'Chain.Cards.RejectInvitation',
		'Chain.Cards.SelfRegistration'
	));
	
	card_pkg.MarkTerminate('Self Registration Questionnaire Manager', 'Chain.Cards.Login');
	card_pkg.MarkTerminate('Self Registration Questionnaire Manager', 'Chain.Cards.SelfRegistration');
	card_pkg.MarkTerminate('Self Registration Questionnaire Manager', 'Chain.Cards.RejectInvitation');
	
	card_pkg.RegisterProgression('Self Registration Questionnaire Manager', 'Chain.Cards.QuestionnaireSelfRegConfirmation', T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));

	UPDATE customer_options SET allow_Company_Self_Reg = 1 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	BEGIN
		INSERT INTO csr.customer_alert_type (app_sid, std_alert_type_id, customer_alert_type_id) 
		VALUES (SYS_CONTEXT('SECURITY','APP'), 5007, csr.customer_alert_type_id_seq.nextval);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
END;

END setup_pkg;
/
