CREATE OR REPLACE PACKAGE CSR.TEMP_US6151_PACKAGE IS

IMPORT_PLUGIN_TYPE_METER_RD			CONSTANT NUMBER(10) := 2;
ALERT_AUTO_IMPORT_COMPLETED 		CONSTANT NUMBER(10) := 66;
ALERT_AUTO_EXPORT_COMPLETED 		CONSTANT NUMBER(10) := 72;

ERR_MAILBOX_NOT_FOUND				CONSTANT NUMBER := -20506;
MAILBOX_NOT_FOUND					EXCEPTION;
PRAGMA EXCEPTION_INIT(MAILBOX_NOT_FOUND, -20506);

PROCEDURE EnableAutomatedExportImport
;

FUNCTION CreateCr360FTPProfile
RETURN ftp_profile.ftp_profile_id%TYPE
;

PROCEDURE CreateClass(
	in_label						IN	automated_import_class.label%TYPE,
	in_lookup_key					IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml					IN	automated_import_class.schedule_xml%TYPE,
	in_abort_on_error				IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error				IN	automated_import_class.email_on_error%TYPE,
	in_email_on_partial				IN	automated_import_class.email_on_partial%TYPE,
	in_email_on_success				IN	automated_import_class.email_on_success%TYPE,
	in_on_completion_sp				IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin				IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending_files	IN	automated_import_class.process_all_pending_files%TYPE DEFAULT 0,
	out_class_sid					OUT	automated_import_class.automated_import_class_sid%TYPE
);

FUNCTION MakeFTPReaderSettings(
	in_ftp_profile_id				IN	auto_imp_fileread_ftp.ftp_profile_id%TYPE,
	in_payload_path					IN	auto_imp_fileread_ftp.payload_path%TYPE,
	in_file_mask					IN	auto_imp_fileread_ftp.file_mask%TYPE,
	in_sort_by						IN	auto_imp_fileread_ftp.sort_by%TYPE,
	in_sort_by_direction			IN	auto_imp_fileread_ftp.sort_by_direction%TYPE,
	in_move_to_path_on_success		IN	auto_imp_fileread_ftp.move_to_path_on_success%TYPE,
	in_move_to_path_on_error		IN	auto_imp_fileread_ftp.move_to_path_on_error%TYPE,
	in_delete_on_success			IN	auto_imp_fileread_ftp.delete_on_success%TYPE,
	in_delete_on_error				IN	auto_imp_fileread_ftp.delete_on_error%TYPE
) RETURN NUMBER;

PROCEDURE AddFtpClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_ftp_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
);

PROCEDURE AddClassStep (
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE,
	in_fileread_plugin_id			IN	automated_import_class_step.FILEREAD_PLUGIN_ID%TYPE
);

PROCEDURE SetGenericImporterSettings(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_mapping_xml					IN	auto_imp_importer_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN	auto_imp_importer_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_excel_row_index				IN	auto_imp_importer_settings.excel_row_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_settings.all_or_nothing%TYPE
);

PROCEDURE AddAttachmentFilter(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_pos							IN	csr.auto_imp_mail_attach_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_mail_attach_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_mail_attach_filter.is_wildcard%TYPE,
	in_matched_import_class_sid		IN	csr.auto_imp_mail_attach_filter.matched_import_class_sid%TYPE,
	in_required_mimetype			IN	csr.auto_imp_mail_attach_filter.required_mimetype%TYPE,
	in_attachment_validator_plugin	IN	csr.auto_imp_mail_attach_filter.attachment_validator_plugin%TYPE
);

FUNCTION CreateFTPProfile (
	in_label						IN  ftp_profile.label%TYPE,
	in_host_name					IN  ftp_profile.host_name%TYPE,
	in_secure_credentials			IN  ftp_profile.secure_credentials%TYPE DEFAULT NULL,
	in_fingerprint					IN  ftp_profile.fingerprint%TYPE,
	in_username						IN  ftp_profile.username%TYPE,
	in_password						IN  ftp_profile.password%TYPE DEFAULT NULL,
	in_port_number					IN  ftp_profile.port_number%TYPE,
	in_ftp_protocol_id				IN  ftp_profile.ftp_protocol_id%TYPE
)
RETURN ftp_profile.ftp_profile_id%TYPE;

PROCEDURE CreateMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_new_sid						OUT	security_pkg.T_SID_ID
);

FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN mail.account.inbox_sid%TYPE;

PROCEDURE MarkMessageAsRead(
	in_mailbox_sid					IN	mail.mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mail.mailbox_message.message_uid%TYPE
);

END;
/


CREATE OR REPLACE PACKAGE BODY CSR.TEMP_US6151_PACKAGE IS

PROCEDURE EnableCapability(
	in_capability  					IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
)
AS
	v_allow_by_default		capability.allow_by_default%TYPE;
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;

    -- just create a sec obj of the right type in the right place
    BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				SYS_CONTEXT('SECURITY','APP'), 
				security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;
	
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
			v_capabilities_sid, 
			class_pkg.GetClassId('CSRCapability'),
			in_capability,
			v_capability_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			IF in_swallow_dup_exception = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
			END IF;
	END;
END;

PROCEDURE EnableAutomatedExportImport
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	-- container
	v_auto_imports_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_exports_container_sid 	security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 						security.security_pkg.T_SID_ID;
	v_www_csr_site 					security.security_pkg.T_SID_ID;
	v_www_csr_site_automated		security.security_pkg.T_SID_ID;
	--Menu
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_automated_menu			security.security_pkg.T_SID_ID;
	--Alert id
	v_importcomplete_alert_type_id	NUMBER;
	v_exportcomplete_alert_type_id	NUMBER;
BEGIN

	--Variables
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
	v_admins 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, v_groups_sid, 'Administrators');

	v_importcomplete_alert_type_id := TEMP_US6151_PACKAGE.ALERT_AUTO_IMPORT_COMPLETED;
	v_exportcomplete_alert_type_id := TEMP_US6151_PACKAGE.ALERT_AUTO_EXPORT_COMPLETED;

	--Create the container for the SOs
	--I don't add any ACLs as the administrators group should inherit down from root node
	BEGIN
	security.securableobject_pkg.CreateSO(v_act_id,
		v_app_sid,
		security.security_pkg.SO_CONTAINER,
		'AutomatedImports',
		v_auto_imports_container_sid
	);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auto_imports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedImports');
	END;
	BEGIN
	security.securableobject_pkg.CreateSO(v_act_id,
		v_app_sid,
		security.security_pkg.SO_CONTAINER,
		'AutomatedExports',
		v_auto_exports_container_sid
	);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_auto_exports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExports');
	END;

	--Create the web resources
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

	BEGIN
		v_www_csr_site_automated := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/automatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'automatedExportImport', v_www_csr_site_automated);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_automated), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_admins, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	--Create the menu item
	v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
			'csr_site_cmsimp_impinstances',
			'Scheduled exports and imports',
			'/csr/site/automatedExportImport/impinstances.acds',
			12, null, v_admin_automated_menu);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	--Add the capability - will inherit from the container (administrators)
	TEMP_US6151_PACKAGE.enablecapability('Manually import automated import instances');
	TEMP_US6151_PACKAGE.enablecapability('Can run additional automated import instances');
	TEMP_US6151_PACKAGE.enablecapability('Can run additional automated export instances');
	TEMP_US6151_PACKAGE.enablecapability('Can preview automated exports');

	--Create the alerts
	BEGIN
			INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (v_app_sid, customer_alert_type_id_seq.nextval, v_importcomplete_alert_type_id);

			INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
			  FROM alert_frame af
			  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = v_app_sid
			   AND cat.std_alert_type_id = v_importcomplete_alert_type_id
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

			INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM default_alert_template_body d
			  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id = v_importcomplete_alert_type_id
			   AND d.lang='en'
			   AND t.application_sid = v_app_sid
			   AND cat.app_sid = v_app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
			INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (v_app_sid, customer_alert_type_id_seq.nextval, v_exportcomplete_alert_type_id);

			INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
			  FROM alert_frame af
			  JOIN customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = v_app_sid
			   AND cat.std_alert_type_id = v_exportcomplete_alert_type_id
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

			INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM default_alert_template_body d
			  JOIN customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id = v_exportcomplete_alert_type_id
			   AND d.lang='en'
			   AND t.application_sid = v_app_sid
			   AND cat.app_sid = v_app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION CreateCr360FTPProfile
RETURN ftp_profile.ftp_profile_id%TYPE
AS
	v_ftp_profile_id				ftp_profile.ftp_profile_id%TYPE;
