CREATE OR REPLACE PACKAGE chain.filter_pkg
IS

-- Filter types
FILTER_TYPE_COMPANIES			CONSTANT NUMBER(10) := 23;
FILTER_TYPE_SURVEY_RESPONSES	CONSTANT NUMBER(10) := 24;
FILTER_TYPE_ISSUES				CONSTANT NUMBER(10) := 25;
FILTER_TYPE_AUDITS				CONSTANT NUMBER(10) := 41;
FILTER_TYPE_NON_COMPLIANCES		CONSTANT NUMBER(10) := 42;
FILTER_TYPE_CMS					CONSTANT NUMBER(10) := 43;
FILTER_TYPE_PROPERTY			CONSTANT NUMBER(10) := 44;
FILTER_TYPE_INITIATIVES			CONSTANT NUMBER(10) := 45;
FILTER_TYPE_METER_DATA			CONSTANT NUMBER(10) := 46;
FILTER_TYPE_CSR_USER			CONSTANT NUMBER(10) := 47;
FILTER_TYPE_COMPLIANCE_LIB		CONSTANT NUMBER(10) := 48;
FILTER_TYPE_COMPLIANCE_REG		CONSTANT NUMBER(10) := 49;

FILTER_TYPE_METERS				CONSTANT NUMBER(10) := 50;
FILTER_TYPE_REGIONS				CONSTANT NUMBER(10) := 51;
FILTER_TYPE_ACTIVITIES			CONSTANT NUMBER(10) := 52;
FILTER_TYPE_BUS_RELS			CONSTANT NUMBER(10) := 53;
FILTER_TYPE_QS_RESPONSE			CONSTANT NUMBER(10) := 54;
FILTER_TYPE_CERTS				CONSTANT NUMBER(10) := 55;
FILTER_TYPE_PRODUCT				CONSTANT NUMBER(10) := 56;

FILTER_TYPE_DEDUPE_PROC_RECS	CONSTANT NUMBER(10) := 57;

FILTER_TYPE_PERMITS				CONSTANT NUMBER(10) := 58;
FILTER_TYPE_QUESTION_LIBRARY	CONSTANT NUMBER(10) := 59;
FILTER_TYPE_PROD_SUPPLIER		CONSTANT NUMBER(10) := 60;

FILTER_TYPE_COMPANY_REQUEST		CONSTANT NUMBER(10) := 61;

FILTER_TYPE_PRODUCT_METRIC_VAL	CONSTANT NUMBER(10) := 62;
FILTER_TYPE_PRD_SUPP_MTRC_VAL	CONSTANT NUMBER(10) := 63;

FILTER_TYPE_BSCI_SUPPLIERS		CONSTANT NUMBER(10) := 64;
FILTER_TYPE_BSCI_2009_AUDITS	CONSTANT NUMBER(10) := 65;
FILTER_TYPE_BSCI_2014_AUDITS	CONSTANT NUMBER(10) := 66;
FILTER_TYPE_BSCI_EXT_AUDITS		CONSTANT NUMBER(10) := 67;

FILTER_TYPE_INTEGRATION_QUESTION_ANSWER		CONSTANT NUMBER(10) := 68;
FILTER_TYPE_SHEET				CONSTANT NUMBER(10) := 69;

-- Column types
COLUMN_TYPE_REGION				CONSTANT NUMBER(10) := 1;
COLUMN_TYPE_DATE				CONSTANT NUMBER(10) := 2;

DEFAULT_AGG_TYPE				CONSTANT NUMBER(10) := 1;
MAX_FILTER_VALUES				CONSTANT NUMBER(10) := 500;

-- Date range options
DATE_SPECIFY_DATES				CONSTANT NUMBER(10) := -1;
DATE_TODAY						CONSTANT NUMBER(10) := -2;
DATE_IN_THE_LAST_WEEK			CONSTANT NUMBER(10) := -3;
DATE_IN_THE_LAST_MONTH			CONSTANT NUMBER(10) := -4;
DATE_IN_THE_LAST_THREE_MONTHS	CONSTANT NUMBER(10) := -5;
DATE_IN_THE_LAST_SIX_MONTHS		CONSTANT NUMBER(10) := -6;
DATE_IN_THE_LAST_YEAR			CONSTANT NUMBER(10) := -7;
DATE_IN_THE_PAST				CONSTANT NUMBER(10) := -8;
DATE_IN_THE_FUTURE				CONSTANT NUMBER(10) := -9;
DATE_IN_THE_NEXT_WEEK			CONSTANT NUMBER(10) := -10;
DATE_IN_THE_NEXT_MONTH			CONSTANT NUMBER(10) := -11;
DATE_IN_THE_NEXT_THREE_MONTHS	CONSTANT NUMBER(10) := -12;
DATE_IN_THE_NEXT_SIX_MONTHS		CONSTANT NUMBER(10) := -13;
DATE_IN_THE_NEXT_YEAR			CONSTANT NUMBER(10) := -14;
DATE_YEAR_TO_DATE				CONSTANT NUMBER(10) := -15;
DATE_YEAR_TO_DATE_PREV_YEAR 	CONSTANT NUMBER(10) := -16;
DATE_IS_NULL					CONSTANT NUMBER(10) := -17;
DATE_NOT_NULL					CONSTANT NUMBER(10) := -18;

