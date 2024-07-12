CREATE OR REPLACE PACKAGE csr.automated_import_pkg AS

IMPORT_PLUGIN_TYPE_CMS				CONSTANT NUMBER(10) := 1;
IMPORT_PLUGIN_TYPE_METER_RD			CONSTANT NUMBER(10) := 2;
IMPORT_PLUGIN_TYPE_XML_BULK			CONSTANT NUMBER(10) := 3;
IMPORT_PLUGIN_TYPE_CORE_DATA		CONSTANT NUMBER(10) := 4;
IMPORT_PLUGIN_TYPE_ZIP_EXTRC		CONSTANT NUMBER(10) := 5;
IMPORT_PLUGIN_TYPE_USER				CONSTANT NUMBER(10) := 6;
IMPORT_PLUGIN_TYPE_PRODUCT			CONSTANT NUMBER(10) := 7;

FILEREADER_PLUGIN_FTP			CONSTANT NUMBER(10) := 1;
FILEREADER_PLUGIN_DATABASE		CONSTANT NUMBER(10) := 2;
FILEREADER_PLUGIN_MANUAL		CONSTANT NUMBER(10) := 3;
FILEREADER_PLUGIN_FTP_FOLDER	CONSTANT NUMBER(10) := 4;

FILE_TYPE_DSV		CONSTANT NUMBER(10) := 0;
FILE_TYPE_EXCEL		CONSTANT NUMBER(10) := 1;
FILE_TYPE_XML		CONSTANT NUMBER(10) := 2;

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

FUNCTION EmptySidIds
RETURN security_pkg.T_SID_IDS;

