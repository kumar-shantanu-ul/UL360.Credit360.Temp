CREATE OR REPLACE PACKAGE  ACTIONS.importer_pkg
IS

PROCEDURE GetMappingMRU(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateMappingMRU(
	in_dummy				IN	NUMBER,
	in_from_headings		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_headings			IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE PrepExportViewAll
;

PROCEDURE PrepExportViewUser
;

PROCEDURE PrepExportViewFilter (
	in_region_sid		security_pkg.T_SID_ID,
	in_project_sids		security_pkg.T_SID_IDS,
	in_status_ids		security_pkg.T_SID_IDS,
	in_progress_ids		security_pkg.T_SID_IDS,
	in_start_dtm		task.start_dtm%TYPE,
	in_end_dtm			task.end_dtm%TYPE
);

PROCEDURE PrepExportViewFilterUser (
	in_region_sid		security_pkg.T_SID_ID,
	in_project_sids		security_pkg.T_SID_IDS,
	in_status_ids		security_pkg.T_SID_IDS,
	in_progress_ids		security_pkg.T_SID_IDS,
	in_start_dtm		task.start_dtm%TYPE,
	in_end_dtm			task.end_dtm%TYPE
);

PROCEDURE GetDataForExport (
	out_data				OUT	security_pkg.T_OUTPUT_CUR,
	out_tasks				OUT security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_csr_task_roles		OUT security_pkg.T_OUTPUT_CUR,
	out_status_history		OUT security_pkg.T_OUTPUT_CUR,
	out_project_team		OUT security_pkg.T_OUTPUT_CUR,
	out_project_sponsor		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplateList(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDefaultTemplate(
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplate(
	in_template_id			IN	import_template.import_template_id%TYPE,
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTemplate(
	in_name					IN	import_template.name%TYPE,
	in_heading_row_idx		IN	import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_template_id			OUT	import_template.import_template_id%TYPE
);

PROCEDURE AmendTemplate(
	in_template_id			IN	import_template.import_template_id%TYPE,
	in_name					IN	import_template.name%TYPE,
	in_heading_row_idx		IN	import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE AmendTemplateData (
	in_template_id			IN	import_template.import_template_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE SetDefaultTemplate (
	in_template_id			IN	import_template.import_template_id%TYPE
);

PROCEDURE DeleteTemplate (
	in_template_id			IN	import_template.import_template_id%TYPE
);

PROCEDURE GetActiveUsers(
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

END importer_pkg;
/

