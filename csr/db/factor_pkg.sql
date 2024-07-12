CREATE OR REPLACE PACKAGE CSR.factor_pkg AS

FACTOR_PATH_SEPARATOR		CONSTANT VARCHAR(3) := '>>>';
DEFAULT_PROFILE_NAME		CONSTANT VARCHAR(20) := 'Migrated profile';
MIGRATED_CSTM_SET_NAME		CONSTANT VARCHAR(20) := 'Bespoke factors';
MIGRATED_OVERRS_SET_NAME	CONSTANT VARCHAR(20) := 'Overrides';

FUNCTION CheckForOverlapStdFactorData RETURN NUMBER;

FUNCTION CheckForOverlapCtmFactorData RETURN NUMBER;
PROCEDURE GetOverlapCtmFactorData(
	out_overlap_count		OUT NUMBER,
	out_overlaps			OUT VARCHAR2
);

PROCEDURE SetStdFactorValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_egrid_ref			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE,
	out_std_factor_id		OUT std_factor.std_factor_id%TYPE
);

PROCEDURE GetFactorTypeMappedPaths(
	out_mapped_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorsForFactorTypes(
	in_factor_type_ids	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE ApplyIndicatorMappings(
	in_factor_type_id	IN factor_type.factor_type_id%TYPE,
	in_measure_sid		IN factor_type.std_measure_id%TYPE,
	in_ind_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetFactorTypePaths(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetFactorTypeNodes(
	out_cur		OUT	SYS_REFCURSOR
);

UNSPECIFIED_FACTOR_TYPE				CONSTANT NUMBER(10) := 3;

PROCEDURE GetGasList(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetGasTypes(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetStdMeasure(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetStdMeasConvList(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetStdFactorSets(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetFactorTypes(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetVisibleFactorTypes(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAvailableStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);
PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,	
	in_geo_region			IN factor.geo_region%TYPE,	
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetBespokeFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetStdFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);


FUNCTION GetRootFactorTypeSid RETURN security_pkg.T_SID_ID;

FUNCTION GetFactorTypeNameBySid 
(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
) RETURN factor_type.name%TYPE;


FUNCTION GetStdSetName
(
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE
) RETURN std_factor_set.name%TYPE;


PROCEDURE DeleteRegionOverrides(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_sids					IN	security_pkg.T_SID_IDS
);

PROCEDURE UpdateSelectedSetForApp(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE
);

PROCEDURE UpdateSelectedSet(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,	
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,	
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE
);

---------  Factor Type tree handlers ----------
PROCEDURE GetTreeWithDepth(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_fetch_depth			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeWithSelect(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_select_sid			IN	security_pkg.T_SID_ID,
	in_fetch_depth			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_search_phrase		IN	VARCHAR2,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_limit			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
-------------------------------------------------------




-- tree handlers for non region tree picker (use to add non geo overrides)
PROCEDURE GetNonGeoRegionTreeRoots(
	in_geo_country	IN	factor.geo_country%TYPE,
	in_geo_region	IN	factor.geo_region%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonRegionTreeWithDepth(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS,
	in_include_root	IN	NUMBER,
	in_fetch_depth	IN	NUMBER,
	in_factor_id	IN	factor_type.factor_type_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonRegionTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_factor_id		IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonRegionList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_limit			IN	NUMBER,
	in_factor_id		IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonRegionListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_factor_id	IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


-- handlers for accessing std factor table
PROCEDURE StdFactorAddNewValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE,
	in_source				IN std_factor.source%TYPE,
	out_std_factor_id		OUT std_factor.std_factor_id%TYPE
);

PROCEDURE StdFactorAmendValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE
);

PROCEDURE StdFactorDelValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE
);



---- handlers for accessing factor table for bespoke values
PROCEDURE BespokeFactorAddNewValue(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN factor.start_dtm%TYPE,
	in_end_dtm				IN factor.end_dtm%TYPE,
	in_gas_type_id			IN factor.gas_type_id%TYPE,
	in_value				IN factor.value%TYPE,
	in_std_meas_conv_id		IN factor.std_measure_conversion_id%TYPE,
	in_note					IN factor.note%TYPE,
	out_factor_id			OUT factor.factor_id%TYPE
);

PROCEDURE BespokeFactorAmendValue(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_id			IN factor.factor_id%TYPE,
	in_start_dtm			IN factor.start_dtm%TYPE,
	in_end_dtm				IN factor.end_dtm%TYPE,
	in_gas_type_id			IN factor.gas_type_id%TYPE,
	in_value				IN factor.value%TYPE,
	in_std_meas_conv_id		IN factor.std_measure_conversion_id%TYPE,
	in_note					IN factor.note%TYPE
);

PROCEDURE BespokeFactorDelValue(
	in_factor_id		IN factor.factor_id%TYPE
);

PROCEDURE CheckExistStdFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckExistBespokeFactor(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSelectedChildrenStdFactor(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSelectedChildrenFactor(
	in_factor_id		IN factor.factor_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUsedGasFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetFactorTypeName(
	in_factor_type_id			IN factor_type.factor_type_id%TYPE
) RETURN factor_type.name%TYPE;

PROCEDURE GetGasFactorListForInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGasFactorListForInd(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	factor.start_dtm%TYPE,
	in_end_dtm				IN	factor.end_dtm%TYPE,
	in_geo_countries		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_geo_regions			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetInheritedStdFactorType (
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE
) RETURN factor_type.factor_type_id%TYPE;

FUNCTION GetInheritedBespokeFactorType (
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE
) RETURN factor_type.factor_type_id%TYPE;

PROCEDURE GetFactorTabs (
	in_plugin_type_id		IN	plugin.plugin_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION CreateStdFactorSet(
	in_name						IN std_factor_set.name%TYPE,
	in_factor_set_group_id		IN std_factor_set.factor_set_group_id%TYPE,
	in_info_note				IN std_factor_set.info_note%TYPE DEFAULT NULL
) RETURN std_factor.std_factor_set_id%TYPE;

FUNCTION CreateCustomFactorSet(
	in_name						IN custom_factor_set.name%TYPE,
	in_factor_set_group_id		IN custom_factor_set.factor_set_group_id%TYPE,
	in_info_note				IN custom_factor_set.info_note%TYPE DEFAULT NULL
) RETURN custom_factor.custom_factor_set_id%TYPE;

PROCEDURE GetStdFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_custom_factor_set_id	IN custom_factor_set.custom_factor_set_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckExistCustomFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertCustomValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN custom_factor.region_sid%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_custom_factor_id	OUT custom_factor.custom_factor_id%TYPE
);

PROCEDURE CustomFactorAddNewValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN custom_factor.region_sid%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_custom_factor_id	OUT custom_factor.custom_factor_id%TYPE
);
	
PROCEDURE CustomFactorAmendValue(
	in_custom_factor_id		IN custom_factor.custom_factor_id%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_message				OUT VARCHAR2
);

PROCEDURE CustomFactorDelValue(
	in_custom_factor_id		IN custom_factor.custom_factor_id%TYPE
);


FUNCTION GetFactorSetName(
	in_factor_set_id		IN NUMBER
) RETURN VARCHAR2;

FUNCTION GetFactorSetInfoNote(
	in_factor_set_id		IN NUMBER
) RETURN CLOB;


PROCEDURE GetEmissionProfiles(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateEmissionProfile(
	in_name					IN	emission_factor_profile.name%TYPE,
	in_applied				IN	emission_factor_profile.applied%TYPE,
	in_start_dtm			IN	emission_factor_profile.start_dtm%TYPE,
	out_profile_id			OUT	emission_factor_profile.profile_id%TYPE
);

PROCEDURE DeleteEmissionProfile(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE
);

PROCEDURE RenameEmissionProfile(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_new_name				IN emission_factor_profile.name%TYPE
);

PROCEDURE UpdateEmissionProfileStatus(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_applied				IN emission_factor_profile.applied%TYPE,
	in_start_dtm			IN emission_factor_profile.start_dtm%TYPE
);

PROCEDURE RebuildEmissionProfileFactors;

PROCEDURE GetEmissionProfile(
	in_profile_id			IN emission_factor_profile.name%TYPE,
	out_cur_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_factors			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_mapped			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionsFactorsMap (
	in_profile_id		IN	emission_factor_profile.profile_id%TYPE,
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE,
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetActiveFactorSets (
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE,
	in_geo_ids			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetProfileFactorMap (
	in_profile_id	IN	emission_factor_profile.profile_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetAllFactors (
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE, 
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE, 
	in_country			IN	factor.geo_country%TYPE, 
	in_region			IN	factor.geo_region%TYPE, 
	in_region_sid		IN	factor.region_sid%TYPE,
	period_cur			OUT	SYS_REFCURSOR,
	gas_cur				OUT SYS_REFCURSOR
);

PROCEDURE WriteFactorLogEntry(
	in_factor_cat_id		IN	custom_factor_history.factor_cat_id%TYPE,
	in_factor_type_id		IN	custom_factor_history.factor_type_id%TYPE,
	in_factor_set_id		IN	custom_factor_history.factor_set_id%TYPE,
	in_country				IN	custom_factor_history.geo_country%TYPE,
	in_region				IN 	custom_factor_history.geo_region%TYPE,
	in_egrid_ref			IN	custom_factor_history.egrid_ref%TYPE,
	in_region_sid			IN	custom_factor_history.region_sid%TYPE,
	in_gas_type_id			IN	custom_factor_history.gas_type_id%TYPE,
	in_start_dtm			IN	custom_factor_history.start_dtm%TYPE,
	in_end_dtm				IN	custom_factor_history.end_dtm%TYPE,
	in_field_name			in	custom_factor_history.field_name%TYPE DEFAULT NULL,
	in_old_val				IN	custom_factor_history.old_val%TYPE DEFAULT NULL,
	in_new_val				IN	custom_factor_history.new_val%TYPE DEFAULT NULL,
	in_message				IN	custom_factor_history.message%TYPE
);

PROCEDURE GetAuditLogForCustomFactor(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE,
	in_factor_set_id		IN	custom_factor.custom_factor_set_id%TYPE,
	in_country				IN	custom_factor.geo_country%TYPE, 
	in_region				IN	custom_factor.geo_region%TYPE,
	in_egrid_ref			IN	custom_factor.egrid_ref%TYPE,
	in_region_sid			IN	custom_factor.region_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_start_date			IN	DATE,
	in_end_date				IN	DATE,
	out_total				OUT	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AprxDelProfFactors(
	in_profile_id	IN	emission_factor_profile.profile_id%TYPE
);

PROCEDURE AprxDelProfileSetFactors(
	in_profile_id				IN	emission_factor_profile.profile_id%TYPE,
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE,
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE
);

PROCEDURE AprxSaveProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE, 
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
);

PROCEDURE SaveProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE, 
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
);

PROCEDURE DeleteProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE, 
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
);

PROCEDURE UpdateEmissionProfileFactors (
	in_profile_id				IN	emission_factor_profile.profile_id%TYPE
);

FUNCTION GetDateForMigratedNewProfile RETURN DATE;

PROCEDURE AddStdProfleFactorsFromFactors (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
);

PROCEDURE AddCustomFactorsToProfile (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
);

PROCEDURE CreateCustomFactorsFromFactors (
	in_custom_factor_set_id		IN	custom_factor.custom_factor_set_id%TYPE,
	in_get_overrides			IN	NUMBER
);

PROCEDURE RunProfileChecksForMigration (
	in_profile_name				IN	VARCHAR2
);

FUNCTION CheckExistingCustomSets (
	in_check_overrides_only		IN	NUMBER
) RETURN NUMBER;

PROCEDURE SetEndDateProfileOnMigration (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
);

PROCEDURE UNSEC_DetachFactorsForMigraton;

PROCEDURE RenameCustomFactorSet(
	in_factor_set_id		IN custom_factor_set.custom_factor_set_id%TYPE,
	in_new_name				IN custom_factor_set.name%TYPE
);

PROCEDURE RenameStdFactorSet(
	in_factor_set_id		IN std_factor_set.std_factor_set_id%TYPE,
	in_new_name				IN std_factor_set.name%TYPE
);

PROCEDURE UpdateStdFactorSetInfoNote(
	in_factor_set_id		IN std_factor_set.std_factor_set_id%TYPE,
	in_info_note			IN std_factor_set.info_note%TYPE
);

PROCEDURE UpdateCustomFactorSetInfoNote(
	in_factor_set_id		IN custom_factor_set.custom_factor_set_id%TYPE,
	in_info_note			IN custom_factor_set.info_note%TYPE
);

PROCEDURE UpdateSubRegionFactors;

PROCEDURE OverlappingFactors(
	out_std_overlaps_cur			OUT	SYS_REFCURSOR,
	out_custom_overlaps_cur			OUT	SYS_REFCURSOR,
	out_std_overlaps_data_cur		OUT	SYS_REFCURSOR,
	out_custom_overlaps_data_cur	OUT	SYS_REFCURSOR
);

PROCEDURE OrphanedProfileFactors(
	out_orphans_cur					OUT	SYS_REFCURSOR
);

PROCEDURE DeleteOrphanedProfileFactors;

PROCEDURE AddFactorType(
	in_parent_id			IN factor_type.parent_id%TYPE,
	in_name					IN factor_type.name%TYPE,
	in_std_measure_id		IN factor_type.std_measure_id%TYPE,
	in_egrid				IN factor_type.egrid%TYPE,
	in_enabled				IN factor_type.enabled%TYPE DEFAULT 0,
	in_info_note			IN factor_type.info_note%TYPE DEFAULT NULL
);

PROCEDURE UpdateFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_parent_id			IN factor_type.parent_id%TYPE,
	in_name					IN factor_type.name%TYPE,
	in_std_measure_id		IN factor_type.std_measure_id%TYPE,
	in_egrid				IN factor_type.egrid%TYPE,
	in_info_note			IN factor_type.info_note%TYPE,
	in_visible				IN factor_type.visible%TYPE DEFAULT NULL
);

PROCEDURE UpdateFactorTypeInfoNote(
	in_factor_type_id			IN factor_type.factor_type_id%TYPE,
	in_info_note			IN factor_type.info_note%TYPE
);

PROCEDURE EnableFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
);

PROCEDURE DisableFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
);

PROCEDURE ChangeFactorTypeVisibility(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_visible			IN factor_type.visible%TYPE
);

PROCEDURE DeleteFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
);

PROCEDURE MoveFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_parent_id			IN factor_type.parent_id%TYPE
);

PROCEDURE GetFactorsForExport(
	out_profile_cur			OUT	SYS_REFCURSOR,
	out_factor_cur			OUT	SYS_REFCURSOR
);

END factor_pkg;
/