-- Number range options
NUMBER_LESS_THAN				CONSTANT NUMBER(10) := 100;
NUMBER_LESS_THAN_OR_EQUAL		CONSTANT NUMBER(10) := 101;
NUMBER_EQUAL					CONSTANT NUMBER(10) := 102;
NUMBER_BETWEEN					CONSTANT NUMBER(10) := 103;
NUMBER_GREATER_THAN_OR_EQUAL	CONSTANT NUMBER(10) := 104;
NUMBER_GREATER_THAN				CONSTANT NUMBER(10) := 105;
NUMBER_NOT_EQUAL				CONSTANT NUMBER(10) := 106;
NUMBER_IS_NULL					CONSTANT NUMBER(10) := 107;
NUMBER_NOT_NULL					CONSTANT NUMBER(10) := 108;

-- User pseudo options
USER_ME							CONSTANT NUMBER(10) := -1;
USER_MY_ROLES					CONSTANT NUMBER(10) := -2;
USER_MY_STAFF					CONSTANT NUMBER(10) := -3;

-- Analytic functions
AFUNC_COUNT						CONSTANT NUMBER(10) := 1;
AFUNC_SUM						CONSTANT NUMBER(10) := 2;
AFUNC_AVERAGE					CONSTANT NUMBER(10) := 3;
AFUNC_MIN						CONSTANT NUMBER(10) := 4;
AFUNC_MAX						CONSTANT NUMBER(10) := 5;
--AFUNC_MEDIAN					CONSTANT NUMBER(10) := 6; -- removed because it causes ORA-22905: cannot access rows from a non-nested table item
AFUNC_STD_DEV					CONSTANT NUMBER(10) := 7;
--AFUNC_COUNT_DISTINCT			CONSTANT NUMBER(10) := 8; -- removed because it causes ORA-22905: cannot access rows from a non-nested table item
AFUNC_OTHER						CONSTANT NUMBER(10) := 9;

-- Filter value types
FILTER_VALUE_TYPE_NUMBER		CONSTANT NUMBER(10) := 1;
FILTER_VALUE_TYPE_NUMBER_RANGE	CONSTANT NUMBER(10) := 2;
FILTER_VALUE_TYPE_STRING		CONSTANT NUMBER(10) := 3;
FILTER_VALUE_TYPE_USER			CONSTANT NUMBER(10) := 4;
FILTER_VALUE_TYPE_REGION		CONSTANT NUMBER(10) := 5;
FILTER_VALUE_TYPE_DATE_RANGE	CONSTANT NUMBER(10) := 6;
FILTER_VALUE_TYPE_SAVED			CONSTANT NUMBER(10) := 7;
FILTER_VALUE_TYPE_COMPOUND		CONSTANT NUMBER(10) := 8;

-- Null filter options
NULL_FILTER_ALL					CONSTANT NUMBER(10) := 0;
NULL_FILTER_REQUIRE_NULL		CONSTANT NUMBER(10) := 1;
NULL_FILTER_EXCLUDE_NULL		CONSTANT NUMBER(10) := 2;

-- Comparators
COMPARATOR_CONTAINS				CONSTANT VARCHAR2(16) := 'contains';
COMPARATOR_EQUALS				CONSTANT VARCHAR2(16) := 'equals';
COMPARATOR_SEARCH				CONSTANT VARCHAR2(16) := 'search';
COMPARATOR_IS_CHILD_OF			CONSTANT VARCHAR2(16) := 'is_child_of';
COMPARATOR_EXCLUDE				CONSTANT VARCHAR2(16) := 'exclude_set';
COMPARATOR_INTERSECT			CONSTANT VARCHAR2(16) := 'intersect_set';

-- SO PROCS
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
);

-- Session callbacks
PROCEDURE OnSessionMigrated (
	in_old_act_id					IN security_pkg.T_ACT_ID,
	in_new_act_id					IN security_pkg.T_ACT_ID
);

PROCEDURE OnSessionDeleted (
	in_old_act_id					IN security_pkg.T_ACT_ID
);

-- Cleaning up filters
PROCEDURE DeleteFiltersForTabSid (
	in_act 						IN	security_pkg.T_ACT_ID,
	in_tab_sid 					IN	security_pkg.T_SID_ID
);

-- Logging
FUNCTION StartDebugLog(
	in_label						IN  debug_log.label%TYPE,
	in_object_id					IN  debug_log.object_id%TYPE DEFAULT NULL
) RETURN NUMBER;