PROCEDURE DeleteClass(
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE GetClass(
	in_import_class_sid			IN	automated_import_class.automated_import_class_sid%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetClasses(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetJob(
	in_batch_job_id				IN	automated_import_instance.batch_job_id%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetInstance(
	in_instance_id				IN	automated_import_instance.batch_job_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR,
	out_message_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetClassInstances(
	in_automated_import_class_sid	IN	security_pkg.T_SID_ID,
	in_start_row    				IN	NUMBER,
	in_end_row      				IN	NUMBER,
	out_cur         				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMostRecentInstances(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetFtpSettings(
	in_automated_import_class_sid		IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE GetDbReaderSettings(
	in_automated_import_class_sid		IN	automated_import_instance.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE WriteInstanceStepStart(
	in_class_sid				IN	automated_import_instance_step.automated_import_class_sid%TYPE,
	in_instance_id				IN	automated_import_instance_step.automated_import_instance_id%TYPE,
	in_step_number				IN	automated_import_instance_step.step_number%TYPE,
	out_instance_step_id		OUT	automated_import_instance_step.auto_import_instance_step_id%TYPE
);

PROCEDURE WriteInstanceStepResult(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_result				IN	automated_import_instance_step.result%TYPE
);

PROCEDURE WriteInstanceStepErrorResult(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_result				IN	automated_import_instance_step.result%TYPE,
	in_error_payload		IN	automated_import_instance_step.error_payload%TYPE,
	in_error_filename		IN	automated_import_instance_step.error_filename%TYPE
);

PROCEDURE WritePayload(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_payload_blob			IN	automated_import_instance_step.payload%TYPE,
	in_filename				IN	automated_import_instance_step.payload_filename%TYPE
);

PROCEDURE GetCmsImportSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);


PROCEDURE GetGenericImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetManualFile(
	in_sid							IN	NUMBER,
	in_instance_id					IN	NUMBER,
	in_step_number					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateInstanceStepFile(
	in_instance_step_id		IN	automated_import_instance_STEP.auto_import_instance_step_id%TYPE,
	in_payload				IN	BLOB,
	in_payload_filename		IN	automated_import_instance_STEP.payload_filename%TYPE
);

PROCEDURE GetInstancesByFileName(
	in_payload_filename				IN	automated_import_instance_STEP.payload_filename%TYPE,
	out_cur							OUT sys_refcursor
);

PROCEDURE GetFile(
	in_auto_imp_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	out_cur								OUT sys_refcursor
);

PROCEDURE GetErrorFile(
	in_auto_imp_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	out_cur								OUT sys_refcursor
);

PROCEDURE GetPayloadFileName(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	in_step_number				IN	automated_import_instance_step.step_number%TYPE,
	out_filename				OUT varchar2
);

PROCEDURE CreateManualInstance(
	in_class_sid			IN	automated_import_class_step.automated_import_class_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetManualFile(
	in_cms_instance_id		IN	NUMBER,
	in_step_number			IN	NUMBER,
	in_file_data			IN	BLOB,
	in_file_name			IN	VARCHAR2
);

PROCEDURE CreateChildInstanceAndStep(
	in_class_sid			IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_parent_instance_id	IN	NUMBER,
	in_file_data			IN	BLOB,
	in_file_name			IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_number_of_steps				IN	BATCH_JOB.total_work%TYPE,
	in_is_manual					IN	automated_import_instance.is_manual%TYPE,
	in_is_from_bus					IN	automated_import_instance.is_from_bus%TYPE DEFAULT 0,
	in_parent_instance_id			IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	in_mailbox_sid					IN	automated_import_instance.mailbox_sid%TYPE DEFAULT NULL,
	in_mail_message_uid				IN	automated_import_instance.mail_message_uid%TYPE DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_number_of_steps				IN	BATCH_JOB.total_work%TYPE,
	in_is_manual					IN	automated_import_instance.is_manual%TYPE,
	in_is_from_bus					IN	automated_import_instance.is_from_bus%TYPE DEFAULT 0,
	in_parent_instance_id			IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	in_mailbox_sid					IN	automated_import_instance.mailbox_sid%TYPE DEFAULT NULL,
	in_mail_message_uid				IN	automated_import_instance.mail_message_uid%TYPE DEFAULT NULL,
	out_auto_import_instance_id		OUT	automated_import_instance.automated_import_instance_id%TYPE
);

PROCEDURE TriggerInstance(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE,
	in_parent_instance_id		IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE CountPriorInstances(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE,
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_result					OUT	NUMBER
);

PROCEDURE WriteDebugLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
);

PROCEDURE WriteSessionLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
);

PROCEDURE GetDebugLogFile(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_cur						OUT sys_refcursor
);

PROCEDURE GetSessionLogFile(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_cur						OUT sys_refcursor
);

/* SCHEDULE PROCEDURES */

FUNCTION ValidateClass(
	in_class_sid		IN	NUMBER
) RETURN NUMBER;

PROCEDURE ScheduleRun;

PROCEDURE CheckForNewJobs;

PROCEDURE ClearupInstancePayloads;

/* SETUP SCRIPTS */

PROCEDURE CreateClass(
	in_parent				IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_label				IN	automated_import_class.label%TYPE,
	in_lookup_key			IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml			IN	automated_import_class.schedule_xml%TYPE,
	in_abort_on_error		IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error		IN	automated_import_class.email_on_error%TYPE,
	in_email_on_partial		IN	automated_import_class.email_on_partial%TYPE,
	in_email_on_success		IN	automated_import_class.email_on_success%TYPE,
	in_on_completion_sp		IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin		IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending_files	IN	automated_import_class.process_all_pending_files%TYPE DEFAULT 0,
	out_class_sid			OUT	automated_import_class.automated_import_class_sid%TYPE
);

PROCEDURE AddStepToClass(
	in_import_class_sid			IN	NUMBER,
	in_step_number				IN 	NUMBER,
	in_importer_plugin_id		IN	NUMBER,
	in_fileread_plugin_id		IN	NUMBER
);

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

PROCEDURE AddDbClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_db_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_DB_ID%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
);

PROCEDURE AddManualClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
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
	in_fileread_plugin_id			IN	automated_import_class_step.FILEREAD_PLUGIN_ID%TYPE,
	in_fileread_db_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_DB_ID%TYPE DEFAULT NULL,
	in_fileread_ftp_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE DEFAULT NULL
);

PROCEDURE SetStepFtpAndCmsSettings (
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_cms_settings_id				IN	auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE,
	in_ftp_settings_id				IN	auto_imp_fileread_ftp.auto_imp_fileread_ftp_id%TYPE
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
)
RETURN NUMBER;

FUNCTION MakeDBReaderSettings(
	in_filedata_sp				IN	auto_imp_fileread_db.filedata_sp%TYPE
)
RETURN NUMBER;

FUNCTION MakeCmsImporterSettings(
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
)
RETURN NUMBER;

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

PROCEDURE AddCmsFtpStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_ftp_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE,
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
);

PROCEDURE AddCmsManualStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
);

PROCEDURE GetImportClasses(
	out_cur                         OUT SYS_REFCURSOR
);

PROCEDURE UpdateImportClass(
	in_automated_import_class_sid		IN	automated_import_class.automated_import_class_sid%TYPE,
	in_label							IN	automated_import_class.label%TYPE,
	in_contains_pii						IN	automated_import_class.contains_pii%TYPE,
	in_lookup_key						IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml						IN	VARCHAR2,
	in_last_scheduled_dtm				IN	automated_import_class.last_scheduled_dtm%TYPE,
	in_abort_on_error					IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error					IN	automated_import_class.email_on_error%TYPE,
	in_email_on_success					IN	automated_import_class.email_on_success%TYPE,
	in_email_on_partial					IN	automated_import_class.email_on_partial%TYPE,
	in_on_completion_sp					IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin					IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending				IN	automated_import_class.process_all_pending_files%TYPE
);

PROCEDURE UpdateImportClassStep(
	in_automated_import_class_sid		IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	in_on_completion_sp					IN	automated_import_class_step.on_completion_sp%TYPE,
	in_on_failure_sp					IN	automated_import_class_step.on_failure_sp%TYPE DEFAULT NULL,
	in_days_to_retain_payload			IN	automated_import_class_step.days_to_retain_payload%TYPE,
	in_plugin							IN	automated_import_class_step.plugin%TYPE,
	in_ignore_file_not_found_xcptn		IN	automated_import_class_step.ignore_file_not_found_excptn%TYPE DEFAULT 0,
	in_fileread_plugin_id				IN	automated_import_class_step.fileread_plugin_id%TYPE DEFAULT NULL,
	in_fileread_ftp_id					IN	automated_import_class_step.auto_imp_fileread_ftp_id%TYPE DEFAULT NULL,
	in_fileread_db_id					IN	automated_import_class_step.auto_imp_fileread_db_id%TYPE DEFAULT NULL,
	in_enable_decryption				IN	automated_import_class_step.enable_decryption%TYPE DEFAULT 0
);

PROCEDURE GetFtpFileReaderSettings(
	out_cur						 	OUT SYS_REFCURSOR
);

PROCEDURE UpdateFtpFileReaderSettings(
	in_sid						  	IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				  	IN automated_import_class_step.step_number%TYPE,
	in_ftp_profile_id				IN auto_imp_fileread_ftp.ftp_profile_id%TYPE,
	in_payload_path				 	IN auto_imp_fileread_ftp.payload_path%TYPE,
	in_file_mask					IN auto_imp_fileread_ftp.file_mask%TYPE,
	in_sort_by					  	IN auto_imp_fileread_ftp.sort_by%TYPE,
	in_sort_by_dir				  	IN auto_imp_fileread_ftp.sort_by_direction%TYPE,
	in_move_to_path_on_success	  	IN auto_imp_fileread_ftp.move_to_path_on_success%TYPE,
	in_move_to_path_on_error		IN auto_imp_fileread_ftp.move_to_path_on_error%TYPE,
	in_delete_on_success			IN auto_imp_fileread_ftp.delete_on_success%TYPE,
	in_delete_on_error			  	IN auto_imp_fileread_ftp.delete_on_error%TYPE
);

PROCEDURE GetCmsImportSettings(
	out_cur						 	OUT SYS_REFCURSOR
);

PROCEDURE UpdateCmsImportSettings(
	in_sid						  	IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				  	IN automated_import_class_step.step_number%TYPE,
	in_tab_sid					  	IN auto_imp_importer_cms.tab_sid%TYPE DEFAULT NULL,
	in_mapping_xml					IN VARCHAR2,
	in_cms_imp_file_type_id			IN auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals	   	IN auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing			   	IN auto_imp_importer_cms.all_or_nothing%TYPE,
	in_header_row				   	IN auto_imp_importer_cms.header_row%TYPE
);

PROCEDURE UpdateDbFileReaderSettings(
	in_sid							IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number					IN automated_import_class_step.step_number%TYPE,
	in_filedata_sp					IN	auto_imp_fileread_db.filedata_sp%TYPE
);

PROCEDURE UpdateMeterImportSettings(
	in_sid							IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number					IN automated_import_class_step.step_number%TYPE,
	in_mapping_xml					IN auto_imp_importer_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN auto_imp_importer_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN auto_imp_importer_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN auto_imp_importer_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN auto_imp_importer_settings.all_or_nothing%TYPE
);

PROCEDURE GetFileTypes(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetImporters(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFileReaders(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFileFromPreviousStep(
	in_importclass_sid				IN	security.security_pkg.T_SID_ID,
	in_instance_id					IN	LONG,
	in_step_number					IN	LONG,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

-- CORE DATA IMPORTER SPs

PROCEDURE GetIndSidFromDescription(
	in_description		IN	ind_description.description%TYPE,
	out_ind_sid			OUT	ind_description.ind_sid%TYPE
);

PROCEDURE GetIndSidFromLookupKey(
	in_text				IN	ind.lookup_key%TYPE,
	out_ind_sid			OUT	ind.ind_sid%TYPE
);

PROCEDURE GetIndSidFromMapTable(
	in_text				IN	ind.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_ind_sid			OUT	ind.ind_sid%TYPE
);

PROCEDURE GetRegionSidFromDescription(
	in_description		IN	region_description.description%TYPE,
	out_region_sid		OUT	region_description.region_sid%TYPE
);

PROCEDURE GetRegionSidFromLookupKey(
	in_text				IN	region.lookup_key%TYPE,
	out_region_sid		OUT	region.region_sid%TYPE
);

PROCEDURE GetRegionSidFromMapTable(
	in_text				IN	region.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_region_sid		OUT	region.region_sid%TYPE
);

PROCEDURE GetUnitSidFromDescription(
	in_description		IN	measure_conversion.description%TYPE,
	in_ind_sid			IN	ind.ind_sid%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
);

PROCEDURE GetUnitSidFromLookupKey(
	in_text				IN	measure_conversion.lookup_key%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
);

PROCEDURE GetUnitSidFromMapTable(
	in_text				IN	measure_conversion.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
);

PROCEDURE CheckConversionAgainstInd (
	in_conv_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_ind_sid			IN	ind.ind_sid%TYPE,
	out_result			OUT	NUMBER
);

PROCEDURE InsertCoreDataPoint(
	in_instance_id				IN 	NUMBER,
	in_instance_step_id			IN 	NUMBER,
	in_ind_sid					IN 	NUMBER,
	in_region_sid				IN 	NUMBER,
	in_start_dtm				IN 	DATE,
	in_end_dtm					IN 	DATE,
	in_val_number				IN 	NUMBER,
	in_measure_conversion_id	IN 	NUMBER,
	in_entry_val_number			IN 	NUMBER,
	in_note						IN 	CLOB,
	in_source_file_ref			IN 	VARCHAR2,
	out_val_id					OUT NUMBER
);

PROCEDURE WriteCoreDataFailedRow(
	in_instance_id				IN	NUMBER,
	in_instance_step_id			IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	in_entry_val_number			IN	NUMBER,
	in_note						IN	CLOB,
	in_source_file_ref			IN	VARCHAR2,
	in_ind_sid					IN	NUMBER,
	in_ind_text					IN	VARCHAR2,
	in_region_sid				IN	NUMBER,
	in_region_text				IN	VARCHAR2,
	in_measure_conversion_id	IN	NUMBER,
	in_measure_conversion_text	IN	VARCHAR2
);

PROCEDURE GetFailedMappingsForClass(
	in_class_sid			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMappingsForClass(
	in_class_sid			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
);

PROCEDURE UpsertRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE,
	in_region_sid			IN	auto_imp_region_map.region_sid%TYPE,
	out_val_id				OUT NUMBER
);

PROCEDURE GetRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	out	sys_refcursor
);

PROCEDURE GetIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	OUT	sys_refcursor
);

PROCEDURE GetMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	OUT	sys_refcursor
);

PROCEDURE GetFailureMapping(
	in_class_sid			IN	NUMBER,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE,
	in_region_sid			IN	auto_imp_region_map.region_sid%TYPE
);

PROCEDURE UpsertIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE,
	in_ind_sid				IN	auto_imp_indicator_map.ind_sid%TYPE,
	out_val_id				OUT NUMBER
);

PROCEDURE AddIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE,
	in_ind_sid				IN	auto_imp_indicator_map.ind_sid%TYPE
);

PROCEDURE UpsertMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE,
	in_measure_conv_id		IN	auto_imp_unit_map.measure_conversion_id%TYPE,
	out_val_id				OUT NUMBER
);

PROCEDURE AddMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE,
	in_measure_conv_id		IN	auto_imp_unit_map.measure_conversion_id%TYPE
);

PROCEDURE DeleteRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE
);

PROCEDURE DeleteIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE
);

