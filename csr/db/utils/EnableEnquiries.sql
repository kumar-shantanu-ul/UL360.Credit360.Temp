whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

-- Please update version.sql too -- this keeps clean builds in sync


PROMPT Insert:
PROMPT 1) Host (e.g. foo.credit360.com)

exec security.user_pkg.logonadmin('&&1');

DECLARE
	v_enable_roles				NUMBER(1) DEFAULT 1;
	v_enable_priorities			NUMBER(1) DEFAULT 1;
	v_default_priority_id		NUMBER(10) DEFAULT NULL;
	---------------------------------------------------------
	v_host						VARCHAR2(200) DEFAULT '&&1';
	v_region_sid				security.security_pkg.T_SID_ID;
	v_role_sid					security.security_pkg.T_SID_ID;
	v_ecd_sid					security.security_pkg.T_SID_ID;
	v_enquiry_menu_sid			security.security_pkg.T_SID_ID;
	v_em_group_sid				security.security_pkg.T_SID_ID;
	v_www_root_sid				security.security_pkg.T_SID_ID;
	v_issues2_wr_sid			security.security_pkg.T_SID_ID;
	v_fp_wr_sid					security.security_pkg.T_SID_ID;
	v_wr_sid					security.security_pkg.T_SID_ID;
	v_wr_child_sid				security.security_pkg.T_SID_ID;
	v_i2_public_wr_sid			security.security_pkg.T_SID_ID;
	v_outbox_sid				security.security_pkg.T_SID_ID;
