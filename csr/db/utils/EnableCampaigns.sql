prompt This enable script should only be used in very specific circumstances. 
prompt For most clients you should use the EnableCampaignsNoRecipients script or the "Enable Campaigns" button on the enable modules page.
prompt 
prompt Do you wish to continue? (Y / N)

DEFINE answer = '&&1'

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

BEGIN
	IF upper('&&answer') != 'Y' THEN
		RAISE_APPLICATION_ERROR(-20001, '========= Update Abandoned =======');
	END IF;
END;
/

set echo on

define host='&&1'
define usr='&&2'

exec security.user_pkg.logonadmin('&&host');

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_users
	 where username = UPPER('&usr');
	if v_exists = 0 then
		execute immediate 'create user &&usr identified by &&usr temporary tablespace temp default tablespace users quota unlimited on users';
	end if;
end;
/

grant select on cms.context to &&usr;
grant select on cms.fast_context to &&usr;
grant execute on cms.tab_pkg to &&usr;
grant execute on security.security_pkg to &&usr;

-- Drop relevent tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(
        'RECIPIENT',
        'RECIPIENT_CATEGORY'
    );
BEGIN
	cms.tab_pkg.enabletrace;
	FOR i IN 1 .. v_list.count 
	LOOP
		-- USER, table_name, cascade, drop physical
		cms.tab_pkg.DropTable(UPPER('&&usr'), v_list(i), true, true);
		null;
	END LOOP;
END;
/

/********************************************************************************
 ENUMERATION TABLES
 ********************************************************************************/


PROMPT > Creating tables...
PROMPT ======================

CREATE TABLE &&usr..RECIPIENT_CATEGORY (
	CATEGORY_ID		NUMBER(10) NOT NULL,
	LABEL			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CATEGORY PRIMARY KEY(CATEGORY_ID)
);

COMMENT ON TABLE &&usr..RECIPIENT_CATEGORY IS 'desc="Recipient category"';
COMMENT ON COLUMN &&usr..RECIPIENT_CATEGORY.CATEGORY_ID IS 'desc="Category",auto';
COMMENT ON COLUMN &&usr..RECIPIENT_CATEGORY.LABEL IS 'desc="Label"';

INSERT INTO &&usr..RECIPIENT_CATEGORY (CATEGORY_ID, LABEL) VALUES (1, 'Manager');
INSERT INTO &&usr..RECIPIENT_CATEGORY (CATEGORY_ID, LABEL) VALUES (2, 'Employee');
INSERT INTO &&usr..RECIPIENT_CATEGORY (CATEGORY_ID, LABEL) VALUES (3, 'Supplier');
INSERT INTO &&usr..RECIPIENT_CATEGORY (CATEGORY_ID, LABEL) VALUES (4, 'Consultant');


/********************************************************************************
 TABLES
 ********************************************************************************/
CREATE TABLE &&usr..RECIPIENT (
	RECIPIENT_ID	NUMBER(10) NOT NULL,
	EMAIL			VARCHAR2(255) NOT NULL,
	FULL_NAME		VARCHAR2(255) NOT NULL,
	CATEGORY_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_RECIPIENT PRIMARY KEY (RECIPIENT_ID)
);
	
COMMENT ON TABLE &&usr..RECIPIENT IS 'desc="Recipients"';
COMMENT ON COLUMN &&usr..RECIPIENT.RECIPIENT_ID IS 'desc="Reference",auto';
COMMENT ON COLUMN &&usr..RECIPIENT.EMAIL IS 'desc="Email"';
COMMENT ON COLUMN &&usr..RECIPIENT.FULL_NAME IS 'desc="Full name"';
COMMENT ON COLUMN &&usr..RECIPIENT.CATEGORY_ID IS 'desc="Category",enum,enum_desc_col=label';

GRANT SELECT ON &&usr..recipient TO web_user;


ALTER TABLE &&usr..RECIPIENT ADD CONSTRAINT FK_RECIPIENT_CATEGORY
    FOREIGN KEY (CATEGORY_ID)
    REFERENCES &&usr..RECIPIENT_CATEGORY (CATEGORY_ID);

