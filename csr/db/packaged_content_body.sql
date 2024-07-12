CREATE OR REPLACE PACKAGE BODY csr.packaged_content_pkg AS

PROCEDURE SetImagePortlet(
	in_blob			IN	image_upload_portlet.image%TYPE,
	in_filename		IN	image_upload_portlet.file_name%TYPE,
	in_mime_type	IN	image_upload_portlet.mime_type%TYPE,
	out_image_id	OUT	image_upload_portlet.img_id%TYPE
)
AS
BEGIN

	csr.image_upload_portlet_pkg.SetImageBlob(
		in_blob			=> in_blob,
		in_filename		=> in_filename,
		in_mime_type	=> in_mime_type,
		out_image_id	=> out_image_id
	);

END;

PROCEDURE AddDocToLibraryFolder(
	in_filename				IN	doc_version.filename%TYPE,
	in_folder_path			IN	VARCHAR2,
	in_doc_data				IN	doc_data.data%TYPE,
	in_mime_type			IN	doc_data.mime_type%TYPE,
	in_description			IN	doc_version.description%TYPE,
	out_doc_id				OUT	doc.doc_id%TYPE
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
	v_def_doc_lib_sid 		security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Documents');
	v_documents_folder		security_pkg.T_SID_ID;
BEGIN

	v_documents_folder := doc_folder_pkg.GetDocumentsFolder(
		in_doc_library_sid			=> v_def_doc_lib_sid
	);

	SELECT MIN(doc_folder_sid)
	  INTO v_parent_sid
	  FROM (
		SELECT doc_folder_sid, REPLACE(SYS_CONNECT_BY_PATH(translated, ''), CHR(1), '/') path
		  FROM DOC_FOLDER_NAME_TRANSLATION
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = 'en'
	   CONNECT BY PRIOR doc_folder_sid = parent_sid
		 START WITH doc_folder_sid = v_documents_folder
	)
	 WHERE PATH = in_folder_path;

	doc_pkg.SaveDoc(
		in_doc_id				=> NULL,
		in_parent_sid			=> v_parent_sid,
		in_filename				=> in_filename,
		in_mime_type			=> in_mime_type,
		in_data					=> in_doc_data,
		in_description			=> in_description,
		in_change_description	=> 'New document',
		out_doc_id				=> out_doc_id
	);

END;

PROCEDURE EnableLanguage(
	in_lang				aspen2.lang.lang%TYPE
)
AS
	v_lang_id			aspen2.lang.lang_id%TYPE;
BEGIN

	SELECT lang_id 
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = in_lang;
	
	csr_app_pkg.AddApplicationTranslation(
		in_application_sid		=> SYS_CONTEXT('SECURITY', 'APP'),
		in_lang_id				=> v_lang_id
	);

END;

PROCEDURE HideLanguage(
	in_lang				aspen2.lang.lang%TYPE
)
AS
	v_lang_id			aspen2.lang.lang_id%TYPE;
BEGIN

	SELECT lang_id 
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = in_lang;
	
	aspen2.tr_pkg.HideApplicationTranslation(
		in_application_sid		=> SYS_CONTEXT('SECURITY', 'APP'),
		in_lang_id				=> v_lang_id
	);

END;

FUNCTION GetCustomerAlertType(
	in_std_alert_type_id			NUMBER
) RETURN NUMBER
AS
BEGIN
	RETURN alert_pkg.GetCustomerAlertType(in_std_alert_type => in_std_alert_type_id);
END;

PROCEDURE SetAlert(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE,
	in_ignore_if_missing			IN	NUMBER DEFAULT 1
)
AS
	v_customer_alert_type_id		alert_template.customer_alert_type_id%TYPE;
	v_alert_frame_id				NUMBER;
BEGIN

	BEGIN
		v_customer_alert_type_id := GetCustomerAlertType(in_std_alert_type_id => in_std_alert_type_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_ignore_if_missing = 1 THEN
				RETURN;
			ELSE
				RAISE;
			END IF;
	END;

	SELECT MIN(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM alert_frame
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	alert_pkg.SaveTemplateAndBody(
		in_customer_alert_type_id	=> v_customer_alert_type_id,
		in_alert_frame_id 			=> v_alert_frame_id,
		in_send_type 				=> in_send_type,
		in_reply_to_name			=> in_reply_to_name,
		in_reply_to_email			=> in_reply_to_email,
		in_lang						=> in_lang,
		in_subject					=> in_subject,
		in_body_html				=> in_body_html,
		in_item_html				=> in_item_html
	);

END;

PROCEDURE SetAlertFrame(
	in_lang					IN	alert_frame_body.lang%TYPE,
	in_html					IN	alert_frame_body.html%TYPE
)
AS
	v_alert_frame_id			alert_frame_body.alert_frame_id%TYPE;
BEGIN

	SELECT MIN(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM alert_frame
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	alert_pkg.SaveFrameBody(
		in_alert_frame_id		=> v_alert_frame_id,
		in_lang					=> in_lang,
		in_html					=> in_html
	);

END;

PROCEDURE CreateDashboardTab(
	in_tab_name			IN	tab.name%TYPE,
	in_layout			IN	tab.layout%TYPE,
	in_override_pos		IN	tab.override_pos%TYPE,
	in_owner_user_sid	IN	csr_user.csr_user_sid%TYPE,
	out_tab_id			OUT	tab.tab_id%TYPE
)
AS
	v_app_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	portlet_pkg.AddTabReturnTabId(
		in_app_sid			=> v_app_sid,
		in_tab_name			=> in_tab_name,
		in_is_shared		=> 1,
		in_is_hideable		=> 0,
		in_layout			=> in_layout,
		in_portal_group		=> '',
		out_tab_id			=> out_tab_id
	);
	portlet_pkg.CreateTabDescriptions(in_tab_id => out_tab_id);
	-- Annoyingly overkill, but you can't set the override pos on a new tab.
	portlet_pkg.UpdateTab(
		in_tab_id			=> out_tab_id,
		in_layout			=> in_layout,
		in_name 			=> in_tab_name,
		in_is_shared		=> 1,
		in_is_hideable		=> 0,
		in_override_pos		=> in_override_pos
	);
	IF in_owner_user_sid IS NOT NULL THEN
		UPDATE tab_user
		   SET user_sid = in_owner_user_sid
		 WHERE tab_id = out_tab_id
		   AND user_sid = security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

END;

PROCEDURE AddTabForGroup(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_group_name		IN	security_pkg.T_SO_NAME
)
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN

	v_group_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/' || in_group_name);

	portlet_pkg.AddTabForGroup(	
		in_group_sid		=> v_group_sid,
		in_tab_id			=> in_tab_id
	);

END;

PROCEDURE AddTabForRole(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_role_name		IN	security_pkg.T_SO_NAME
)
AS
	v_role_sid				security_pkg.T_SID_ID;
BEGIN

	v_role_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/' || in_role_name);

	portlet_pkg.AddTabForGroup(	
		in_group_sid		=> v_role_sid,
		in_tab_id			=> in_tab_id
	);

END;

PROCEDURE AddPortletToTab(
	in_tab_id			IN	tab_portlet.tab_id%TYPE,
	in_type				IN	portlet.type%TYPE,
	in_initial_state	IN	tab_portlet.state%TYPE,
	out_tab_portlet_id	OUT	tab_portlet.tab_portlet_id%TYPE
)
AS
	v_customer_portlet_sid	tab_portlet.customer_portlet_sid%TYPE;
BEGIN
	
	EnsurePortletEnabled(
		in_type						=> in_type,
		out_customer_portlet_sid	=> v_customer_portlet_sid
	);
	
	portlet_pkg.AddPortletToTab(
		in_tab_id				=> in_tab_id,
		in_customer_portlet_sid	=> v_customer_portlet_sid,
		in_initial_state		=> in_initial_state,
		out_tab_portlet_id		=> out_tab_portlet_id
	);
END;

PROCEDURE SetTabPortletPosition(
	in_tab_portlet_id	IN	tab_portlet.tab_portlet_id%TYPE,
	in_column			IN	tab_portlet.column_num%TYPE,
	in_pos				IN	tab_portlet.pos%TYPE
)
AS
BEGIN

	-- This isn't ideal, but the existing procedures to update portlet position/column
	-- are quite UI tied in that they want them all at once, etc.
	UPDATE csr.tab_portlet
	   SET column_num = in_column,
		   pos = in_pos
	 WHERE tab_portlet_id = in_tab_portlet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE WriteToObjectMap(
	in_object_ref			IN	packaged_content_object_map.object_ref%TYPE,
	in_created_object_id	IN	packaged_content_object_map.created_object_id%TYPE
)
AS
BEGIN

	INSERT INTO csr.packaged_content_object_map
		(object_ref, created_object_id)
	VALUES
		(in_object_ref, in_created_object_id);
	

END;

PROCEDURE SetChartTemplate(
	in_data						IN	FILE_UPLOAD.data%TYPE
)
AS
BEGIN

	template_pkg.SetTemplate(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_template_type_id			=> csr_data_pkg.TEMPLATE_TYPE_DEFAULT_CHART,
		in_mime_type				=> 'text/plain',
		in_data						=> in_data
	);

END;

PROCEDURE DeleteDefaultTab
AS
	v_tab_id			tab.tab_id%TYPE;
BEGIN

	-- There isn't a SP to fetch the tab id. This could probably live in 
	-- portlet_pkg...
	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE name = 'My data'
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	IF v_tab_id IS NOT NULL THEN
		portlet_pkg.UNSECURED_DeleteTab(in_tab_id => v_tab_id);
	END IF;

END;

PROCEDURE EnsurePortletEnabled(
	in_type						IN	portlet.type%TYPE,
	out_customer_portlet_sid	OUT	tab_portlet.customer_portlet_sid%TYPE
)
AS
	v_portlet_id	portlet.portlet_id%TYPE;
BEGIN

	SELECT portlet_id
	  INTO v_portlet_id
	  FROM portlet
	 WHERE type = in_type;


	portlet_pkg.EnablePortletForCustomer(
		in_portlet_id	=> v_portlet_id
	);
	
	SELECT customer_portlet_sid
	  INTO out_customer_portlet_sid
	  FROM customer_portlet
	 WHERE portlet_id = v_portlet_id;
	
	
END;

PROCEDURE SetMenuParent(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID
)
AS
	v_menu_sid				security_pkg.T_SID_ID;
	v_existing_parent_sid	security_pkg.T_SID_ID;
BEGIN

	SELECT m.sid_id, so.parent_sid_id
	  INTO v_menu_sid, v_existing_parent_sid
	  FROM security.menu m
	  JOIN security.securable_object so on m.sid_id = so.sid_id
	 WHERE so.name = in_menu_so_name
	   AND so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_existing_parent_sid != in_parent_sid THEN
		security.menu_pkg.ReparentNode(
			in_menu_item_sid	=> v_menu_sid,
			in_new_parent_sid	=> in_parent_sid
		);
	END IF;
END;

PROCEDURE RemoveGroupFromAce(
	in_object_sid			IN	security_pkg.T_SID_ID,
	in_group_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN

	security.acl_pkg.RemoveACEsForSid(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'), 
		in_acl_id			=> security.acl_pkg.GetDACLIDForSID(in_object_sid), 
		in_remove_for_sid	=> in_group_sid
	);

END;

-- This SP looks up a menu SO by it's name rather than path - just in case 
-- it has been reparented. There shouldn't really be 2 menu items with the 
-- same name.
-- Will throw if there isn't exactly 1 matching result. The reponsibility is on
-- the caller to decide whether to catch, what to do, etc.
FUNCTION GetMenuSidBySoName(
	in_menu_so_name			IN security_pkg.T_SO_NAME
) RETURN security_pkg.T_SID_ID
AS
	v_sid					security_pkg.T_SID_ID;
BEGIN

	SELECT m.sid_id
	  INTO v_sid
	  FROM security.menu m
	  JOIN security.securable_object so on m.sid_id = so.sid_id
	 WHERE so.name = in_menu_so_name
	   AND so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_sid;

END;

PROCEDURE RemoveGroupFromMenuAce(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_group_sid			IN	security_pkg.T_SID_ID
)
AS
	v_menu_sid				security_pkg.T_SID_ID;
BEGIN

	v_menu_sid := GetMenuSidBySoName(in_menu_so_name => in_menu_so_name);
	RemoveGroupFromAce(in_object_sid => v_menu_sid, in_group_sid => in_group_sid);

END;

PROCEDURE AddGroupToAce(
	in_object_sid			IN	security_pkg.T_SID_ID,
	in_group_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN

	security.acl_pkg.AddACE(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'), 
		in_acl_id			=> security.acl_pkg.GetDACLIDForSID(in_object_sid), 
		in_acl_index		=> -1, 
		in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW, 
		in_ace_flags		=> security.security_pkg.ACE_FLAG_DEFAULT, 
		in_sid_id			=> in_group_sid, 
		in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
	);

END;

PROCEDURE AddGroupToMenuAce(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_group_sid			IN	security_pkg.T_SID_ID
)
AS
	v_menu_sid				security_pkg.T_SID_ID;
BEGIN

	v_menu_sid := GetMenuSidBySoName(in_menu_so_name => in_menu_so_name);
	AddGroupToAce(in_object_sid => v_menu_sid, in_group_sid => in_group_sid);

END;

PROCEDURE GetDocLibFolderRoot(
	out_folder_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_def_doc_lib_sid 		security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Documents');
BEGIN
	out_folder_sid := doc_folder_pkg.GetDocumentsFolder(
		in_doc_library_sid			=> v_def_doc_lib_sid
	);
END;

PROCEDURE GetOrCreateDocLibFolder(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	security_pkg.T_SO_NAME,
	out_sid_id				OUT	security_pkg.T_SID_ID
)
AS
BEGIN

	BEGIN
		SELECT doc_folder_sid 
		  INTO out_sid_id
		  FROM doc_folder_name_translation
		 WHERE parent_sid = in_parent_sid
		   AND translated = in_name
		   AND lang = 'en';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			doc_folder_pkg.CreateFolder(
				in_parent_sid			=> in_parent_sid, 
				in_name					=> in_name,
				in_is_system_managed	=> 0,
				out_sid_id				=> out_sid_id
			);
	END;
END;

PROCEDURE SetGlobalSettings(
	in_alert_mail_address			IN	customer.alert_mail_address%TYPE,
	in_alert_mail_name				IN	customer.alert_mail_name%TYPE,
	in_raise_reminders				IN	customer.raise_reminders%TYPE,
	in_raise_split_deleg_alerts		IN	customer.raise_split_deleg_alerts%TYPE,
	in_cascade_reject				IN	customer.cascade_reject%TYPE,
	in_allow_partial_submit			IN	customer.allow_partial_submit%TYPE,
	in_create_sheets_period_end		IN	customer.create_sheets_at_period_end%TYPE,
	in_incl_inactive_regions		IN	customer.incl_inactive_regions%TYPE,
	in_tear_off_deleg_header		IN	customer.tear_off_deleg_header%TYPE,
	in_deleg_dropdown_threshold		IN	customer.deleg_dropdown_threshold%TYPE
)
AS
	v_alert_mail_address			customer.alert_mail_address%TYPE;
	v_alert_mail_name				customer.alert_mail_name%TYPE;
	v_alert_batch_run_time			customer.alert_batch_run_time%TYPE;
	v_raise_reminders				customer.raise_reminders%TYPE;
	v_raise_split_deleg_alerts		customer.raise_split_deleg_alerts%TYPE;
	v_cascade_reject				customer.cascade_reject%TYPE;
	v_approver_response_window		customer.approver_response_Window%TYPE;
	v_self_reg_group_sid			customer.self_reg_group_sid%TYPE;
	v_self_reg_needs_approval		customer.self_reg_needs_approval%TYPE;
	v_self_reg_approver_sid			customer.self_reg_approver_sid%TYPE;
	v_lock_end_dtm					customer.lock_end_dtm%TYPE;
	v_allow_partial_submit			customer.allow_partial_submit%TYPE;
	v_create_sheets_period_end		customer.create_sheets_at_period_end%TYPE;
	v_incl_inactive_regions			customer.incl_inactive_regions%TYPE;
	v_lock_prevents_editing			customer.lock_prevents_editing%TYPE;
	v_tear_off_deleg_header			customer.tear_off_deleg_header%TYPE;
	v_deleg_dropdown_threshold		customer.deleg_dropdown_threshold%TYPE;
BEGIN

	SELECT alert_mail_address, alert_mail_name, alert_batch_run_time, raise_split_deleg_alerts,
		   raise_reminders, cascade_reject, approver_response_window, self_reg_group_sid,
		   self_reg_needs_approval, self_reg_approver_sid, lock_end_dtm,
		   allow_partial_submit, create_sheets_at_period_end, incl_inactive_regions,
		   lock_prevents_editing, deleg_dropdown_threshold
	  INTO v_alert_mail_address,v_alert_mail_name,v_alert_batch_run_time,v_raise_split_deleg_alerts,
		   v_raise_reminders,v_cascade_reject,v_approver_response_window,v_self_reg_group_sid,
		   v_self_reg_needs_approval,v_self_reg_approver_sid,v_lock_end_dtm,
		   v_allow_partial_submit,v_create_sheets_period_end,v_incl_inactive_regions,
		   v_lock_prevents_editing,v_deleg_dropdown_threshold
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');


	csr_data_pkg.SetConfiguration(
		in_alert_mail_address					=> NVL(in_alert_mail_address, v_alert_mail_address),
		in_alert_mail_name						=> NVL(in_alert_mail_name, v_alert_mail_name),
		in_alert_batch_run_time					=> v_alert_batch_run_time,
		in_raise_reminders						=> NVL(in_raise_reminders, v_raise_reminders),
		in_raise_split_deleg_alerts				=> NVL(in_raise_split_deleg_alerts, v_raise_split_deleg_alerts),
		in_cascade_reject						=> NVL(in_cascade_reject, v_cascade_reject),
		in_approver_response_window				=> v_approver_response_window,
		in_self_reg_group_sid					=> v_self_reg_group_sid,
		in_self_reg_needs_approval				=> v_self_reg_needs_approval,
		in_self_reg_approver_sid				=> v_self_reg_approver_sid,
		in_lock_end_dtm							=> v_lock_end_dtm,
		in_allow_partial_submit					=> NVL(in_allow_partial_submit, v_allow_partial_submit),
		in_create_sheets_period_end				=> NVL(in_create_sheets_period_end, v_create_sheets_period_end),
		in_incl_inactive_regions				=> NVL(in_incl_inactive_regions, v_incl_inactive_regions),
		in_lock_prevents_editing				=> v_lock_prevents_editing,
		in_tear_off_deleg_header				=> NVL(in_tear_off_deleg_header, v_tear_off_deleg_header),
		in_deleg_dropdown_threshold				=> NVL(in_deleg_dropdown_threshold, v_deleg_dropdown_threshold),
		in_auto_anonymisation_enabled			=> null,
		in_inactive_days_before_anonymisation	=> null
	);

END;

PROCEDURE SetLogonAsOnAcl(
	in_acl_id			IN Security_Pkg.T_ACL_ID,
	in_group_sid		IN Security_Pkg.T_SID_ID,
	in_permission_set	IN Security_Pkg.T_PERMISSION
)
AS
BEGIN

	security.acl_pkg.AddACE(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_acl_id			=> in_acl_id,
		in_acl_index		=> -1,
		in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags		=> security.security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id			=> in_group_sid,
		in_permission_set	=> in_permission_set
	);

END;

PROCEDURE SetupAdminLogonAs
AS
	v_class_id			NUMBER;
	v_admins			security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Administrators');
	v_perms_set			security.permission_name.permission%TYPE;
BEGIN

	SELECT class_id 
	  INTO v_class_id
	  FROM security.securable_object_class 
	 WHERE class_name = 'CSRUserGroup';
	
	SELECT permission
	  INTO v_perms_set
	  FROM security.permission_name
	 WHERE class_id = v_class_id
	   AND permission_name = 'Logon as another user';

	FOR r IN (
		SELECT dacl_id
		  FROM security.group_table g
		  JOIN security.securable_object so ON so.sid_id = g.sid_id
		 WHERE so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
		   AND class_id = v_class_id
		   AND name NOT IN (
				'RegisteredUsers',
				'Administrators'
		)
	)
	LOOP
		SetLogonAsOnAcl(
		in_acl_id			=> r.dacl_id,
		in_group_sid		=> v_admins,
		in_permission_set	=> v_perms_set
	);
	END LOOP;

END;

PROCEDURE FlagPackagedContentSite(
	in_enabled_modules_json		IN	packaged_content_site.enabled_modules_json%TYPE,
	in_version					IN	packaged_content_site.version%TYPE,
	in_package_name				IN	packaged_content_site.package_name%TYPE
)
AS
BEGIN

	INSERT INTO packaged_content_site
		(version, enabled_modules_json, package_name)
	VALUES
		(in_version, in_enabled_modules_json, in_package_name);

END;

END;
/