PROCEDURE EndDebugLog(
	in_debug_log_id					IN  debug_log.debug_log_id%TYPE
);

PROCEDURE DebugACT;

-- Registering Filters
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
);

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE;

-- Starting a filter session
PROCEDURE CheckCompoundFilterAccess (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_access					IN	NUMBER
);

PROCEDURE CheckCompoundFilterForCycles (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CreateCompoundFilter (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CreateCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CopyCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
);

FUNCTION IsFilterEmpty(
	in_filter_id				IN  filter.filter_id%TYPE
) RETURN NUMBER;

FUNCTION IsCompoundFilterEmpty(
	in_compound_filter_id		IN  compound_filter.compound_filter_id%TYPE
) RETURN NUMBER;

FUNCTION GetSharedParentSid (
	in_card_group_id			IN	card_group.card_group_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION IsFilterEnabled (
	in_card_group_id			IN  card_group.card_group_id%TYPE
) RETURN NUMBER;

PROCEDURE GetExportManagerType (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE,
	out_card_group_id			OUT	card_group.card_group_id%TYPE
);

PROCEDURE LinkToBatchJob (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE,
	in_filter_type				IN	NUMBER,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE
);

PROCEDURE CleanupBatchExport (
	in_batch_job_id				IN	csr.batch_job.batch_job_id%TYPE
);

PROCEDURE CloneCompoundFilterForBatchJob (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CloneBreadcrumbsForBatchJob (
	in_breadcrumb				IN	security_pkg.T_SID_IDS,
	out_gp_compound_filter		OUT SYS_REFCURSOR,
	out_breadcrumb				OUT SYS_REFCURSOR
);

PROCEDURE SaveCompoundFilter (
	in_saved_filter_sid			IN 	security_pkg.T_SID_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_search_text				IN	saved_filter.search_text%TYPE,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_grp_by_cmpnd_filter_id	IN	compound_filter.compound_filter_id%TYPE,
	in_aggregation_types		IN	security_pkg.T_SID_IDS,
	in_name						IN	saved_filter.name%TYPE,
	in_folder_sid				IN	security_pkg.T_SID_ID,
	in_region_column_id			IN	saved_filter.region_column_id%TYPE,
	in_date_column_id			IN	saved_filter.date_column_id%TYPE,
	in_group_key				IN	saved_filter.group_key%TYPE,
	in_cms_id_column_sid		IN	saved_filter.cms_id_column_sid%TYPE,
	in_list_page_url			IN	saved_filter.list_page_url%TYPE,
	in_exclude_from_reports		IN	saved_filter.exclude_from_reports%TYPE,
	in_region_sids				IN	security_pkg.T_SID_IDS,
	in_dual_axis				IN	saved_filter.dual_axis%TYPE,
	in_ranking_mode				IN	saved_filter.ranking_mode%TYPE DEFAULT 0,
	in_colour_by				IN	saved_filter.colour_by%TYPE,
	in_colour_range_id			IN	saved_filter.colour_range_id%TYPE,
	in_order_by					IN  saved_filter.order_by%TYPE DEFAULT NULL,
	in_order_direction			IN  saved_filter.order_direction%TYPE DEFAULT NULL,	
	in_results_per_page			IN  saved_filter.results_per_page%TYPE DEFAULT NULL,
	in_map_colour_by			IN  saved_filter.map_colour_by%TYPE DEFAULT NULL,
	in_map_cluster_bias			IN  saved_filter.map_cluster_bias%TYPE DEFAULT NULL,
	in_column_names_to_keep		IN  security_pkg.T_VARCHAR2_ARRAY,
	in_hide_empty				IN	saved_filter.hide_empty%TYPE DEFAULT 0,
	out_saved_filter_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE SaveCompoundFilterColumn (
	in_saved_filter_sid			IN 	security_pkg.T_SID_ID,
	in_column_name				IN  saved_filter_column.column_name%TYPE,
	in_pos						IN  saved_filter_column.pos%TYPE,
	in_width					IN  saved_filter_column.width%TYPE,
	in_label					IN  saved_filter_column.label%TYPE
);

PROCEDURE GetSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_query					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION HasSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE
) RETURN NUMBER;

-- Creates a new compound filter based on the saved one
PROCEDURE LoadSavedFilter (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	out_fil_cur						OUT	SYS_REFCURSOR,
	out_agg_types					OUT	SYS_REFCURSOR,
	out_breadcrumb					OUT	SYS_REFCURSOR,
	out_region_sids					OUT	SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
);

PROCEDURE LoadReadOnlySavedFilter (
	in_saved_filter_sid				IN	security_pkg.T_SID_ID,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	out_fil_cur						OUT	SYS_REFCURSOR,
	out_agg_types					OUT	SYS_REFCURSOR,
	out_breadcrumb					OUT	SYS_REFCURSOR,
	out_region_sids					OUT	SYS_REFCURSOR,
	out_columns						OUT SYS_REFCURSOR
);

-- Returns compound filter from saved one. For read-only use only.
-- Used by issue chart portlet but superceded by new reporting model
FUNCTION LoadReadOnlySavedFilter (
	in_saved_filter_sid			IN	security_pkg.T_SID_ID
) RETURN compound_filter.compound_filter_id%TYPE;

PROCEDURE GetSavedFilterName(
	in_saved_filter_sid			IN	security_pkg.T_SID_ID,
	out_filter_name				OUT saved_filter.name%TYPE	
);

-- Filter item management
FUNCTION GetNextFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER;

FUNCTION GetCompoundIdFromfilterId (
	in_filter_id				IN	filter.filter_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE;

PROCEDURE DeleteFilter (
	in_filter_id				IN	filter.filter_id%TYPE
);

PROCEDURE DeleteCompoundFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE
);

PROCEDURE AddCardFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
);

PROCEDURE UpdateFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_operator_type			IN	filter.operator_type%TYPE
);

PROCEDURE GetFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
);

