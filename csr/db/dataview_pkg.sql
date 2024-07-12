CREATE OR REPLACE PACKAGE CSR.Dataview_Pkg AS

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
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * TrashObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

/**
 * RestoreFromTrash
 * 
 * @param in_object_sids			The objects being restored
 */
PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

/**
 * SaveDataView
 * 
 * @param in_dataview_sid					Sid of the dataview to amend
 * @param in_parent_sid						Parent folder
 * @param in_name							The name
 * @param in_start_dtm						The start date
 * @param in_end_dtm						The end date
 * @param in_group_by						Group by settings
 * @param in_period_set_id					The period set
 * @param in_period_interval				The period interval (m|q|h|y)
 * @param in_chart_config_xml				Chart configuration
 * @param in_chart_style_xml				Chart style
 * @param in_description					Description of the dataview
 * @param in_dataview_type_id				1 = ChartOrTable (i.e. Data Explorer), 2 = ExcelExport (i.e. Data Export)
 * @param in_show_calc_trace				Show the calculation trace
 * @param in_show_variance					Show percentage variance
 * @param in_show_abs_variance				Show absolute variance
 * @param in_show_variance_explanations		Show variance explanations
 * @param in_include_parent_region_names	How many parent regions to include in the region name
 * @param in_sort_by_most_recent			Sort by most recent period
 * @param in_treat_null_as_zero				Show null values as zero
 * @param in_rank_limit_left				Number or percent of values for the left-hand bar chart
 * @param in_rank_limit_left_type			Whether the left limit specifies a number or a percentage
 * @param in_rank_limit_right				Number or percent of values for the right-hand bar chart
 * @param in_rank_limit_right_type			Whether the right limit specifies a number or a percentage
 * @param in_rank_ind_sid					Indicator to rank by
 * @param in_rank_filter_type				The type of filtering to use
 * @param in_rank_reverse					Whether the filtered values should be reversed
 * @param in_region_grouping_tag_group		The tag group to group regions by (0 for no grouping)
 * @param in_anonymous_region_names			Whether to use anonymous region names
 * @param in_include_notes_in_table			Whether to include user-entered notes in the generated table
 * @param in_show_region_events				Whether to display region events
 * @param in_suppress_unmerged_data_msg		Whether to suppress the message about using unmerged data
 *											even if the corresponding capability is enabled and unmerged
 *											data is being used
 * @param in_highlight_changed_since		Whether to highlight values
 * @param in_highlight_changed_since_dtm	Date to highlight values after
 * @param in_aggregation_period_id			Aggregation Period Id
 * @param in_show_layer_variance_pct		Show Layer Variance (percentage)
 * @param in_show_layer_variance_abs		Show Layer Variance (absolute)
 * @param in_show_layer_var_pct_base		Show Layer Base Variance (percentage)
 * @param in_show_layer_var_abs_base		Show Layer Base Variance (absolute)
 * @param out_dataview_sid_id				Sid of the created dataview
 */
PROCEDURE SaveDataView(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	in_name							IN	dataview.name%TYPE,
	in_start_dtm					IN	dataview.start_dtm%TYPE,
	in_end_dtm						IN	dataview.end_dtm%TYPE,
	in_group_by						IN	dataview.group_by%TYPE,
	in_period_set_id				IN	dataview.period_set_id%TYPE,
	in_period_interval_id			IN	dataview.period_interval_id%TYPE,
	in_chart_config_xml				IN 	dataview.chart_config_xml%TYPE,
	in_chart_style_xml				IN	dataview.chart_style_xml%TYPE,
	in_description					IN	dataview.description%TYPE,
	in_dataview_type_id				IN	dataview.dataview_type_id%TYPE,
	in_show_calc_trace				IN	dataview.show_calc_trace%TYPE,
	in_show_variance				IN	dataview.show_variance%TYPE,
	in_show_abs_variance			IN	dataview.show_abs_variance%TYPE,
	in_show_variance_explanations	IN	dataview.show_variance_explanations%TYPE,
	in_include_parent_region_names	IN	dataview.include_parent_region_names%TYPE,
	in_sort_by_most_recent			IN	dataview.sort_by_most_recent%TYPE,
	in_treat_null_as_zero			IN	dataview.treat_null_as_zero%TYPE,
	in_rank_limit_left				IN	dataview.rank_limit_left%TYPE,
	in_rank_limit_left_type			IN	dataview.rank_limit_left_type%TYPE,
	in_rank_limit_right				IN	dataview.rank_limit_right%TYPE,
	in_rank_limit_right_type		IN	dataview.rank_limit_right%TYPE,
	in_rank_ind_sid					IN	dataview.rank_ind_sid%TYPE,
	in_rank_filter_type				IN	dataview.rank_filter_type%TYPE,
	in_rank_reverse					IN	dataview.rank_reverse%TYPE,
	in_region_grouping_tag_group	IN	dataview.region_grouping_tag_group%TYPE,
	in_anonymous_region_names		IN	dataview.anonymous_region_names%TYPE,
	in_include_notes_in_table		IN	dataview.include_notes_in_table%TYPE,
	in_show_region_events			IN	dataview.show_region_events%TYPE,
	in_suppress_unmerged_data_msg	IN	dataview.suppress_unmerged_data_message%TYPE,
	in_highlight_changed_since		IN	dataview.highlight_changed_since%TYPE,
	in_highlight_changed_since_dtm	IN	dataview.highlight_changed_since_dtm%TYPE,
	in_show_layer_variance_pct		IN	dataview.show_layer_variance_pct%TYPE,
	in_show_layer_variance_abs		IN	dataview.show_layer_variance_abs%TYPE,
	in_show_layer_var_pct_base		IN	dataview.show_layer_variance_pct_base%TYPE,
	in_show_layer_var_abs_base		IN	dataview.show_layer_variance_abs_base%TYPE,
	in_show_layer_variance_start	IN	dataview.show_layer_variance_start%TYPE,
	in_aggregation_period_id		IN	dataview.aggregation_period_id%TYPE DEFAULT NULL,
	out_dataview_sid_id				OUT security_pkg.T_SID_ID
);

