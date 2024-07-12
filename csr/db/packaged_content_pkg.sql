CREATE OR REPLACE PACKAGE csr.packaged_content_pkg AS

PROCEDURE SetImagePortlet(
	in_blob			IN	image_upload_portlet.image%TYPE,
	in_filename		IN	image_upload_portlet.file_name%TYPE,
	in_mime_type	IN	image_upload_portlet.mime_type%TYPE,
	out_image_id	OUT	image_upload_portlet.img_id%TYPE
);

PROCEDURE AddDocToLibraryFolder(
	in_filename				IN	doc_version.filename%TYPE,
	in_folder_path			IN	VARCHAR2,
	in_doc_data				IN	doc_data.data%TYPE,
	in_mime_type			IN	doc_data.mime_type%TYPE,
	in_description			IN	doc_version.description%TYPE,
	out_doc_id				OUT	doc.doc_id%TYPE
);

PROCEDURE EnableLanguage(
	in_lang				aspen2.lang.lang%TYPE
);

PROCEDURE HideLanguage(
	in_lang				aspen2.lang.lang%TYPE
);

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
);

PROCEDURE SetAlertFrame(
	in_lang					IN	alert_frame_body.lang%TYPE,
	in_html					IN	alert_frame_body.html%TYPE
);

PROCEDURE CreateDashboardTab(
	in_tab_name			IN	tab.name%TYPE,
	in_layout			IN	tab.layout%TYPE,
	in_override_pos		IN	tab.override_pos%TYPE,
	in_owner_user_sid	IN	csr_user.csr_user_sid%TYPE,
	out_tab_id			OUT	tab.tab_id%TYPE
);

PROCEDURE AddTabForGroup(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_group_name		IN	security_pkg.T_SO_NAME
);

PROCEDURE AddTabForRole(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_role_name		IN	security_pkg.T_SO_NAME
);

PROCEDURE AddPortletToTab(
	in_tab_id			IN	tab_portlet.tab_id%TYPE,
	in_type				IN	portlet.type%TYPE,
	in_initial_state	IN	tab_portlet.state%TYPE,
	out_tab_portlet_id	OUT	tab_portlet.tab_portlet_id%TYPE
);

PROCEDURE SetTabPortletPosition(
	in_tab_portlet_id	IN	tab_portlet.tab_portlet_id%TYPE,
	in_column			IN	tab_portlet.column_num%TYPE,
	in_pos				IN	tab_portlet.pos%TYPE
);

PROCEDURE WriteToObjectMap(
	in_object_ref			IN	packaged_content_object_map.object_ref%TYPE,
	in_created_object_id	IN	packaged_content_object_map.created_object_id%TYPE
);

PROCEDURE SetChartTemplate(
	in_data						IN	FILE_UPLOAD.data%TYPE
);

PROCEDURE DeleteDefaultTab;

PROCEDURE EnsurePortletEnabled(
	in_type						IN	portlet.type%TYPE,
	out_customer_portlet_sid	OUT	tab_portlet.customer_portlet_sid%TYPE
);

PROCEDURE SetMenuParent(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveGroupFromMenuAce(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_group_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE AddGroupToMenuAce(
	in_menu_so_name			IN	security.securable_object.name%TYPE,
	in_group_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetDocLibFolderRoot(
	out_folder_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE GetOrCreateDocLibFolder(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	security_pkg.T_SO_NAME,
	out_sid_id				OUT	security_pkg.T_SID_ID
);

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
);

PROCEDURE SetupAdminLogonAs;

PROCEDURE FlagPackagedContentSite(
	in_enabled_modules_json		IN	packaged_content_site.enabled_modules_json%TYPE,
	in_version					IN	packaged_content_site.version%TYPE,
	in_package_name				IN	packaged_content_site.package_name%TYPE
);

END;
/