BEGIN
	BEGIN
		SELECT ftp_profile_id
		  INTO v_ftp_profile_id
		  FROM ftp_profile
		 WHERE host_name = 'CYANOXANTHA';
	EXCEPTION
		WHEN no_data_found THEN
			v_ftp_profile_id := CreateFTPProfile(
				in_label						=> 'Cr360 SFTP',
				in_host_name					=> 'CYANOXANTHA',
				in_fingerprint					=> 'ssh-rsa 2048 f8:34:18:03:83:5f:9d:95:13:b4:85:4d:d0:71:85:57',
				in_username						=> 'cmsimport',
				in_port_number					=> 2222,
				in_ftp_protocol_id				=> 2
			);
	END;
	RETURN v_ftp_profile_id;
END;

PROCEDURE CreateClass(
	in_label						IN	automated_import_class.label%TYPE,
	in_lookup_key					IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml					IN	automated_import_class.schedule_xml%TYPE,
	in_abort_on_error				IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error				IN	automated_import_class.email_on_error%TYPE,
	in_email_on_partial				IN	automated_import_class.email_on_partial%TYPE,
	in_email_on_success				IN	automated_import_class.email_on_success%TYPE,
	in_on_completion_sp				IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin				IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending_files	IN	automated_import_class.process_all_pending_files%TYPE DEFAULT 0,
	out_class_sid					OUT	automated_import_class.automated_import_class_sid%TYPE
)
AS
	v_imports_sid				security.security_pkg.T_SID_ID;
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Find the imports container. If can't find, not enabled to bail
	BEGIN
		v_imports_sid := security.securableObject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedImports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'AutomatedImports container not found - please enable Automated Export Import framework via the enable page first.');
	END;

	-- Create the SO
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_imports_sid, class_pkg.getClassID('CSRAutomatedImport'), in_label, out_class_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			RAISE_APPLICATION_ERROR(-20001, 'An import with that name already exists.');
	END;

	INSERT INTO automated_import_class
		(automated_import_class_sid, label, lookup_key, schedule_xml, last_scheduled_dtm, rerun_asap, abort_on_error, email_on_error, email_on_partial,
		 email_on_success, on_completion_sp, import_plugin, process_all_pending_files)
	VALUES
		(out_class_sid, in_label, in_lookup_key, in_schedule_xml, CASE WHEN in_schedule_xml IS NULL THEN NULL ELSE SYSDATE-1 END, 0, in_abort_on_error, in_email_on_error, in_email_on_partial,
		 in_email_on_success, in_on_completion_sp, in_import_plugin, in_process_all_pending_files);
END;

FUNCTION MakeFTPReaderSettings(
	in_ftp_profile_id				IN	auto_imp_fileread_ftp.ftp_profile_id%TYPE,
	in_payload_path					IN	auto_imp_fileread_ftp.payload_path%TYPE,
	in_file_mask					IN	auto_imp_fileread_ftp.file_mask%TYPE,
	in_sort_by						IN	auto_imp_fileread_ftp.sort_by%TYPE,
	in_sort_by_direction			IN	auto_imp_fileread_ftp.sort_by_direction%TYPE,
	in_move_to_path_on_success		IN	auto_imp_fileread_ftp.move_to_path_on_success%TYPE,
	in_move_to_path_on_error		IN	auto_imp_fileread_ftp.move_to_path_on_error%TYPE,
	in_delete_on_success			IN	auto_imp_fileread_ftp.delete_on_success%TYPE,
	in_delete_on_error				IN	auto_imp_fileread_ftp.delete_on_error%TYPE
)
RETURN NUMBER
AS
	v_settings_id						NUMBER;
BEGIN
	SELECT auto_imp_fileread_ftp_id_seq.nextval
	  INTO v_settings_id
	  FROM dual;

	INSERT INTO auto_imp_fileread_ftp
		(auto_imp_fileread_ftp_id, ftp_profile_id, payload_path, file_mask, sort_by, sort_by_direction, move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error)
	VALUES
		(v_settings_id, in_ftp_profile_id, in_payload_path, in_file_mask, in_sort_by, in_sort_by_direction, in_move_to_path_on_success, in_move_to_path_on_error, in_delete_on_success, in_delete_on_error);

	return v_settings_id;
END;