PROCEDURE GetFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- Filter field + value management. NB this is a generic version for use in helper_pkgs, but helper_pkgs can choose to store this information how they want
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	in_group_by_index		IN	filter_field.group_by_index%TYPE,
	in_show_all				IN	filter_field.show_all%TYPE,
	in_top_n				IN	filter_field.top_n%TYPE,
	in_bottom_n				IN	filter_field.bottom_n%TYPE,
	in_column_sid			IN	filter_field.column_sid%TYPE,
	in_period_set_id		IN	filter_field.period_set_id%TYPE := NULL,
	in_period_interval_id	IN	filter_field.period_interval_id%TYPE := NULL,
	in_show_other			IN	filter_field.show_other%TYPE := NULL,
	in_row_or_col			IN	filter_field.row_or_col%TYPE := NULL,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
);

PROCEDURE UpdateFilterField (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_group_by_index		IN	filter_field.group_by_index%TYPE,
	in_show_all				IN	filter_field.show_all%TYPE,
	in_top_n				IN	filter_field.top_n%TYPE,
	in_bottom_n				IN	filter_field.bottom_n%TYPE,
	in_column_sid			IN	filter_field.column_sid%TYPE,
	in_period_set_id		IN	filter_field.period_set_id%TYPE,
	in_period_interval_id	IN	filter_field.period_interval_id%TYPE,
	in_show_other			IN	filter_field.show_other%TYPE,
	in_comparator			IN  filter_field.comparator%TYPE,
	in_row_or_col			IN  filter_field.row_or_col%TYPE
);

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_null_filter			IN  filter_value.null_filter%TYPE DEFAULT NULL_FILTER_ALL,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddRegionValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_region_sid			IN	filter_value.region_sid%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddUserValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_user_sid				IN	filter_value.user_sid%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddCompoundFilterValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_compound_filter_id	IN	filter_value.compound_filter_id_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddSavedFilterValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_saved_filter_sid		IN	filter_value.saved_filter_sid_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_null_filter			IN  filter_value.null_filter%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddDateRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_start_dtm			IN	filter_value.start_dtm_value%TYPE,
	in_end_dtm				IN	filter_value.end_dtm_value%TYPE,
	in_description			IN	filter_value.description%TYPE,
	in_stringValue			IN	filter_value.str_value%TYPE DEFAULT NULL,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddNumberRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_min_value			IN	filter_value.MIN_NUM_VAL%TYPE,
	in_max_value			IN	filter_value.MAX_NUM_VAL%TYPE,
	in_description			IN	filter_value.description%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE CopyFieldsAndValues (
	in_from_filter_id		IN	filter.filter_id%TYPE,
	in_to_filter_id			IN	filter.filter_id%TYPE
);

PROCEDURE GetFieldsAndValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_field_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_value_cur			OUT	security_pkg.T_OUTPUT_CUR
);

-- helper functions
FUNCTION CheckNumberRange (
	in_compare_value				IN	NUMBER,
	in_number_type					IN	NUMBER,
	in_min_value					IN	NUMBER,
	in_max_value					IN	NUMBER
) RETURN NUMBER;

FUNCTION GetNumberTypeCount (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
) RETURN NUMBER;

PROCEDURE SortNumberValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
);

PROCEDURE SortFlowStateValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
);

PROCEDURE SortScoreThresholdValues (
	in_filter_field_id				IN  chain.filter_value.filter_field_id%TYPE
);

PROCEDURE SetFlowStateColours (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE
);

PROCEDURE SetThresholdColours (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE
);

PROCEDURE PopulateDateRangeTT (
	in_filter_field_id				IN filter_value.filter_field_id%TYPE,
	in_include_time_in_filter		IN NUMBER
);

