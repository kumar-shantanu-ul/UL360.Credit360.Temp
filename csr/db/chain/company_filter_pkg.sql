CREATE OR REPLACE PACKAGE chain.company_filter_pkg
IS

-- Chart aggregation types
SUPPLIER_COUNT					CONSTANT NUMBER(10) := 1;

-- Region column types
COL_TYPE_SUPPLIER_REGION		CONSTANT NUMBER(10) := 1;

-- Date column types
-- TODO: Still need to define suitable/useful date types (e.g. activated, created, relationship activated, invitation date, who knows?)
-- For now, don't filter by date

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
);


PROCEDURE Search (
	in_search_term		IN  VARCHAR2,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterCompanySids (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_parallel			IN	NUMBER,
	in_max_group_by		IN  NUMBER,
	in_sids				IN  T_FILTERED_OBJECT_TABLE,
	out_sids			OUT T_FILTERED_OBJECT_TABLE
);

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE CreateCompanySearchFilter (
	in_search_phrase			IN	filter_value.str_value%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CreateQuestionnaireFilter (
	in_questionnaire_type_id	IN	filter_value.num_value%TYPE,
	in_status_id				IN	filter_value.num_value%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);



PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
);


/* Required to be a filter helper_pkg */
PROCEDURE CopyFilter (
	in_from_filter_id			IN	filter.filter_id%TYPE,
	in_to_filter_id				IN	filter.filter_id%TYPE
);

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterResponseIds (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_sids				IN  security.T_SID_TABLE,
	out_sids			OUT security.T_SID_TABLE
);

PROCEDURE ConvertIdsToRegionSids(
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_region_sids					OUT	chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_bounds_north					IN	NUMBER,
	in_bounds_east					IN	NUMBER,
	in_bounds_south					IN	NUMBER,
	in_bounds_west					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_session_prefix				IN	VARCHAR2 DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REfCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetCompanyRegions (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetReportData(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_aggregation_types			IN	security.T_SID_TABLE DEFAULT NULL,
	in_show_totals					IN	NUMBER DEFAULT NULL,
	in_breadcrumb					IN	security.T_SID_TABLE DEFAULT NULL,
	in_max_group_by					IN	NUMBER DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT	SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetCompanyExportUsers(
	in_sids							IN security_pkg.T_SID_IDS,
	out_cur_company_users			OUT	SYS_REFCURSOR,
	out_cur_company_user_roles		OUT	SYS_REFCURSOR
);

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REfCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE FilterCompaniesGraph(
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_search_term  				IN  VARCHAR2,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_bus_rel_type_id				IN  security_pkg.T_SID_ID,
	out_company_sids_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comps_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SortAuditSids (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
);

PROCEDURE SortNonCompIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
);

PROCEDURE SortActivityIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
);

PROCEDURE SortSurveyResponseIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
);

PROCEDURE GetTagGroups (
	out_tag_groups					OUT	SYS_REFCURSOR,
	out_tag_group_members			OUT	SYS_REFCURSOR
);

PROCEDURE GetDirectSuppliers(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetSuppliersAsPrimaryPurchaser(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetSubsidiarySuppliers(
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR,
	out_scores_cur					OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_refs_cur					OUT	SYS_REFCURSOR,
	out_bus_cur						OUT SYS_REFCURSOR,
	out_followers_cur				OUT SYS_REFCURSOR,
	out_certifications_cur			OUT SYS_REFCURSOR,
	out_prim_purchsr_cur			OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetPrchasrWithDirectSuppliers(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPrimaryPurchasers(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPrchasrWithSubsidiaries(
	in_company_sids					IN	security_pkg.T_SID_IDS,
	in_related_company_type_ids		IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	SYS_REFCURSOR
);

END company_filter_pkg;
/