PROCEDURE DeleteMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE
);

PROCEDURE ProcessFailedRow(
	in_val_id					IN	NUMBER
);

PROCEDURE MergeCoreDataRow(
	in_val_id					IN	NUMBER,
	out_new_val_id				OUT	NUMBER
);

PROCEDURE MergeCoreData(
	in_instance_id				NUMBER,
	in_instance_step_id			NUMBER
);

PROCEDURE SetCoreDataImporterSettings(
	in_import_class_sid					IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number						IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_mapping_xml						IN	auto_imp_core_data_settings.mapping_xml%TYPE,
	in_imp_file_type_id					IN	auto_imp_core_data_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator					IN	auto_imp_core_data_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals			IN	auto_imp_core_data_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index			IN	auto_imp_core_data_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing					IN	auto_imp_core_data_settings.all_or_nothing%TYPE,
	in_has_headings						IN	auto_imp_core_data_settings.has_headings%TYPE,
	in_ind_mapping_type_id				IN	auto_imp_core_data_settings.ind_mapping_type_id%TYPE,
	in_region_mapping_type_id			IN	auto_imp_core_data_settings.region_mapping_type_id%TYPE,
	in_unit_mapping_type_id				IN	auto_imp_core_data_settings.unit_mapping_type_id%TYPE,
	in_requires_validation_step			IN	auto_imp_core_data_settings.requires_validation_step%TYPE,
	in_date_format_type_id				IN	auto_imp_core_data_settings.date_format_type_id%TYPE,
	in_first_col_date_format_id			IN	auto_imp_core_data_settings.first_col_date_format_id%TYPE,
	in_second_col_date_format_id		IN	auto_imp_core_data_settings.second_col_date_format_id%TYPE,
	in_date_string_exact_pars_frmt		IN	auto_imp_core_data_settings.date_string_exact_parse_format%TYPE DEFAULT NULL,
	in_zero_indexed_month_indices		IN	auto_imp_core_data_settings.zero_indexed_month_indices%TYPE,
	in_financial_year_start_month		IN	auto_imp_core_data_settings.financial_year_start_month%TYPE,
	in_overlap_action					IN	auto_imp_core_data_settings.overlap_action%TYPE
);