PROCEDURE AddFtpClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_ftp_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
)
AS
BEGIN
	-- FTP reader is 1; select * from AUTO_IMP_FILEREAD_PLUGIN;
	INSERT INTO automated_import_class_step
		(automated_import_class_sid, step_number, on_completion_sp, on_failure_sp, days_to_retain_payload, plugin, fileread_plugin_id, auto_imp_fileread_ftp_id, importer_plugin_id)
	VALUES
		(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, 1, in_ftp_settings_id, in_importer_plugin_id);
END;

PROCEDURE AddClassStep (
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE,
	in_fileread_plugin_id			IN	automated_import_class_step.FILEREAD_PLUGIN_ID%TYPE
)
AS
BEGIN
	INSERT INTO automated_import_class_step
		(automated_import_class_sid, step_number, on_completion_sp, on_failure_sp, days_to_retain_payload, plugin, fileread_plugin_id, importer_plugin_id)
	VALUES
		(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, in_fileread_plugin_id, in_importer_plugin_id);
END;

PROCEDURE SetGenericImporterSettings(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_mapping_xml					IN	auto_imp_importer_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN	auto_imp_importer_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_excel_row_index				IN	auto_imp_importer_settings.excel_row_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_settings.all_or_nothing%TYPE
)
AS
	v_settings_id					auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
	v_mapping_xml					auto_imp_importer_cms.mapping_xml%TYPE;
	v_imp_file_type_id				auto_imp_importer_cms.cms_imp_file_type_id%TYPE;
	v_dsv_separator					auto_imp_importer_cms.dsv_separator%TYPE;
	v_dsv_quotes_as_literals		auto_imp_importer_cms.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index			auto_imp_importer_cms.excel_worksheet_index%TYPE;
	v_all_or_nothing				auto_imp_importer_cms.all_or_nothing%TYPE;
BEGIN
	BEGIN
		INSERT INTO auto_imp_importer_settings 
			(auto_imp_importer_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing)
		VALUES 
			(auto_importer_settings_id_seq.nextval, in_import_class_sid, in_step_number, in_mapping_xml, in_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_all_or_nothing);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			SELECT mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing
			  INTO v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing			
			  FROM auto_imp_importer_settings
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			
			UPDATE auto_imp_importer_settings
			   SET mapping_xml = in_mapping_xml,
				   automated_import_file_type_id = in_imp_file_type_id,
				   dsv_separator = in_dsv_separator,
				   dsv_quotes_as_literals = in_dsv_quotes_as_literals,
				   excel_worksheet_index = in_excel_worksheet_index,
			   excel_row_index = in_excel_row_index,
				   all_or_nothing = in_all_or_nothing
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE AddAttachmentFilter(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_pos							IN	csr.auto_imp_mail_attach_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_mail_attach_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_mail_attach_filter.is_wildcard%TYPE,
	in_matched_import_class_sid		IN	csr.auto_imp_mail_attach_filter.matched_import_class_sid%TYPE,
	in_required_mimetype			IN	csr.auto_imp_mail_attach_filter.required_mimetype%TYPE,
	in_attachment_validator_plugin	IN	csr.auto_imp_mail_attach_filter.attachment_validator_plugin%TYPE
)
AS
BEGIN
	INSERT INTO auto_imp_mail_attach_filter
		(mailbox_sid, pos, filter_string, is_wildcard, matched_import_class_sid, required_mimetype, attachment_validator_plugin)
	VALUES
		(in_mailbox_sid, in_pos, in_filter_string, in_is_wildcard, in_matched_import_class_sid, in_required_mimetype, in_attachment_validator_plugin);
END;

FUNCTION CreateFTPProfile (
	in_label						IN  ftp_profile.label%TYPE,
	in_host_name					IN  ftp_profile.host_name%TYPE,
	in_secure_credentials			IN  ftp_profile.secure_credentials%TYPE DEFAULT NULL,
	in_fingerprint					IN  ftp_profile.fingerprint%TYPE,
	in_username						IN  ftp_profile.username%TYPE,
	in_password						IN  ftp_profile.password%TYPE DEFAULT NULL,
	in_port_number					IN  ftp_profile.port_number%TYPE,
	in_ftp_protocol_id				IN  ftp_profile.ftp_protocol_id%TYPE
)
RETURN ftp_profile.ftp_profile_id%TYPE
AS
	v_ftp_profile_id				ftp_profile.ftp_profile_id%TYPE;
