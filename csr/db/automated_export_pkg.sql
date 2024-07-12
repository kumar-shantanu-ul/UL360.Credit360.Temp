CREATE OR REPLACE PACKAGE csr.automated_export_pkg AS

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

PROCEDURE DeleteClass(
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_automated_export_inst_id		OUT	automated_export_instance.automated_export_instance_id%TYPE
);

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_is_preview						IN	automated_export_instance.is_preview%TYPE,
	out_automated_export_inst_id		OUT	automated_export_instance.automated_export_instance_id%TYPE
);

PROCEDURE TriggerInstance(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE CreatePreviewInstance(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetJob(
	in_batch_job_id				IN	automated_export_instance.batch_job_id%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetInstance(
	in_instance_id				IN	automated_export_instance.batch_job_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR,
	out_message_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetInstance(
	in_class_sid				IN	automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetClass(
	in_export_class_sid			IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR,
	out_keys_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetClassCountByLabel(
	in_label					IN	automated_export_class.label%TYPE,
	out_count					OUT NUMBER
);

PROCEDURE GetClasses(
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	in_lookup_key				IN automated_export_class.lookup_key%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetClassInstances(
	in_automated_export_class_sid	IN	security_pkg.T_SID_ID,
	in_start_row					IN	NUMBER,
	in_end_row	  					IN	NUMBER,
	in_include_preview              IN  NUMBER,
	in_include_failure              IN  NUMBER,
	out_cur		 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMostRecentInstances(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDbWriterSettings(
	in_automated_export_class_sid	IN	automated_export_instance.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDsvSettings(
	in_auto_export_instance_id			IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE GetDsvSettingsByClass(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE UpdateDsvSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_delimiter_id						IN	auto_exp_filecreate_dsv.delimiter_id%TYPE,
	in_secondary_delimiter_id			IN	auto_exp_filecreate_dsv.secondary_delimiter_id%TYPE,
	in_encoding_name					IN	auto_exp_filecreate_dsv.encoding_name%TYPE DEFAULT NULL,
	in_encode_newline					IN	auto_exp_filecreate_dsv.encode_newline%TYPE DEFAULT 0
);

PROCEDURE GetFtpSettings(
	in_auto_export_instance_id			IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE GetFtpClassSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE GetDataViewExporterSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE UpdateDataViewExporterSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid						IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values				IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml						IN	VARCHAR2,
	in_region_selection_type_id			IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id							IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id			IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
);

FUNCTION CreateStoredProcSettingsFn(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure				IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs	IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
) RETURN NUMBER;

PROCEDURE CreateStoredProcSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure				IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs	IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
);

PROCEDURE GetStoredProcExpSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
);

PROCEDURE UpdateStoredProcExpSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure					IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs		IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
);

PROCEDURE AppendToInstancePayload(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	in_payload_chunk			IN	BLOB,
	in_payload_filename			IN	automated_export_instance.payload_filename%TYPE
);

PROCEDURE ResetInstancePayload(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	in_payload_filename			IN	automated_export_instance.payload_filename%TYPE
);

PROCEDURE GetPayloadFile(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
);

PROCEDURE GetFileRequestCount(
	in_class_sid			IN automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id			IN automated_export_instance.automated_export_instance_id%TYPE,
	out_count				OUT NUMBER
);

PROCEDURE IncrementFileRequestCount(
	in_class_sid			IN	automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id			IN automated_export_instance.automated_export_instance_id%TYPE
);

PROCEDURE GetClassName(
	in_class_sid			IN	automated_export_class.automated_export_class_sid%TYPE,
	out_label				OUT	automated_export_class.label%TYPE
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
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
);

PROCEDURE GetSessionLogFile(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
);

PROCEDURE ScheduleRun;

PROCEDURE CheckForNewJobs;

PROCEDURE ClearupInstancePayloads;


PROCEDURE CreateClass(
	in_parent					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_label					IN	automated_export_class.label%TYPE,
	in_schedule_xml				IN	automated_export_class.schedule_xml%TYPE,
	in_file_mask				IN	automated_export_class.file_mask%TYPE,
	in_file_mask_date_format	IN	automated_export_class.file_mask_date_format%TYPE,
	in_email_on_error			IN	automated_export_class.email_on_error%TYPE,
	in_email_on_success			IN	automated_export_class.email_on_success%TYPE,
	in_exporter_plugin_id		IN	automated_export_class.exporter_plugin_id%TYPE,
	in_file_writer_plugin_id	IN	automated_export_class.file_writer_plugin_id%TYPE,
	in_include_headings			IN	automated_export_class.include_headings%TYPE,
	in_output_empty_as			IN	automated_export_class.output_empty_as%TYPE,
	in_lookup_key				IN	automated_export_class.lookup_key%TYPE,
	out_class_sid				OUT	automated_export_class.automated_export_class_sid%TYPE
);

FUNCTION CreateDataviewSettingsFn(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid					IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values			IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml					IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id		IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id						IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id		IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
) RETURN NUMBER;

PROCEDURE CreateDataviewSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid					IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values			IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml					IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id		IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id						IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id		IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
);

PROCEDURE CreateDataviewExporterClass(
	in_label					IN	automated_export_class.label%TYPE,
	in_schedule_xml				IN	automated_export_class.schedule_xml%TYPE,
	in_file_mask				IN	automated_export_class.file_mask%TYPE,
	in_file_mask_date_format	IN	automated_export_class.file_mask_date_format%TYPE,
	in_email_on_error			IN	automated_export_class.email_on_error%TYPE,
	in_email_on_success			IN	automated_export_class.email_on_success%TYPE,
	in_exporter_plugin_id		IN	automated_export_class.exporter_plugin_id%TYPE,
	in_file_writer_plugin_id	IN	automated_export_class.file_writer_plugin_id%TYPE,
	in_include_headings			IN	automated_export_class.include_headings%TYPE,
	in_output_empty_as			IN	automated_export_class.output_empty_as%TYPE,
	in_dataview_sid				IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values		IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml				IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id	IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id					IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id	IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE,
	out_class_sid				OUT	automated_export_class.automated_export_class_sid%TYPE
);

PROCEDURE SetFtpFileWriterOnClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_ftp_profile_id			IN	auto_exp_filewrite_ftp.ftp_profile_id%TYPE,
	in_output_path				IN	auto_exp_filewrite_ftp.output_path%TYPE
);

PROCEDURE SetDsvFileCreateOnClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_delimiter_id				IN	auto_exp_filecreate_dsv.delimiter_id%TYPE,
	in_secondary_delimiter_id	IN	auto_exp_filecreate_dsv.secondary_delimiter_id%TYPE,
	in_encoding_name			IN	auto_exp_filecreate_dsv.encoding_name%TYPE DEFAULT NULL,
	in_encode_newline			IN	auto_exp_filecreate_dsv.encode_newline%TYPE DEFAULT 0
);

PROCEDURE UpdateExportClass(
	in_automated_export_class_sid   IN automated_export_class.automated_export_class_sid%TYPE,
	in_label						IN automated_export_class.label%TYPE,
	in_contains_pii					IN automated_export_class.contains_pii%TYPE,
	in_file_mask					IN automated_export_class.file_mask%TYPE,
	in_schedule_xml					IN VARCHAR2,
	in_last_scheduled_dtm			IN automated_export_class.last_scheduled_dtm%TYPE,
	in_email_on_error				IN automated_export_class.email_on_error%TYPE,
	in_email_on_success				IN automated_export_class.email_on_success%TYPE,
	in_include_headings				IN automated_export_class.include_headings%TYPE,
	in_output_empty_as				IN automated_export_class.output_empty_as%TYPE,
	in_file_mask_date_format		IN automated_export_class.file_mask_date_format%TYPE,
	in_days_to_retain_payload		IN automated_export_class.days_to_retain_payload%TYPE,
	in_enable_encryption			IN automated_export_class.enable_encryption%TYPE,
	in_public_key_id				IN automated_export_class.auto_impexp_public_key_id%TYPE,
	in_lookup_key					IN automated_export_class.lookup_key%TYPE
);

PROCEDURE GetFtpFileWriterSettings(
	out_cur						 	OUT SYS_REFCURSOR
);

PROCEDURE UpdateDbFileWriterSettings(
	in_sid								IN automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure					IN auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs		IN auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
);

PROCEDURE UpdateFtpWriterClassSettings(
	in_auto_exp_filewrite_ftp_id	IN auto_exp_filewrite_ftp.auto_exp_filewrite_ftp_id%TYPE,
	in_output_path				  	IN auto_exp_filewrite_ftp.output_path%TYPE
);

PROCEDURE UpdateFtpFileWriterSettings(
	in_class_sid			IN automated_export_class.automated_export_class_sid%TYPE,
	in_ftp_profile_id		IN auto_exp_filewrite_ftp.ftp_profile_id%TYPE,
	in_output_path			IN auto_exp_filewrite_ftp.output_path%TYPE
);

PROCEDURE GetQuickChartExporterSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateQuickChartExporterSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_saved_filter_sid				IN	auto_exp_class_qc_settings.saved_filter_sid%TYPE,
	in_encoding_name				IN	auto_exp_class_qc_settings.encoding_name%TYPE
);

PROCEDURE GetInUseQuickChartFilterSids(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetExternalTargetSettings(
	in_auto_export_instance_id		IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetExternalTargetClassSettings(
	in_class_sid					IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateExternalTargetClassSettings(
	in_class_sid					IN automated_export_class.automated_export_class_sid%TYPE,
	in_target_profile_id			IN external_target_profile.target_profile_id%TYPE
);

-- AUDIT LOGGING

PROCEDURE AuditValue(
	in_class_sid			NUMBER,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				VARCHAR2
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				XMLTYPE
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				XMLTYPE
);

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				VARCHAR2
);

PROCEDURE AuditMsg(
	in_class_sid			NUMBER,
	in_msg					VARCHAR2
);

-- END AUDIT LOGGING

PROCEDURE SetBatchedExporterSettings(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_batched_export_type_id	IN	auto_exp_batched_exp_settings.batched_export_type_id%TYPE,
	in_settings_xml				IN	auto_exp_batched_exp_settings.settings_xml%TYPE,
	in_convert_to_dsv			IN	auto_exp_batched_exp_settings.convert_to_dsv%TYPE,
	in_primary_delimiter		IN	auto_exp_batched_exp_settings.primary_delimiter%TYPE,
	in_secondary_delimiter		IN	auto_exp_batched_exp_settings.secondary_delimiter%TYPE,
	in_include_first_row		IN	auto_exp_batched_exp_settings.include_first_row%TYPE
);

PROCEDURE GetExporters(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFileWriters(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetBatchedExporters(
	out_cur			OUT SYS_REFCURSOR
);

FUNCTION GetPayloadRetention(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE
)
RETURN automated_export_class.days_to_retain_payload%TYPE;

END;
/