PROCEDURE GetCoreDataImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetMappingTypes(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetDateFormatTypes(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetDateColumnTypes(
	out_cur			OUT	SYS_REFCURSOR
);

-- END CORE DATA IMPORTER

-- ZIP EXTRACT IMPORTER

PROCEDURE SetZipImporterSettings(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_sort_by						IN	csr.auto_imp_zip_settings.sort_by%TYPE,
	in_sort_by_direction			IN	csr.auto_imp_zip_settings.sort_by_direction%TYPE,
	in_remove_filters				IN	NUMBER DEFAULT 0
);

PROCEDURE SetZipFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_zip_filter.is_wildcard%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
);

PROCEDURE SetZipWildcardFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
);

PROCEDURE SetZipRegexFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
);

PROCEDURE GetZipImporterSettings(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_filter_cur					OUT SYS_REFCURSOR
);

-- END ZIP EXTRACT IMPORTER

-- USER IMPORTER

PROCEDURE SetUserImporterSettings(
	in_import_class_sid					IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	in_mapping_xml						IN	auto_imp_user_imp_settings.mapping_xml%TYPE,
	in_imp_file_type_id					IN	auto_imp_user_imp_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator					IN	auto_imp_user_imp_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals			IN	auto_imp_user_imp_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index			IN	auto_imp_user_imp_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing					IN	auto_imp_user_imp_settings.all_or_nothing%TYPE,
	in_has_headings						IN	auto_imp_user_imp_settings.has_headings%TYPE,
	in_concatenator						IN	auto_imp_user_imp_settings.concatenator%TYPE,
	in_active_status_method				IN	auto_imp_user_imp_settings.active_status_method_txt%TYPE,
	in_use_loc_region_as_start_pt		IN	auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE,
	in_group_sids						IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_set_line_mngmnt_frm_mngr_ky		IN	auto_imp_user_imp_settings.set_line_mngmnt_frm_mngr_key%TYPE,
	in_region_mapping_type_id			IN	auto_imp_user_imp_settings.region_mapping_type_id%TYPE,
	in_role_sids						IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_date_string_exact_pars_frmt		IN	auto_imp_user_imp_settings.date_string_exact_parse_format%TYPE DEFAULT NULL	
);