BEGIN
	INSERT INTO ftp_profile (ftp_profile_id, label, host_name, secure_credentials, fingerprint, username, password, port_number, ftp_protocol_id)
		 VALUES (ftp_profile_id_seq.nextval, in_label, in_host_name, in_secure_credentials, in_fingerprint, in_username, in_password, in_port_number, in_ftp_protocol_id)
	  RETURNING ftp_profile_id INTO v_ftp_profile_id;

	RETURN v_ftp_profile_id;
END;

PROCEDURE CreateCsrMailbox(
	in_email_address		IN	mail.account.email_address%TYPE,
	out_new_sid				OUT	mail.mailbox.mailbox_sid%TYPE
)
AS
	v_account_sid				mail.account.account_sid%TYPE;
	v_admins_sid				security_pkg.T_SID_ID;
BEGIN

		-- Create the mail account
	mail.mail_pkg.createAccount(
		in_email_address				=> in_email_address,
		in_password						=> NULL,
		in_description					=> '',
		in_for_outlook					=> 0,
		in_class_id						=> security.class_pkg.getClassId('CSRMailbox'),
		out_account_sid					=> v_account_sid,
		out_root_mailbox_sid			=> out_new_sid
	);
	
	-- Get hold of the host's adminstrators group sid
	v_admins_sid := securableobject_pkg.GetSidFromPath(
		security_pkg.getACT, 
		securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, 
			security_pkg.getAPP, 
			'Groups'
		), 
		'Administrators'
	);
	
	-- Set permissions on the root folder and propagate
	acl_pkg.AddACE(
		security_pkg.GetACT, 
		acl_pkg.GetDACLIDForSID(out_new_sid), 
		-1, 
		security_pkg.ACE_TYPE_ALLOW, 
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins_sid,
		security_pkg.PERMISSION_STANDARD_READ
	);
	
	acl_pkg.PropogateACEs(
		security_pkg.GetACT, 
		out_new_sid
	);

END;

PROCEDURE CreateMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_new_sid						OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CreateCsrMailbox(
		in_email_address		=> in_email_address,
		out_new_sid				=> out_new_sid
	);
	
	INSERT INTO csr.auto_imp_mailbox
		(address, mailbox_sid, body_validator_plugin, use_full_mail_logging, matched_imp_class_sid_for_body)
	VALUES
		(in_email_address, out_new_sid, in_body_plugin, in_use_full_logging, in_matched_class_sid_for_body);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id						=> in_user_sid,
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_EXPIMP_MAILBOX,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> out_new_sid,
		in_description					=> 'Automated import mailbox "{0}" created',
		in_param_1						=> in_email_address
	);
		
END;

FUNCTION getInboxSIDFromEmail(
	in_email_address				IN	VARCHAR2
) RETURN mail.account.inbox_sid%TYPE
AS
	v_inbox_sid mail.account.inbox_sid%TYPE;
BEGIN
	BEGIN
		SELECT a.inbox_sid
		  INTO v_inbox_sid
		  FROM mail.account_alias aa, mail.account a
		 WHERE LOWER(aa.email_address) = LOWER(in_email_address)
		   AND a.account_sid = aa.account_sid;
		 
		RETURN v_inbox_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE MAILBOX_NOT_FOUND;
	END;
END;

PROCEDURE MarkMessageAsRead(
	in_mailbox_sid					IN	mail.mailbox_message.mailbox_sid%TYPE,
	in_message_uid					IN	mail.mailbox_message.message_uid%TYPE
)
AS
	v_modseq						mail.mailbox.modseq%TYPE;
BEGIN
	UPDATE mail.mailbox
	   SET modseq = modseq + 1
	 WHERE mailbox_sid = in_mailbox_sid
	 	   RETURNING modseq INTO v_modseq;
	 	   
	UPDATE mail.mailbox_message
	   SET modseq = v_modseq, flags = security.bitwise_pkg.bitor(flags, 4 /*mail_pkg.Flag_Seen*/)
	 WHERE mailbox_sid = in_mailbox_sid AND message_uid = in_message_uid
	   AND bitand(flags, 4 + 2 /*mail_pkg.Flag_Seen + mail_pkg.Flag_deleted*/) = 0;
END;

END;
/

