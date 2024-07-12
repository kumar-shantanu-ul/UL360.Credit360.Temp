CREATE OR REPLACE PACKAGE CSR.initiative_import_pkg
IS

PROCEDURE GetMappingMRU(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateMappingMRU(
	in_dummy			IN	NUMBER,
	in_from_headings	IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_headings		IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE GetTemplateList(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDefaultTemplate(
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplate(
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTemplate(
	in_name					IN	initiative_import_template.name%TYPE,
	in_heading_row_idx		IN	initiative_import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	initiative_import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	initiative_import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_template_id			OUT	initiative_import_template.import_template_id%TYPE
);

PROCEDURE AmendTemplate(
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	in_name					IN	initiative_import_template.name%TYPE,
	in_heading_row_idx		IN	initiative_import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	initiative_import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	initiative_import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE AmendTemplateData (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE SetDefaultTemplate (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE
);

PROCEDURE DeleteTemplate (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE
);

PROCEDURE GetActiveUsers(
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RegionSidsFromRefs (
	in_dummy		IN	NUMBER,
	in_refs			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RegionSidsFromNames (
	in_dummy		IN	NUMBER,
	in_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END initiative_import_pkg;
/