PROCEDURE GetUserImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_settings_cur			OUT	SYS_REFCURSOR,
	out_groups_cur				OUT	SYS_REFCURSOR,
	out_roles_cur				OUT	SYS_REFCURSOR
);

-- END USER IMPORTER

-- START PRODUCT IMPORTER

PROCEDURE GetProductImportSettings(
	in_class_sid				IN	auto_imp_product_settings.automated_import_class_sid%TYPE,
	in_step_number				IN	auto_imp_product_settings.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetProductImportSettings(
	in_import_class_sid				IN	auto_imp_product_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	auto_imp_product_settings.step_number%TYPE,
	in_mapping_xml					IN	auto_imp_product_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN	auto_imp_product_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_product_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_product_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_product_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_product_settings.all_or_nothing%TYPE,
	in_header_row					IN	auto_imp_product_settings.header_row%TYPE,
	in_concatenator					IN	auto_imp_product_settings.concatenator%TYPE,
	in_default_company_sid			IN	auto_imp_product_settings.default_company_sid%TYPE,
	in_company_mapping_type_id		IN	auto_imp_product_settings.company_mapping_type_id%TYPE,
	in_product_mapping_type_id		IN	auto_imp_product_settings.product_mapping_type_id%TYPE,
	in_prod_type_mapping_type_id	IN	auto_imp_product_settings.product_type_mapping_type_id%TYPE,
	in_cms_mapping_xml				IN	auto_imp_product_settings.cms_mapping_xml%TYPE,
	in_tab_sid						IN	auto_imp_product_settings.tab_sid%TYPE
);

PROCEDURE GetCompanySidFromName(
	in_name				IN	chain.company.name%TYPE,
	out_company_sid		OUT	chain.company.company_sid%TYPE
);

PROCEDURE CheckCompanySid(
	in_company_sid		IN	chain.company.company_sid%TYPE,
	out_company_sid		OUT	chain.company.company_sid%TYPE
);

-- END PRODUCT IMPORTER

-- MAIL

PROCEDURE CreateMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_new_sid						OUT	security_pkg.T_SID_ID
);