/********************************************************************************
 TABLE REGISTRATION
 ********************************************************************************/
spool registerTables.log
begin
    dbms_output.enable(NULL); -- unlimited output, lovely
    security.user_pkg.LogonAdmin('&&host');
	cms.tab_pkg.registertable(UPPER('&&usr'), 'RECIPIENT_CATEGORY', FALSE);
	cms.tab_pkg.registertable(UPPER('&&usr'), 'RECIPIENT', FALSE);
    commit;
END;
/

spool off

/********************************************************************************
 MENU AND ALERTS
 ********************************************************************************/
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_af_id						NUMBER(10,0);
	v_cust_alert_type_id 		NUMBER(10);
	-- menu
	v_menu_campaign				security.security_pkg.T_SID_ID;
	v_menu_recipients			security.security_pkg.T_SID_ID;
	v_campaigns_sid				security.security_pkg.T_SID_ID;
	-- web resources	
	v_wwwroot_sid				security.security_pkg.T_SID_ID;
	v_forms_sid 				security.security_pkg.T_SID_ID;
	v_csr_forms_sid 			security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&host');
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- campaign list
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_quicksurvey_campaignlist', 'Survey campaigns', '/csr/site/quicksurvey/admin/CampaignList.acds', 7, null, v_menu_campaign);
	EXCEPTION 
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	v_wwwroot_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	
	-- recipients
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'forms_recipients', 'Recipients', '/forms/recipients', 7, null, v_menu_recipients);
	EXCEPTION 
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_wwwroot_sid, 'forms', security.Security_Pkg.SO_WEB_RESOURCE, null, v_forms_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_forms_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'), 
				security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_forms_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot_sid, 'forms');
	END;
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_forms_sid, 'recipients', security.Security_Pkg.SO_WEB_RESOURCE,
			'/fp/cms/form.acds?_FORM_PATH=/csr/forms/recipient_list.xml', v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid,
			security.securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot_sid, 'csr'), 'forms',
			security.Security_Pkg.SO_WEB_RESOURCE, null, v_csr_forms_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_csr_forms_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'), 
				security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	
	BEGIN
		security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_forms_sid, 'recipient_categories', security.Security_Pkg.SO_WEB_RESOURCE,
			'/fp/cms/form.acds?_FORM_PATH=/csr/forms/recipient_category_list.xml', v_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	DELETE FROM csr.alert_template_body 
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id=31);

	DELETE FROM csr.alert_template 
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id=31);

	DELETE FROM csr.customer_alert_type 
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
	   AND customer_alert_type_id IN (select customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id=31);

	INSERT INTO csr.customer_alert_type (app_sid, std_alert_type_id, customer_alert_type_id) 
		VALUES (SYS_CONTEXT('SECURITY','APP'), 31, csr.customer_alert_type_id_seq.nextval)
		RETURNING customer_alert_type_id INTO v_cust_alert_type_id;

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

	INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES (SYS_CONTEXT('SECURITY','APP'), v_cust_alert_type_id, v_af_id, 'automatic');

	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
		INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (SYS_CONTEXT('SECURITY','APP'), v_cust_alert_type_id, r.lang, 
			'<template>Survey Invitation</template>',
			'<template>'||
				'Hello,<br />'||
				'<br />'||
				'Please fill in the following survey:<br />'||
				'<br />'||
				'<mergefield name="SURVEY_URL" /><br />'||
				'<br />'||
				'Thank you for your cooperation. Sincerely, yours<br />'||
				'<mergefield name="FROM_NAME" />'||
			'</template>', 
			'<template></template>');
	END LOOP;
	
	
	BEGIN
		v_campaigns_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Campaigns');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Campaigns', v_campaigns_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_campaigns_sid), -1, 
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'), 
				security.security_pkg.PERMISSION_STANDARD_ALL);
	END;
	
	BEGIN
		INSERT INTO CSR.CUSTOMER_FLOW_ALERT_CLASS (FLOW_ALERT_CLASS) VALUES ('campaign');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

PROMPT You can copy forms over from cr360sharing\web\forms\recipient

COMMIT;