-- Gets a start/end date that is the smallest overall date window
-- that covers all filter values the requested field, restricted by
-- optional start / end dates from the drilldown
PROCEDURE GetLargestDateWindow (
	in_compound_filter_id	IN	compound_filter.compound_filter_id%TYPE,
	in_field_name			IN	filter_field.name%TYPE,
	in_helper_pkg			IN	filter_type.helper_pkg%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	out_start_dtm			OUT	DATE,
	out_end_dtm				OUT	DATE
);

PROCEDURE CreateDateRangeValues (
	in_filter_field_id		IN	NUMBER,
	in_min_date				IN	DATE,
	in_max_date				IN	DATE
);

PROCEDURE SetupCalendarDateField (	
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE
);

PROCEDURE ShowAllTags (
	in_filter_field_id				IN  filter_field.filter_field_id%TYPE,
	in_tag_group_id					IN  csr.tag_group.tag_group_id%TYPE
);

PROCEDURE ApplyBreadcrumb (
	in_filtered_ids			IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb			IN	security_pkg.T_SID_IDS,
	out_filtered_ids		OUT	T_FILTERED_OBJECT_TABLE
);

FUNCTION GetPrivateFiltersRoot
RETURN security_pkg.T_SID_ID;

PROCEDURE GetFilterList(
	in_card_group_id		IN	card_group.card_group_id%TYPE,
	in_parent_sid			IN	security_pkg.T_SID_ID,	
	in_cms_id_column_sid	IN  saved_filter.cms_id_column_sid%TYPE,
	in_for_report			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_agg_types			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunCompoundFilter(
	in_filter_proc_name				VARCHAR2,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
);

FUNCTION FindTopN (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_type				IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_max_group_by					IN	NUMBER DEFAULT NULL
) RETURN security.T_ORDERED_SID_TABLE;

FUNCTION FindTopN (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_type				IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	in_max_group_by					IN	NUMBER DEFAULT NULL
) RETURN security.T_ORDERED_SID_TABLE;

PROCEDURE GetAllFilterFieldValues (
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	out_top_n_values				OUT security.T_ORDERED_SID_TABLE
);

FUNCTION GetCompFilterIdFromBreadcrumb(
	in_breadcrumb					IN	security_pkg.T_SID_IDS
) RETURN NUMBER;

FUNCTION GetCompoundFilterIdFromAdapter(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER
) RETURN NUMBER;

FUNCTION GetGroupByLimit(
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE
) RETURN NUMBER;

PROCEDURE GetAggregateData (
	in_card_group_id				IN	chain.card_group.card_group_id%TYPE,
	in_field_filter_id				IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	in_max_group_by					IN	NUMBER,
	in_show_totals					IN	NUMBER,
	in_object_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	in_top_n_values					IN  security.T_ORDERED_SID_TABLE,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR
);

PROCEDURE PopulateTempRegionSid (
	in_region_sids					IN	security.T_SID_TABLE,	
	in_region_col_type				IN	NUMBER,
	out_has_regions					OUT NUMBER
);

PROCEDURE GetAvailableGroups (
	out_available_groups_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetFilterReportConfig (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_group_key				IN	filter_page_column.group_key%TYPE DEFAULT NULL,
	in_path						IN	filter_item_config.path%TYPE DEFAULT NULL,
	out_inds_cur				OUT SYS_REFCURSOR,
	out_inds_interval_cur		OUT SYS_REFCURSOR,
	out_cms_tables_cur			OUT SYS_REFCURSOR,
	out_agg_types_cur			OUT SYS_REFCURSOR,
	out_page_columns_cur		OUT SYS_REFCURSOR,
	out_item_config_cur			OUT SYS_REFCURSOR,
	out_filter_cols_cur			OUT SYS_REFCURSOR,
	out_agg_type_config_cur		OUT SYS_REFCURSOR,
	out_available_groups_cur	OUT SYS_REFCURSOR,
	out_customer_cols_cur		OUT SYS_REFCURSOR,
	out_customer_items_cur		OUT SYS_REFCURSOR,
	out_cust_item_agg_typs_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetFilterPageColumns (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFilterItemConfig (
	in_card_group_id			IN	filter_item_config.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_path						IN	filter_item_config.path%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAggregateTypeConfig (
	in_card_group_id			IN	aggregate_type_config.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE DEFAULT NULL,
	in_path						IN	aggregate_type_config.path%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearFilterPageColumns (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE
);

PROCEDURE SaveFilterPageColumn (
	in_card_group_id			IN  filter_page_column.card_group_id%TYPE,
	in_session_prefix			IN  filter_page_column.session_prefix%TYPE,
	in_group_key				IN	filter_page_column.group_key%TYPE DEFAULT NULL,
	in_column_name				IN  filter_page_column.column_name%TYPE, 
	in_label					IN  filter_page_column.label%TYPE, 
	in_pos						IN  filter_page_column.pos%TYPE, 
	in_width					IN  filter_page_column.width%TYPE DEFAULT 150, 
	in_fixed_width				IN  filter_page_column.fixed_width%TYPE DEFAULT 0, 
	in_hidden					IN  filter_page_column.hidden%TYPE DEFAULT 0,
	in_group_sid				IN  filter_page_column.group_sid%TYPE DEFAULT NULL,
	in_include_in_export		IN  filter_page_column.include_in_export%TYPE DEFAULT 0
);

PROCEDURE SaveFilterItemConfig (
	in_card_group_id			IN  filter_item_config.card_group_id%TYPE,
	in_js_class_type			IN	card.js_class_type%TYPE,
	in_session_prefix			IN  filter_item_config.session_prefix%TYPE,
	in_item_name				IN  filter_item_config.item_name%TYPE, 
	in_label					IN  filter_item_config.label%TYPE, 
	in_pos						IN  filter_item_config.pos%TYPE, 
	in_group_sid				IN  filter_item_config.group_sid%TYPE DEFAULT NULL,
	in_path						IN  filter_item_config.path%TYPE DEFAULT NULL,
	in_include_in_filter		IN  filter_item_config.include_in_filter%TYPE DEFAULT 1,
	in_include_in_breakdown		IN  filter_item_config.include_in_breakdown%TYPE DEFAULT 1,
	in_include_in_advanced		IN  filter_item_config.include_in_advanced%TYPE DEFAULT 1
);

PROCEDURE SaveAggregateTypeConfig (
	in_card_group_id			IN  aggregate_type_config.card_group_id%TYPE,
	in_aggregate_type_id		IN  aggregate_type_config.aggregate_type_id%TYPE, 
	in_session_prefix			IN  aggregate_type_config.session_prefix%TYPE DEFAULT NULL,
	in_label					IN  aggregate_type_config.label%TYPE, 
	in_pos						IN  aggregate_type_config.pos%TYPE DEFAULT NULL, 
	in_group_sid				IN  aggregate_type_config.group_sid%TYPE DEFAULT NULL,
	in_path						IN  aggregate_type_config.path%TYPE DEFAULT NULL,
	in_enabled					IN  aggregate_type_config.enabled%TYPE DEFAULT 1
);

FUNCTION UNSEC_AddCustomerAggregateType (
	in_card_group_id				IN  customer_aggregate_type.card_group_id%TYPE,
	in_cms_aggregate_type_id		IN  customer_aggregate_type.cms_aggregate_type_id%TYPE DEFAULT NULL,
	in_initiative_metric_id			IN  customer_aggregate_type.initiative_metric_id%TYPE DEFAULT NULL,
	in_ind_sid						IN  customer_aggregate_type.ind_sid%TYPE DEFAULT NULL,
	in_filter_page_ind_interval_id	IN  customer_aggregate_type.filter_page_ind_interval_id%TYPE DEFAULT NULL,
	in_meter_aggregate_type_id		IN  customer_aggregate_type.meter_aggregate_type_id%TYPE DEFAULT NULL,
	in_score_type_agg_type_id		IN  customer_aggregate_type.score_type_agg_type_id%TYPE DEFAULT NULL,
	in_cust_filt_item_agg_type_id	IN	customer_aggregate_type.cust_filt_item_agg_type_id%TYPE DEFAULT NULL
) RETURN NUMBER;

PROCEDURE UNSEC_RemoveCustomerAggType (
	in_customer_aggregate_type_id	IN  customer_aggregate_type.customer_aggregate_type_id%TYPE
);

PROCEDURE GetAggregateTypes (
	in_card_group_id			IN  NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEmptyExtraSeriesCur (
	out_extra_series_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetReportData (
	in_card_group_id				IN  card_group.card_group_id%TYPE,
	in_search						IN	VARCHAR2,
	in_group_key					IN  saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER,
	in_parent_id					IN	NUMBER,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE,
	in_aggregation_types			IN	security_pkg.T_SID_IDS,
	in_show_totals					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_max_group_by					IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN  NUMBER,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_aggregate_cur				OUT SYS_REFCURSOR,
	out_aggregate_threshold_cur		OUT SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetIdsAndRegionSids (
	in_card_group_id				IN  card_group.card_group_id%TYPE,
	in_search						IN	VARCHAR2,
	in_group_key					IN  saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_cms_id_column_sid			IN  saved_filter.cms_id_column_sid%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_region_sid_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetFilterColumns (
	in_card_group_id			IN  NUMBER,
	in_column_type				IN  card_group_column_type.column_type%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

/*
 * Tree View Procedures
 */
PROCEDURE GetTreeWithDepth(
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid			IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTree(
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid			IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTextFiltered(
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid			IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_card_group_id				IN	card_group.card_group_id%TYPE,
	in_cms_id_column_sid			IN	saved_filter.cms_id_column_sid%TYPE,
	in_for_report					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/*
 * End Tree View Procedures
 */
 
/*
 * Start of alert procedures
 */
PROCEDURE GetAlertJobs (
	out_cur							OUT SYS_REFCURSOR,
	out_users_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetAllAlertParams (
	out_cg_cur						OUT SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetAlertData (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SetupInitialSet (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS
);

PROCEDURE MarkAlertSent (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_object_ids					IN  security_pkg.T_SID_IDS
);

PROCEDURE SetAlertErrorMessage (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_error_message				IN  saved_filter_alert_subscriptn.error_message%TYPE
);

PROCEDURE SetAlertNextFireTime (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_next_fire_time				IN  saved_filter_alert.next_fire_time%TYPE,
	in_alerts_sent_on_last_run		IN  saved_filter_alert.alerts_sent_on_last_run%TYPE
);

PROCEDURE GetFilterAlerts (
	in_search						IN  VARCHAR2,
	in_start_row					IN  NUMBER,
	in_end_row						IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_alert_cur					OUT SYS_REFCURSOR,
	out_subscription_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	out_alert_cur					OUT SYS_REFCURSOR,
	out_subscription_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetAlertParams (
	in_std_alert_type_id			IN	csr.customer_alert_type.std_alert_type_id%TYPE,
	in_customer_alert_type_id		IN	csr.customer_alert_type.customer_alert_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_description					IN  saved_filter_alert.description%TYPE,
	in_customer_alert_type_id		IN  saved_filter_alert.customer_alert_type_id%TYPE,
	in_alert_frame_id				IN  csr.alert_template.alert_frame_id%TYPE,
	in_send_type					IN  csr.alert_template.send_type%TYPE,
	in_reply_to_name				IN  csr.alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN  csr.alert_template.reply_to_email%TYPE,
	in_users_can_subscribe			IN  saved_filter_alert.users_can_subscribe%TYPE,
	in_is_hourly					IN  NUMBER,
	in_schedule_xml					IN  saved_filter_alert.schedule_xml%TYPE,
	in_next_fire_time				IN  saved_filter_alert.next_fire_time%TYPE,
	out_customer_alert_type_id		OUT saved_filter_alert.customer_alert_type_id%TYPE
);

PROCEDURE SaveFilterAlertBody (
	in_customer_alert_type_id		IN  csr.alert_template_body.customer_alert_type_id%TYPE,
	in_lang							IN  csr.alert_template_body.lang%TYPE,
	in_subject						IN  csr.alert_template_body.subject%TYPE,
	in_body_html					IN  csr.alert_template_body.body_html%TYPE,
	in_item_html					IN  csr.alert_template_body.item_html%TYPE
);

PROCEDURE DeleteFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID
);
 
PROCEDURE CreateFilterAlertSubscription (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_has_had_initial_set			IN  saved_filter_alert_subscriptn.has_had_initial_set%TYPE
);

PROCEDURE DeleteFilterAlertSubscription (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_region_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE UnsubscribeFromFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SubscribeToFilterAlert (
	in_saved_filter_sid				IN  security_pkg.T_SID_ID,
	in_region_sids					IN  security_pkg.T_SID_IDS
);

PROCEDURE GetMyFilterAlerts (
	out_filter_alerts				OUT  SYS_REFCURSOR,
	out_filter_alert_regions		OUT  SYS_REFCURSOR
);
 
/*
 * End of alert procedures
 */ 

PROCEDURE GetFilterPageCmsTables (
	in_card_group_id				IN  filter_page_cms_table.card_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveFilterPageCmsTable (
	in_filter_page_cms_table_id		IN  filter_page_cms_table.filter_page_cms_table_id%TYPE,
	in_card_group_id				IN  filter_page_cms_table.card_group_id%TYPE,
	in_column_sid					IN  filter_page_cms_table.column_sid%TYPE,
	out_filter_page_cms_table_id	OUT filter_page_cms_table.filter_page_cms_table_id%TYPE
);

PROCEDURE DeleteFilterPageCmsTable (
	in_filter_page_cms_table_id		IN  filter_page_cms_table.filter_page_cms_table_id%TYPE
);


/*
 * Start of filter ind procedures
 */ 
PROCEDURE GetFilterPageInds (
	in_card_group_id				IN  filter_page_ind.card_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_intervals_cur				OUT SYS_REFCURSOR
);

PROCEDURE SaveFilterPageInd (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE,
	in_card_group_id				IN  filter_page_ind.card_group_id%TYPE,
	in_ind_sid						IN  filter_page_ind.ind_sid%TYPE,
	in_period_set_id				IN  filter_page_ind.period_set_id%TYPE,
	in_period_interval_id			IN  filter_page_ind.period_interval_id%TYPE,
	in_start_dtm					IN  filter_page_ind.start_dtm%TYPE,
	in_end_dtm						IN  filter_page_ind.end_dtm%TYPE,
	in_previous_n_intervals			IN  filter_page_ind.previous_n_intervals%TYPE,
	in_include_in_list				IN  filter_page_ind.include_in_list%TYPE,
	in_include_in_filter			IN  filter_page_ind.include_in_filter%TYPE,
	in_include_in_aggregates		IN  filter_page_ind.include_in_aggregates%TYPE,
	in_include_in_breakdown			IN  filter_page_ind.include_in_breakdown%TYPE,
	in_show_measure_in_description	IN  filter_page_ind.show_measure_in_description%TYPE,
	in_show_interval_in_descriptn	IN  filter_page_ind.show_interval_in_description%TYPE,
	in_description_override			IN  filter_page_ind.description_override%TYPE,
	out_filter_page_ind_id			OUT filter_page_ind.filter_page_ind_id%TYPE
);

PROCEDURE DeleteFilterPageInd (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE
);

PROCEDURE GenerateFilterPageIndIntervals (
	in_filter_page_ind_id			IN  filter_page_ind.filter_page_ind_id%TYPE
);

PROCEDURE EmptyTempFilterIndVal;

PROCEDURE AddTempFilterIndVal (
	in_filter_page_ind_interval_id	IN  tt_filter_ind_val.filter_page_ind_interval_id%TYPE,
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_ind_sid						IN  security_pkg.T_SID_ID,
	in_period_start_dtm				IN  tt_filter_ind_val.period_start_dtm%TYPE,
	in_period_end_dtm				IN  tt_filter_ind_val.period_end_dtm%TYPE,
	in_val_number					IN  tt_filter_ind_val.val_number%TYPE,
	in_error_code					IN  tt_filter_ind_val.error_code%TYPE,
	in_note							IN  tt_filter_ind_val.note%TYPE
);

PROCEDURE FilterInd (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
);
 
/*
 * End of filter ind procedures
 */


/*
 * Caching procedures
 */
FUNCTION GetFilterCacheTimeout
RETURN NUMBER;

PROCEDURE GetFilteredObjectsFromCache (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE DEFAULT NULL,
	out_filtered_objects			OUT	T_FILTERED_OBJECT_TABLE
);

PROCEDURE SetFilteredObjectsInCache (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE DEFAULT NULL,
	in_filtered_objects				IN 	T_FILTERED_OBJECT_TABLE
);

PROCEDURE ClearCacheForAllUsers (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE DEFAULT NULL,
	in_cms_col_sid					IN	filter_cache.cms_col_sid%TYPE DEFAULT NULL
);

PROCEDURE ClearCacheForUser (
	in_card_group_id				IN	filter_cache.card_group_id%TYPE DEFAULT NULL,
	in_user_sid						IN	filter_cache.user_sid%TYPE
);

PROCEDURE RemoveExpiredCaches;

/*
 * End of Caching procedures
 */

PROCEDURE GetGridExtensions (
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetCustomerGridExtensions (
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE SaveCustomerGridExtension (
	in_grid_extension_id		IN customer_grid_extension.grid_extension_id%TYPE,
	in_enabled					IN customer_grid_extension.enabled%TYPE,
	out_grid_extension_id		OUT	customer_grid_extension.grid_extension_id%TYPE
);

PROCEDURE GetEnabledGridExtensions (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE SortExtension(
	in_base_grid				IN VARCHAR2,
	in_id_list					IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row				IN	NUMBER,
	in_end_row					IN	NUMBER,
	in_order_by 				IN	VARCHAR2,
	in_order_dir				IN	VARCHAR2,
	out_id_list					OUT	security.T_ORDERED_SID_TABLE
);


PROCEDURE InvertFilterSet(
	in_starting_sids 		IN  T_FILTERED_OBJECT_TABLE,
	in_result_sids   		IN  T_FILTERED_OBJECT_TABLE,
	out_inverse_result_sids	OUT	T_FILTERED_OBJECT_TABLE
);

PROCEDURE SaveCustomerFilterColumn(
	in_card_group_id	IN	customer_filter_column.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_column.session_prefix%TYPE,
	in_column_name		IN	customer_filter_column.column_name%TYPE,
	in_label			IN	customer_filter_column.label%TYPE,
	in_width			IN	customer_filter_column.width%TYPE,
	in_fixed_width		IN	customer_filter_column.fixed_width%TYPE,
	in_sortable			IN	customer_filter_column.sortable%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerFilterColumns(
	in_card_group_id	IN	customer_filter_column.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_column.session_prefix%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCustomerFilterItem(
	in_card_group_id	IN	customer_filter_item.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_item.session_prefix%TYPE,
	in_item_name		IN	customer_filter_item.item_name%TYPE,
	in_label			IN	customer_filter_item.label%TYPE,
	in_can_breakdown	IN	customer_filter_item.can_breakdown%TYPE,
	in_analytic_fns		IN  security.security_pkg.T_SID_IDS,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR,
	out_agg_types_cur	OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerFilterItems(
	in_card_group_id	IN	customer_filter_item.card_group_id%TYPE,
	in_session_prefix	IN	customer_filter_item.session_prefix%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR,
	out_agg_types_cur	OUT	security.security_pkg.T_OUTPUT_CUR
);


END filter_pkg;
/