PROCEDURE SetMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_sid							OUT	security_pkg.T_SID_ID
);

PROCEDURE ClearMailboxClassAssociation(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE
);

PROCEDURE UpdateMailbox(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_clear_filters				IN	NUMBER
);

PROCEDURE AddSenderFilter(
	in_mailbox_sid			IN	mail.mailbox.mailbox_sid%TYPE,
	in_filter_string		IN	csr.auto_imp_mail_sender_filter.filter_string%TYPE,
	in_is_wildcard			IN	csr.auto_imp_mail_sender_filter.is_wildcard%TYPE
);

PROCEDURE AddSubjectFilter(
	in_mailbox_sid			IN	mail.mailbox.mailbox_sid%TYPE,
	in_filter_string		IN	csr.auto_imp_mail_subject_filter.filter_string%TYPE,
	in_is_wildcard			IN	csr.auto_imp_mail_subject_filter.is_wildcard%TYPE
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

PROCEDURE SetAttachmentFilter(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_pos							IN	csr.auto_imp_mail_attach_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_mail_attach_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_mail_attach_filter.is_wildcard%TYPE,
	in_matched_import_class_sid		IN	csr.auto_imp_mail_attach_filter.matched_import_class_sid%TYPE,
	in_required_mimetype			IN	csr.auto_imp_mail_attach_filter.required_mimetype%TYPE,
	in_attachment_validator_plugin	IN	csr.auto_imp_mail_attach_filter.attachment_validator_plugin%TYPE
);

PROCEDURE LogEmail(
	in_mailbox_sid			IN	csr.auto_imp_mail.mailbox_sid%TYPE,
	in_mail_message_uid		IN	csr.auto_imp_mail.mail_message_uid%TYPE,
	in_subject				IN	csr.auto_imp_mail.subject%TYPE,
	in_recieved_dtm			IN	csr.auto_imp_mail.recieved_dtm%TYPE,
	in_sender_address		IN	csr.auto_imp_mail.sender_address%TYPE,
	in_sender_name			IN	csr.auto_imp_mail.sender_name%TYPE,
	in_number_attachments	IN	csr.auto_imp_mail.number_attachments%TYPE
);

PROCEDURE LogEmailMessage(
	in_mailbox_sid			IN	csr.auto_imp_mail.mailbox_sid%TYPE,
	in_mail_message_uid		IN	csr.auto_imp_mail.mail_message_uid%TYPE,
	in_message				IN	csr.auto_imp_mail_msg.message%TYPE
);

PROCEDURE CreateEmailInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_mailbox_sid					IN	auto_imp_mail_file.mailbox_sid%TYPE,
	in_mail_message_uid				IN	mail.message.message_id%TYPE,
	in_file_blob					IN	BLOB,
	in_file_name					IN	auto_imp_mail_file.file_name%TYPE,
	in_made_from_body				IN	auto_imp_mail_file.made_from_body%TYPE,
	out_new_instance_id				OUT	auto_imp_mail_file.automated_import_instance_id%TYPE
);

