CREATE OR REPLACE PACKAGE CSR.templated_report_pkg AS

TPL_RPT_TAG_TYPE_UNMAPPED			CONSTANT NUMBER(10) := -1;
TPL_RPT_TAG_TYPE_IND				CONSTANT NUMBER(10) := 1;
TPL_RPT_TAG_TYPE_TABLE				CONSTANT NUMBER(10) := 2;
TPL_RPT_TAG_TYPE_CHART				CONSTANT NUMBER(10) := 3;
TPL_RPT_TAG_TYPE_IND_COMMENT		CONSTANT NUMBER(10) := 4;
TPL_RPT_TAG_TYPE_IND_NOTE			CONSTANT NUMBER(10) := 5;
TPL_RPT_TAG_TYPE_IND_COND			CONSTANT NUMBER(10) := 6;
TPL_RPT_TAG_TYPE_LGN_FRM			CONSTANT NUMBER(10) := 7;
TPL_RPT_TAG_TYPE_CUSTOM				CONSTANT NUMBER(10) := 8;
TPL_RPT_TAG_TYPE_TEXT				CONSTANT NUMBER(10) := 9;
TPL_RPT_TAG_TYPE_NON_COMPL			CONSTANT NUMBER(10) := 10;
TPL_RPT_TAG_TYPE_REGION_DATA		CONSTANT NUMBER(10) := 11;
-- Approval dashboard tags - don't follow sequence as they cannot be manually mapped
TPL_RPT_TAG_TYPE_APP_CHART			CONSTANT NUMBER(10) := 101;
TPL_RPT_TAG_TYPE_APP_NOTE			CONSTANT NUMBER(10) := 102;
TPL_RPT_TAG_TYPE_APP_MATRIX			CONSTANT NUMBER(10) := 103;

-- I don't think these are actually used (basedata.sql populates CSR.TPL_REGION_TYPE with numbers):
TPL_REGION_TYPE_SELECTED			CONSTANT NUMBER(10) := 1;
TPL_REGION_TYPE_PARENT 				CONSTANT NUMBER(10) := 2;
TPL_REGION_TYPE_TOP					CONSTANT NUMBER(10) := 3;
TPL_REGION_TYPE_ONE_FROM_TOP		CONSTANT NUMBER(10) := 4;
TPL_REGION_TYPE_TWO_FROM_TOP 		CONSTANT NUMBER(10) := 5;
TPL_REGION_TYPE_ARBITRARY			CONSTANT NUMBER(10) := 6;
TPL_REGION_TYPE_IMMDIAT_CHILD		CONSTANT NUMBER(10) := 7;
TPL_REGION_TYPE_SEL_CHILD			CONSTANT NUMBER(10) := 8;
TPL_REGION_TYPE_SEL_CHILD_PAR		CONSTANT NUMBER(10) := 9;
TPL_REGION_TYPE_LOW_LVL_PROP		CONSTANT NUMBER(10) := 10;
TPL_REGION_TYPE_TWO_DOWN			CONSTANT NUMBER(10) := 11;
TPL_REGION_TYPE_ALL_SELECTED		CONSTANT NUMBER(10) := 12;
TPL_REGION_TYPE_BOTTOM				CONSTANT NUMBER(10) := 13;
TPL_REGION_TYPE_ONE_FROM_BTM		CONSTANT NUMBER(10) := 14;