BEGIN
	/************************************************************************
		SETUP THE ISSUE TYPE
	************************************************************************/
	-- ensure that the EnquiryCreatorDaemon exists
	BEGIN
		v_ecd_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Users/EnquiryCreatorDaemon');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- create a daemon user
			security.user_pkg.CreateUser(
				in_act_id						=> security.security_pkg.GetAct,
				in_parent_sid				=> security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Users'),
				in_login_name				=> 'EnquiryCreatorDaemon',
				in_class_id					=> security.Security_Pkg.SO_USER,
				in_account_expiry_enabled	=> 0,
				out_user_sid				=> v_ecd_sid
			);

			-- fiddle with csr user data
			INSERT INTO csr.csr_user
			(app_sid, guid, info_xml, send_alerts, show_portal_help, hidden,
				csr_user_sid, email, full_name, user_name, friendly_name)
			SELECT c.app_sid, security.user_pkg.GenerateACT, null, 0, 0, 1,
					-- things we care about
					v_ecd_sid, 'no-reply@cr360.com', 'Enquiry submission', 'EnquiryCreatorDaemon', 'Enquiry submission'
			  FROM csr.customer c
			 WHERE c.app_sid = security.security_pkg.GetApp;

			INSERT INTO csr.region_start_point (region_sid, user_sid)
				SELECT region_root_sid, v_ecd_sid
				  FROM csr.customer;

			INSERT INTO csr.ind_start_point (ind_sid, user_sid)
				SELECT ind_root_sid, v_ecd_sid
				  FROM csr.customer;
	END;
	
	IF v_enable_roles = 1 THEN
		-- First, we will create a top level region called Enquiry Issues
		BEGIN
			v_region_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Regions/Enquiry Issues');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				csr.region_pkg.CreateRegion(
					in_parent_sid			=> NULL,
					in_name					=> 'Enquiry Issues',
					in_description			=> 'Enquiry Issues',
					out_region_sid			=> v_region_sid
				);
		END;
		
		-- now create a role
		csr.role_pkg.SetRole('Enquiry manager', 'enquiry_manager', v_role_sid);	
		-- lets add all of the current users of the administrators group as region role members
		FOR r IN (
			SELECT cu.csr_user_sid
			  FROM csr.csr_user cu, TABLE(security.group_pkg.GetMembersAsTable(security.security_pkg.GetAct, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Administrators'))) gm
			 WHERE cu.csr_user_sid = gm.sid_id
		)
		LOOP
			csr.role_pkg.AddRoleMemberForRegion(v_role_sid, v_region_sid, r.csr_user_sid);
		END LOOP;
	END IF;
	
	IF v_enable_priorities = 1 THEN
		
		BEGIN
			INSERT INTO csr.issue_priority(issue_priority_id, description, due_date_offset)
			VALUES (1, 'Low priority', 14);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO csr.issue_priority(issue_priority_id, description, due_date_offset)
			VALUES (2, 'Normal priority', 7);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO csr.issue_priority(issue_priority_id, description, due_date_offset)
			VALUES (3, 'High priority', 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
	END IF;
		
	BEGIN
		INSERT INTO csr.issue_type (issue_type_id, label, default_region_sid, default_issue_priority_id, require_priority) 
		VALUES (
			csr.csr_data_pkg.ISSUE_ENQUIRY, 
			'Enquiry', 
			v_region_sid, 
			v_default_priority_id,
			v_enable_priorities
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			UPDATE csr.issue_type 
			   SET label = 'Enquiry',
				   default_region_sid = v_region_sid, 
				   default_issue_priority_id = v_default_priority_id, 
				   require_priority = v_enable_priorities
			 WHERE app_sid = security.security_pkg.GetApp
			   AND issue_type_id = csr.csr_data_pkg.ISSUE_ENQUIRY;
	END;
	
	/************************************************************************
			CREATE THE MANAGEMENT GROUP
	************************************************************************/
	BEGIN
		v_em_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Enquiry Managers');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN	
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetAct, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups'), 
				security.security_pkg.GROUP_TYPE_SECURITY, 'Enquiry Managers', security.class_pkg.GetClassId('CSRUserGroup'), v_em_group_sid);
	END;
	
	/************************************************************************
			WEB RESOURCES FOR ISSUES2
	************************************************************************/
	v_www_root_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot');
	
	BEGIN
		v_issues2_wr_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot/csr/site/issues2');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(
				security.security_pkg.GetAct, 
				v_www_root_sid,
				security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot/csr/site'), 
				'issues2', 
				v_issues2_wr_sid
			);
			
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_issues2_wr_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		v_i2_public_wr_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_issues2_wr_sid, 'public');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(
				security.security_pkg.GetAct, 
				v_www_root_sid,
				v_issues2_wr_sid, 
				'public', 
				v_i2_public_wr_sid
			);
			
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_i2_public_wr_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/Everyone'), security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	/************************************************************************
				WEB RESOURCES FOR /fp/shared/extux/upload/file/upload.ashx
	************************************************************************/
	v_fp_wr_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'wwwroot/fp');
	
	v_wr_sid := v_wr_child_sid;
	BEGIN
		v_wr_child_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_fp_wr_sid, 'shared');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_root_sid, v_fp_wr_sid, 'shared', v_wr_child_sid);
	END;
	
	v_wr_sid := v_wr_child_sid;
	BEGIN
		v_wr_child_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_wr_sid, 'extux');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_root_sid, v_wr_sid, 'extux', v_wr_child_sid);
	END;
	
	v_wr_sid := v_wr_child_sid;
	BEGIN
		v_wr_child_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_wr_sid, 'upload');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_root_sid, v_wr_sid, 'upload', v_wr_child_sid);
	END;
	
	v_wr_sid := v_wr_child_sid;
	BEGIN
		v_wr_child_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_wr_sid, 'file');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_root_sid, v_wr_sid, 'file', v_wr_child_sid);
	END;
	
	v_wr_sid := v_wr_child_sid;
	BEGIN
		v_wr_child_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, v_wr_sid, 'upload.ashx');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(security.security_pkg.GetAct, v_www_root_sid, v_wr_sid, 'upload.ashx', v_wr_child_sid);
	
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_wr_child_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/Everyone'), security.security_pkg.PERMISSION_STANDARD_READ);		
	END;	
	
	/************************************************************************
			CREATE MENU
	************************************************************************/
	BEGIN
		v_enquiry_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'menu/enquiry');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(security.security_pkg.GetAct, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'menu'),
					'enquiry', 'Enquiry', '/csr/public/enquirylanding.acds', 100, null, v_enquiry_menu_sid);
					
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_enquiry_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_em_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_enquiry_menu_sid);
	
	-- add permissions to the capability
	security.acl_pkg.AddACE(security.security_pkg.GetACT, 
		security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Issue management')), 
		-1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
		v_em_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		
	
	/************************************************************************
	 			ENABLE ALERTS
	************************************************************************/
	FOR r IN (
		SELECT * FROM csr.default_alert_frame ORDER BY default_alert_frame_id
	) LOOP
		BEGIN
			INSERT INTO csr.alert_frame (alert_frame_id, name) 
			VALUES (csr.alert_frame_id_seq.nextval, r.name);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id) 
		SELECT csr.customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM (
			SELECT std_alert_type_id 
			  FROM csr.std_alert_type 
			 WHERE std_alert_type_id IN (17, 32, 33, 34, 35, 36)
			  MINUS
			SELECT std_alert_type_id 
			  FROM csr.customer_alert_type
		 );
			
	/************************************************************************
				CSR SETUP
	************************************************************************/
	UPDATE csr.customer 
	   SET issue_editor_url = '/csr/site/issues2/public/editIssueDialog.jsi';
	   
	FOR r IN( 
		SELECT portlet_id
		  FROM csr.portlet 
		 WHERE type = 'Credit360.Portlets.Issue2')
	LOOP
		csr.portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	
	/************************************************************************
				MAILBOX PERMISSIONS
	************************************************************************/
	-- allow anyone to add contents to the application outbox
	v_outbox_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.SID_ROOT, 'Mail/Folders/'||SUBSTR(v_host, 1, INSTR(v_host, '.') - 1) || '@' || SUBSTR(v_host, INSTR(v_host, '.') + 1, LENGTH(v_host))||'/Outbox');
	
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_outbox_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/Everyone'), security.security_pkg.PERMISSION_ADD_CONTENTS);	
END;
/


commit;
exit;



/*
declare 
    v_inbound_addr varchar2(255) := 'questions@cr360sharing.credit360.com';
    v_account_name varchar2(255) := 'CR360 Sharing Questions';
    v_account_sid  security.security_pkg.T_SID_ID;
    v_sid          security.security_pkg.T_SID_ID;
    v_inbox_sid	   security.security_pkg.T_SID_ID;
    v_mailbox_sid  security.security_pkg.T_SID_ID;
begin
    security.user_pkg.logonadmin;
    mail.mail_pkg.createAccount(v_inbound_addr, 'sdn3!fed_gwJWWgPWa', v_account_name, v_sid, v_inbox_sid);
    mail.mailbox_pkg.createMailbox(v_inbox_sid, 'Invalid e-mails', v_account_sid, v_mailbox_sid);
    security.user_pkg.logonadmin('cr360sharing.credit360.com');
	update csr.issue_type set alert_mail_address=v_inbound_addr, alert_mail_name=v_account_name where issue_type_id = 9 and app_sid = security.security_pkg.getapp;
end;
/
*/

/*
declare
	v_menu_issue 	number(10);
begin
	security.menu_pkg.CreateMenu(security.security_pkg.GetAct, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'menu/data'),
		'csr_issue', 'Queries', '/csr/site/issues/issueList.acds',10, null, v_menu_issue);
end;
/

*/