PROCEDURE GetEmailFile(
	in_instance_id					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllAppMailboxes(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMailboxes(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMailbox(
	in_mailbox_sid				IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_box_cur					OUT	SYS_REFCURSOR,
	out_sender_filters_cur		OUT	SYS_REFCURSOR,
	out_subject_filters_cur		OUT	SYS_REFCURSOR,
	out_attachment_filters_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetMailbox(
	in_app_sid					IN	customer.app_sid%TYPE,
	in_mailbox_sid				IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_box_cur					OUT	SYS_REFCURSOR,
	out_sender_filters_cur		OUT	SYS_REFCURSOR,
	out_subject_filters_cur		OUT	SYS_REFCURSOR,
	out_attachment_filters_cur	OUT	SYS_REFCURSOR
);

PROCEDURE DeactivateMailbox(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE
);

PROCEDURE ReactivateMailbox(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE
);

PROCEDURE GetMailLog(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMailDetails(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE,
	in_mail_message_uid		IN	automated_import_instance.mail_message_uid%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_msg_cur				OUT	SYS_REFCURSOR
);

-- END MAIL

-- MESSAGE BUS

PROCEDURE CreateBusInstanceAndBatchJob(
	in_lookup_key					IN	automated_import_class.lookup_key%TYPE,
	in_file_blob					IN	BLOB,
	in_source_description			IN	automated_import_bus_file.source_description%TYPE,
	out_new_instance_id				OUT	automated_import_bus_file.automated_import_instance_id%TYPE
);

PROCEDURE CreateBusInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_file_blob					IN	BLOB,
	in_source_description			IN	automated_import_bus_file.source_description%TYPE,
	out_new_instance_id				OUT	automated_import_bus_file.automated_import_instance_id%TYPE
);

PROCEDURE GetMessageBusFile(
	in_instance_id					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

-- END MESSAGE BUS

-- AUDIT LOGGING

PROCEDURE AuditValue(
	in_class_sid			NUMBER,
	in_step_number			NUMBER DEFAULT NULL,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				VARCHAR2
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				XMLTYPE
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				XMLTYPE
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				VARCHAR2
);

PROCEDURE AuditMsg(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_msg					VARCHAR2
);

-- END AUDIT LOGGING

END;
/