-- Securable object callbacks
/**
 * CreateObject
 *
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 *
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 *
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);


PROCEDURE SetTemplateFromCache(
	in_cache_key					IN	aspen2.filecache.cache_key%type,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE SetTemplateFromCache(
	in_cache_key					IN	aspen2.filecache.cache_key%type,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE SetTemplate(
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE,
	in_parent_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_word_doc						IN	tpl_report.word_doc%TYPE,
	in_filename						IN	aspen2.filecache.filename%TYPE,
	out_templated_report_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE CopyTemplate(
	in_from_tpl_report_sid			IN	security_pkg.T_SID_ID,
	in_tpl_folder_sid				IN	security_pkg.T_SID_ID,
	in_new_name						IN	tpl_report.name%TYPE,
	out_to_tpl_report_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE UpdateTemplate(
	in_tpl_report_sid				IN 	security_pkg.T_SID_ID,
	in_name							IN	tpl_report.name%TYPE,
	in_description					IN	tpl_report.description%TYPE,
	in_period_set_id				IN	tpl_report.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report.period_interval_id%TYPE
);

PROCEDURE SaveTemplateThumb(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_data							IN tpl_report.thumb_img%TYPE
);

PROCEDURE ChangeTemplate(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_cache_key					IN	aspen2.filecache.cache_key%type
);

PROCEDURE GetImgKeys(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_GetImgKeys(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetTemplate(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	tpl_cur							OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_GetTemplate(
	in_tpl_report_sid	IN security_pkg.T_SID_ID,
	tpl_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetThumbnail(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	tpl_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetTemplateList(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetChildReports(
	in_parent_sid					IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTags(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_unmapped_cur			OUT SYS_REFCURSOR,
	out_ind_cur					OUT SYS_REFCURSOR,
	out_dataview_cur			OUT SYS_REFCURSOR,
	out_cond_cur				OUT SYS_REFCURSOR,
	out_logng_form_cur			OUT SYS_REFCURSOR,
	out_custom_cur				OUT SYS_REFCURSOR,
	out_text_cur				OUT SYS_REFCURSOR,
	out_non_compl_cur			OUT SYS_REFCURSOR,
	out_app_note_cur			OUT SYS_REFCURSOR,
	out_app_matrix_cur			OUT SYS_REFCURSOR,
	out_region_data_cur			OUT SYS_REFCURSOR,
	out_quick_chart_data_cur	OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_GetTags(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_unmapped_cur			OUT SYS_REFCURSOR,
	out_ind_cur					OUT SYS_REFCURSOR,
	out_dataview_cur			OUT SYS_REFCURSOR,
	out_cond_cur				OUT SYS_REFCURSOR,
	out_logng_form_cur			OUT SYS_REFCURSOR,
	out_custom_cur				OUT SYS_REFCURSOR,
	out_text_cur				OUT SYS_REFCURSOR,
	out_non_compl_cur			OUT SYS_REFCURSOR,
	out_app_note_cur			OUT SYS_REFCURSOR,
	out_app_matrix_cur			OUT SYS_REFCURSOR,
	out_region_data_cur			OUT SYS_REFCURSOR,
	out_quick_chart_data_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetTagNames(
	in_tpl_report_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetTagUnmapped(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE
);

PROCEDURE SetTagInd(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_ind.month_offset%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_measure_conversion_id		IN	tpl_report_tag_ind.measure_conversion_id%TYPE,
	in_format_mask					IN	tpl_report_tag_ind.format_mask%TYPE,
	in_show_full_path				IN	tpl_report_tag_ind.show_full_path%TYPE,
	out_tpl_report_tag_ind_id		OUT	tpl_report_tag_ind.tpl_report_tag_ind_id%TYPE
);

PROCEDURE SetTagEval(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_all_must_be_true	 			IN	tpl_report_tag_eval.all_must_be_true%TYPE,
	in_if_true						IN	tpl_report_tag_eval.if_true%TYPE,
	in_if_false						IN	tpl_report_tag_eval.if_false%TYPE,
	in_month_offset					IN	tpl_report_tag_eval.month_offset%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	out_tpl_report_tag_eval_id		OUT	tpl_report_tag_eval.tpl_report_tag_eval_id%TYPE
);

PROCEDURE SetTagDataview(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_dataview.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_dataview.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_hide_if_empty				IN	tpl_report_tag_dataview.hide_if_empty%TYPE,
	in_split_table_by_columns		IN	tpl_report_tag_dataview.split_table_by_columns%TYPE,
	in_filter_result_mode			IN	tpl_report_tag_dataview.filter_result_mode%TYPE,
	in_aggregate_type_id			IN	tpl_report_tag_dataview.aggregate_type_id%TYPE,
	in_approval_dashboard_sid		IN  tpl_report_tag_dataview.approval_dashboard_sid%TYPE			DEFAULT NULL,
	in_ind_tag						IN  tpl_report_tag_dataview.ind_tag%TYPE						DEFAULT NULL,
	out_tpl_report_tag_dataview_id	OUT	tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE
);

PROCEDURE SetTagLoggingForm(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tab_sid						IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_logging_form.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_logging_form.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_region_column_name			IN	tpl_report_tag_logging_form.region_column_name%TYPE,
	in_tpl_region_type_id			IN	tpl_report_tag_logging_form.tpl_region_type_id%TYPE,
	in_date_column_name				IN	tpl_report_tag_logging_form.date_column_name%TYPE,
	in_view_sid						IN	security_pkg.T_SID_ID,
	out_tpl_report_tag_lgng_frm_id	OUT	tpl_report_tag_logging_form.tpl_report_tag_logging_form_id%TYPE
);

PROCEDURE SetTagNonCompliance(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_month_offset					IN	tpl_report_non_compl.month_offset%TYPE,
	in_month_duration				IN	tpl_report_non_compl.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_tpl_region_type_id			IN	tpl_report_non_compl.tpl_region_type_id%TYPE,
	in_tag_id						IN	tpl_report_non_compl.tag_id%TYPE,
	out_tpl_report_non_cmpl_id		OUT	tpl_report_non_compl.tpl_report_non_compl_id%TYPE
);

PROCEDURE SetTagCustom(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_custom_tag_type_id			IN	tpl_report_tag.tpl_rep_cust_tag_type_id%TYPE
);

PROCEDURE SetTagCustom(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_custom_tag_cs_class			IN	tpl_rep_cust_tag_type.cs_class%TYPE
);

PROCEDURE SetTagText(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_label						IN	tpl_report_tag_text.label%TYPE,
	out_tpl_report_tag_text_id		OUT	tpl_report_tag_text.tpl_report_tag_text_id%TYPE
);

PROCEDURE SetTagApprovalNote(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tab_portlet_id				IN  tpl_report_tag_approval_note.tab_portlet_id%TYPE,
	in_approval_dashboard_sid		IN	tpl_report_tag_approval_note.approval_dashboard_sid%TYPE,
	out_tpl_report_tag_app_note_id	OUT	tpl_report_tag_approval_note.tpl_report_tag_app_note_id%TYPE
);

PROCEDURE SetTagApprovalMatrix(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_approval_dashboard_sid		IN	tpl_report_tag_approval_matrix.approval_dashboard_sid%TYPE,
	out_tpl_rep_tag_app_mtx_id		OUT	tpl_report_tag_approval_matrix.tpl_report_tag_app_matrix_id%TYPE
);

PROCEDURE SetTagRegionData(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_tpl_report_reg_data_type_id	IN	tpl_report_reg_data_type.tpl_report_reg_data_type_id%TYPE,
	out_tpl_report_tag_reg_data_id OUT	tpl_report_tag_reg_data.tpl_report_tag_reg_data_id%TYPE
);

PROCEDURE SetTagQuickChart(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tpl_report_tag.tag%TYPE,
	in_tag_type						IN	tpl_report_tag.tag_type%TYPE,
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_month_offset					IN	tpl_report_tag_qchart.month_offset%TYPE,
	in_month_duration				IN	tpl_report_tag_qchart.month_duration%TYPE,
	in_period_set_id				IN	tpl_report_tag_ind.period_set_id%TYPE,
	in_period_interval_id			IN	tpl_report_tag_ind.period_interval_id%TYPE,
	in_hide_if_empty				IN	tpl_report_tag_qchart.hide_if_empty%TYPE,
	in_split_table_by_columns		IN	tpl_report_tag_qchart.split_table_by_columns%TYPE,
	out_tpl_report_tag_qc_id		OUT	tpl_report_tag_qchart.tpl_report_tag_qchart_id%TYPE
);

PROCEDURE UNSEC_InsertTagRegion(
	in_tpl_report_tag_dataview_id	IN tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE,
	in_dataview_sid					IN security_pkg.T_SID_ID,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_tpl_region_type_id			IN tpl_report_tag_dv_region.tpl_region_type_id%TYPE,
	in_filter_by_tag				IN tpl_report_tag_dv_region.filter_by_tag%TYPE
);

PROCEDURE UNSEC_InsertTagCondition(
	in_tpl_report_tag_eval_id		IN tpl_report_tag_eval.tpl_report_tag_eval_id%TYPE,
	in_left_ind_sid					IN security_pkg.T_SID_ID,
	in_operator						IN tpl_report_tag_eval_cond.operator%TYPE,
	in_right_ind_sid				IN security_pkg.T_SID_ID,
	in_right_value					IN tpl_report_tag_eval_cond.right_value%TYPE
);

PROCEDURE GetRegionParent(
	in_region_sid					IN	region.region_sid%TYPE,
	out_parent_sid					OUT	region.parent_sid%TYPE
);

PROCEDURE GetRegionFromTop(
	in_region_sid					IN	region.region_sid%TYPE,
	in_depth						IN	NUMBER,
	out_region_sid					OUT	region.region_sid%TYPE
);

PROCEDURE GetChildrenAtLevel(
	in_region_sid					IN	region.region_sid%TYPE,
	in_level						IN	NUMBER,
	in_include_inactive				IN	NUMBER,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetCustomerTagTypes (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTemplateImages(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE DeleteTemplateImage(
	in_key							IN	tpl_img.key%TYPE
);

PROCEDURE SaveTemplateImage(
	in_old_key						IN	tpl_img.key%TYPE,
	in_key							IN	tpl_img.key%TYPE,
	in_path							IN	score_threshold.description%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE ChangeTemplateImage(
	in_key							IN	tpl_img.key%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%type
);

PROCEDURE GetTemplateImage(
	in_key							IN	tpl_img.key%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderPath(
	in_folder_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

-- Batch job procedures
PROCEDURE SetBatchJob(
	in_settings_xml		IN	CLOB,
	in_user_sid			IN	batch_job_templated_report.user_sid%TYPE,
	in_schedule_sid		IN	batch_job_templated_report.schedule_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSettingsFromBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateBatchJob(
	in_batch_job_id		IN NUMBER,
	in_report_data		IN batch_job_templated_report.report_data%TYPE
);

PROCEDURE GetBatchJobReportData(
	in_batch_job_id		IN	batch_job_templated_report.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CanDownloadReport(
	in_batch_job_id			IN	batch_job_templated_report.batch_job_id%TYPE,
	out_result				OUT NUMBER
);

FUNCTION CanDownloadReport(
	in_batch_job_id			IN	batch_job_templated_report.batch_job_id%TYPE
) RETURN BOOLEAN;

PROCEDURE ScheduledBatchJobDataTidy(
	in_blank			IN NUMBER DEFAULT NULL
);

PROCEDURE ReRunBatchJob(
	in_batch_job_id		IN	batch_job_templated_report.batch_job_id%TYPE,
	in_user_sid			IN	batch_job_templated_report.user_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetTemplateJobs(
	in_template_sid			IN TPL_REPORT.tpl_report_sid%TYPE,
	in_start_row			IN NUMBER,
	in_end_row				IN NUMBER,
	in_order_by				IN VARCHAR2,
	in_order_dir			IN VARCHAR2,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE CheckCanReadRegions(
	in_regions				IN	security_pkg.T_SID_IDS,
	out_result				OUT NUMBER
);

PROCEDURE GetPortletDetails(
	in_tab_portlet_id			IN	TAB_PORTLET.tab_portlet_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetRegionDataTypes(
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE CheckForInactiveRegions(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	out_invalid_count	OUT NUMBER
);

PROCEDURE GetTemplateVariants(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR
);

PROCEDURE GetTemplateVariant(
	in_tpl_report_sid				IN security_pkg.T_SID_ID,
	in_language_code				IN tpl_report_variant.language_code%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveTemplateVariant(
	in_master_template_sid			IN	tpl_report_variant.master_template_sid%TYPE,
	in_language_code				IN	tpl_report_variant.language_code%TYPE,
	in_filename						IN	tpl_report_variant.filename%TYPE,
	in_cache_key					IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE DeleteTemplateVariant(
	in_master_template_sid			IN security_pkg.T_SID_ID,
	in_language_code				IN tpl_report_variant.language_code%TYPE
);

PROCEDURE DeleteLangVariantTags(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_language_code				IN	tpl_report_variant.language_code%TYPE
);

PROCEDURE SetLangVariantTag(
	in_tpl_report_sid				IN	security_pkg.T_SID_ID,
	in_language_code				IN	tpl_report_variant.language_code%TYPE,
	in_tag							IN	tpl_report_tag.tag%TYPE
);

FUNCTION GetParentLanguage(
	in_lang					IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE;

PROCEDURE GetDescendantReports(
	in_root_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

END;
/