/* The complexities of secobjs and special characters requires a specific rename func. */
PROCEDURE RenameDataView(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	dataview.name%TYPE
);

/**
 * GetDataView
 * 
 * @param in_act_id				Access token
 * @param in_dataview_sid		.
 * @param out_cur				The rowset
 */
PROCEDURE GetDataView(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_AddDataViewZone(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_pos							IN	dataview_zone.pos%TYPE,
	in_type							IN	dataview_zone.type%TYPE,
	in_name							IN	dataview_zone.name%TYPE,
	in_description					IN	dataview_zone.description%TYPE,
	in_start_val_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_val_region_sid			IN	security_pkg.T_SID_ID,
	in_start_val_start_dtm			IN	dataview_zone.start_val_start_dtm%TYPE,
	in_start_val_end_dtm			IN	dataview_zone.start_val_end_dtm%TYPE,
	in_end_val_ind_sid				IN	security_pkg.T_SID_ID,
	in_end_val_region_sid			IN	security_pkg.T_SID_ID,
	in_end_val_start_dtm			IN	dataview_zone.end_val_start_dtm%TYPE,
	in_end_val_end_dtm				IN	dataview_zone.end_val_end_dtm%TYPE,
	in_style_xml					IN	dataview_zone.style_xml%TYPE,
	in_is_target					IN	dataview_zone.is_target%TYPE,
	in_target_direction				IN	dataview_zone.target_direction%TYPE
);

PROCEDURE GetDataViewZones(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_AddDataViewTrend(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_pos							IN	dataview_trend.pos%TYPE,
	in_name							IN	dataview_trend.name%TYPE,
	in_title						IN	dataview_trend.title%TYPE,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_months						IN	dataview_trend.months%TYPE,
	in_rounding_method				IN	dataview_trend.rounding_method%TYPE,
	in_rounding_digits				IN	dataview_trend.rounding_digits%TYPE
);

PROCEDURE GetDataViewTrends(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_dataview_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetChildDataViews
 * 
 * @param in_act_id				Access token
 * @param in_parent_sid			The sid of the parent object
 * @param in_dataview_type_id	The type of dataview to return, or 0 for all types
 * @param out_cur				The rowset
 */
PROCEDURE GetChildDataViews(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	in_dataview_type_id	IN dataview.dataview_type_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

/** 
 * Lists the child data views, ordered by position
 * The output rowset is of the form:
 * dataview_sid, name
 *
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param out_cur			The rowset
 *
 * I DON'T THINK THIS IS CALLED FROM ANYWHERE NOW
 */
PROCEDURE GetChildDataViewsByPos(
	in_act_id			 IN security_pkg.T_ACT_ID,
	in_parent_sid		 IN security_pkg.T_SID_ID,
	out_cur				 OUT SYS_REFCURSOR
);

/** 
 * Lists the child data views, ordered by position
 * The output rowset is of the form:
 * dataview_sid, name
 *
 * @param in_act_id				Access token
 * @param in_parent_sid			The sid of the parent object
 * @param in_dataview_type_id	The type of dataview to return, or 0 for all types
 * @param out_cur				The rowset
 */
PROCEDURE GetChildDataViewsByPos(
	in_act_id			 IN security_pkg.T_ACT_ID,
	in_parent_sid		 IN security_pkg.T_SID_ID,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur				 OUT SYS_REFCURSOR
);

/**
 * GetInstanceDataViews
 * 
 * @param in_act_id			Access token
 * @param in_context		.
 * @param in_instance_Id	.
 * @param out_cur			The rowset
 */
PROCEDURE GetInstanceDataViews(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_context			IN instance_dataview.context%TYPE,
	in_instance_Id	IN instance_dataview.instance_Id%TYPE,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * AddInstanceDataView
 * 
 * @param in_act_id				Access token
 * @param in_context			.
 * @param in_instance_Id		.
 * @param in_dataview_sid		.
 * @param in_pos				.
 */
PROCEDURE AddInstanceDataView(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_context			IN instance_dataview.context%TYPE,
	in_instance_Id	IN instance_dataview.instance_Id%TYPE,
	in_dataview_sid	IN security_pkg.T_SID_ID,
	in_pos					IN instance_dataview.pos%TYPE
);


/**
 * RemoveInstanceDataView
 * 
 * @param in_act_id				Access token
 * @param in_context			.
 * @param in_instance_Id		.
 * @param in_dataview_sid		.
 */
PROCEDURE RemoveInstanceDataView(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_context			IN instance_dataview.context%TYPE,
	in_instance_Id	IN instance_dataview.instance_Id%TYPE,
	in_dataview_sid	IN security_pkg.T_SID_ID
);

/**
 * GetDescendantDataViews
 * 
 * @param in_act_id			Access token
 * @param in_root_sid		.
 * @param out_cur			The rowset
 */
PROCEDURE GetDescendantDataViews(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_root_sid		IN security_pkg.T_SID_ID,
	in_dataview_type_id	 IN dataview.dataview_type_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * CopyDataView
 * 
 * @param in_act_id					Access token
 * @param in_copy_dataview_sid		.
 * @param in_parent_sid_id			The sid of the parent object
 * @param out_sid_id				.
 */
PROCEDURE CopyDataView(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_dataview_sid	IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
);


/**
 * RemoveIndicators
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE RemoveIndicators(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
);

/**
 * AddIndicator
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_ind_sid				The sid of the object
 * @param in_description			The description
 * @param in_format_mask			Format mask for the indicator
 * @param in_show_as_rank			1 to convert values to ranks; 0 to leave them as values
 * @param in_normalization_ind_sid	The sid of the indicator to normalise by
 * @param in_langs					Languages for translations
 * @param in_translations			Translations into various languagesn
 */
PROCEDURE AddIndicator(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_dataview_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_calculation_type_id		IN	security_pkg.T_SID_ID,
	in_format_mask				IN	ind.format_mask%TYPE,
	in_measure_conversion_id	IN	dataview_ind_member.measure_conversion_id%TYPE,
	in_normalization_ind_sid	IN	dataview_ind_member.normalization_ind_sid%TYPE,
	in_show_as_rank				IN	dataview_ind_member.show_as_rank%TYPE,
	in_langs					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations				IN	security_pkg.T_VARCHAR2_ARRAY
);

/**
 * GetIndicators
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the dataview
 * @param out_ind_cur				Indicator details
 * @param out_ind_tag_cur			Indicator tags
 * @param out_normalisation_ind_cur	Indicators used for normalisation
 * @param out_ind_translations_cur	Translations of indicator descriptions
 */
PROCEDURE GetIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_ind_cur						OUT SYS_REFCURSOR,
	out_ind_tag_cur					OUT SYS_REFCURSOR,
	out_normalisation_ind_cur		OUT SYS_REFCURSOR,
	out_ind_translations_cur		OUT SYS_REFCURSOR
);

/** 
 * Determines if an indicator is used in a data view for the purpose of normalisation.
 *
 *	@param in_ind_sid	
 *		The SID of the indicator to test.
 *
 *	@param in_check_children
 *		If specified, descendents of the specified indicator will also be checked.
 *
 *	@return 
 *		Returns 1, if the indicator is used for normalisation; otherwise, returns 0.
 */
FUNCTION IsIndicatorUsedInNormalisation(
	in_ind_sid						IN security_pkg.T_SID_ID,
	in_check_children				IN NUMBER DEFAULT(0)
) RETURN NUMBER;

/**
 * RemoveRegions
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE RemoveRegions(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
);

/**
 * Add a region to a dataview
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the dataview
 * @param in_region_sid				The sid of the region
 * @param in_langs					List of languages for region descriptions
 * @param in_translations			List of descriptions matching list of languages
 */
PROCEDURE AddRegion(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_sid_id					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_level					IN	NUMBER,
	in_langs					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations				IN	security_pkg.T_VARCHAR2_ARRAY
);

/**
 * Adds templated report region 
 * 
 * @param in_act_id							Access token
 * @param in_sid_id							The sid of the dataview
 * @param in_tpl_report_tag_dataview_id 	Templated report dataview tag id
 * @param in_region_sid						The sid of the region
 * @param in_tpl_region_type_id				The type of the region
 * @param in_filter_by_tag					The filter by tag ID for the region
 */
PROCEDURE AddTplReportRegion(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_tpl_report_tag_dataview_id	IN tpl_report_tag_dataview.tpl_report_tag_dataview_id%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_tpl_region_type_id			IN tpl_report_tag_dv_region.tpl_region_type_id%TYPE,
	in_filter_by_tag				IN tpl_report_tag_dv_region.filter_by_tag%TYPE
);

/**
 * GetRegions
 * 
 * @param in_act_id						Access token
 * @param in_sid_id						The sid of the dataview
 * @param out_region_cur				The regions
 * @param out_region_tag_cur			Region tags
 * @param out_region_translation_cur	Translations of the region names
 */
PROCEDURE GetRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_region_cur					OUT SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR,
	out_region_translation_cur		OUT	SYS_REFCURSOR
);

/**
 * GetDataViewRegions
 * 
 * @param in_sid_id						The sid of the dataview
 * @param in_region_sids				List of sids
 * @param in_skip_missing				Skip missing
 * @param in_skip_denied				Skip denied
 * @param out_region_cur				The regions
 * @param out_tag_cur					Region tags
 */
PROCEDURE GetDataViewRegions(
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
);

/**
 * GetTplReportsRegions
 * 
 * @param in_act_id						Access token
 * @param in_sid_id						The sid of the dataview
 * @param out_cur						The regions
 */
PROCEDURE GetTplReportsRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sid_id						IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Set the scenario runs for the given data view
 *
 * @param in_dataview_sid			The dataview to update
 * @param in_scenario_run_sids		Sids of the scenario runs to use
 */
PROCEDURE SetScenarioRuns(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	in_scenario_run_sids			IN	security_pkg.T_SID_IDS
);

FUNCTION GetScenarioDescription(
	in_scenario_run_type	IN	csr.dataview_scenario_run.scenario_run_type%TYPE,
	in_scenario_sid			IN	csr.scenario.scenario_sid%TYPE,
	in_scenario_run_sid		IN	csr.scenario_run.scenario_run_sid%TYPE
) RETURN VARCHAR2;

/**
 * Get the scenario runs for the given data view
 *
 * @param in_dataview_sid			The dataview
 * @param out_cur					The scenario run sids
 */
PROCEDURE GetScenarioRuns(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

-- Note that calls to the following are constructed dynamically
-- as csr.dataview_pkg.Get{0}Translations
-- by C:\cvs\fproot\App_Code\Credit360\Web\JsonRpcHandler.cs

/**
 * Get translations of an indicator name
 *
 * @param in_ind_sid				The indicator
 * @param out_cur					Translations
 */
PROCEDURE GetIndicatorTranslations(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get translations of a region name
 *
 * @param in_region_sid				The region
 * @param out_cur					Translations
 */
PROCEDURE GetRegionTranslations(
	in_region_sid					IN	region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get Arbitrary Periods for a dataview
 *
 * @param in_dataview_sid			The dataview
 * @param out_cur					Arbitrary Periods
 */
PROCEDURE GetArbitraryPeriods(
	in_dataview_sid					IN	dataview.dataview_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record Historic Arbitrary Periods for a dataview
 *
 * @param in_dataview_sid			The dataview
 */
PROCEDURE RecordHistoricArbitraryPeriods(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE
);

/**
 * Remove All Arbitrary Periods for a dataview
 *
 * @param in_dataview_sid			The dataview
 */
PROCEDURE RemoveAllArbitraryPeriods(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE
);

/**
 * Set Arbitrary Period for a dataview
 *
 * @param in_dataview_sid			The dataview
 */
PROCEDURE SetArbitraryPeriod(
	in_dataview_sid					IN	dataview_arbitrary_period.dataview_sid%TYPE,
	in_start_dtm					IN	dataview_arbitrary_period.start_dtm%TYPE,
	in_end_dtm						IN	dataview_arbitrary_period.end_dtm%TYPE
);

END Dataview_Pkg;
/
