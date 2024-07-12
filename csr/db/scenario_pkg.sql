CREATE OR REPLACE PACKAGE CSR.scenario_pkg AS

RT_ABSOLUTE_VALUE				CONSTANT NUMBER(10) := 0;
RT_ABSOLUTE_CHANGE				CONSTANT NUMBER(10) := 1;
RT_PERCENTAGE_CHANGE			CONSTANT NUMBER(10) := 2;
RT_INITIATIVES_IND_FILTER		CONSTANT NUMBER(10) := 3;
RT_LIKE_FOR_LIKE				CONSTANT NUMBER(10) := 4;
RT_ACTIVE_FOR_WHOLE_PERIOD		CONSTANT NUMBER(10) := 5;
RT_FORECASTING					CONSTANT NUMBER(10) := 6;
RT_FIXCALCRESULTS				CONSTANT NUMBER(10) := 7;

PROCEDURE GetOptions (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioList(
	in_parent_sid					IN 	security_pkg.T_SID_ID,	 
	in_order_by						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_scn_ind_cur					OUT	SYS_REFCURSOR,
	out_scn_region_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetMergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUnmergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioExtrapolationRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_rule_ind_cur				OUT	SYS_REFCURSOR,
	out_rule_region_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioLikeForLikeRule(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetForecastingRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetFixCalcResultsRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_ind_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioLikeForLikeRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_exclusion_set_cur			OUT	SYS_REFCURSOR,
	out_contiguous_set_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioIndFilterRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR,
	out_exclusion_set_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetActiveForWholePeriodRules(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_rule_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_scn_ind_cur					OUT	SYS_REFCURSOR,
	out_scn_region_cur				OUT	SYS_REFCURSOR,
	out_scn_rule_cur				OUT	SYS_REFCURSOR,
	out_scn_rule_ind_cur			OUT	SYS_REFCURSOR,
	out_scn_rule_region_cur			OUT	SYS_REFCURSOR,
	out_scn_like_rule_cur			OUT SYS_REFCURSOR	
);

PROCEDURE SaveScenario(
	in_class_id						IN	security_pkg.T_CLASS_ID DEFAULT NULL,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario.description%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_regions						IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	scenario.start_dtm%TYPE,
	in_end_dtm						IN	scenario.end_dtm%TYPE,
	in_period_set_id				IN	scenario.period_set_id%TYPE DEFAULT 1,
	in_period_interval_id			IN	scenario.period_interval_id%TYPE DEFAULT 1,
	in_include_all_inds				IN	scenario.include_all_inds%TYPE DEFAULT 0,
	in_file_based					IN	scenario.file_based%TYPE DEFAULT 1,
	out_scenario_sid				OUT	scenario.scenario_sid%TYPE
);

PROCEDURE SaveRule(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE,
	in_description					IN	scenario_rule.description%TYPE,
	in_rule_type					IN	scenario_rule.rule_type%TYPE,
	in_amount						IN	scenario_rule.amount%TYPE,
	in_measure_conversion_id		IN	scenario_rule.measure_conversion_id%TYPE,
	in_start_dtm					IN	scenario_rule.start_dtm%TYPE,
	in_end_dtm						IN	scenario_rule.end_dtm%TYPE,
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_regions						IN	security_pkg.T_SID_IDS,
	out_rule_id						OUT	scenario_rule.rule_id%TYPE
);

PROCEDURE DeleteRule(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE,
	in_rule_id						IN	scenario_rule.rule_id%TYPE
);

PROCEDURE DeleteAllRules(
	in_scenario_sid					IN	scenario_rule.scenario_sid%TYPE
);

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

-- TODO: warn if part of formula / has user mount points pointing to it etc?
PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID
);

-- Indicator tree view handlers for the rule edit screen
PROCEDURE GetRuleIndTreeWithDepth(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRuleIndTreeWithSelect(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRuleIndTreeTextFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRuleIndTreeTagFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRuleIndListTextFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRuleIndListTagFiltered(
	in_indicators					IN	security_pkg.T_SID_IDS,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE ResolveNormalInds(
	in_ind_list						IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllRegions (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllUntrashedRegions (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllUntrashedInds (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_fetch_depth   				IN	NUMBER,
	out_cur   						OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderTreeWithSelect(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid   				IN	security_pkg.T_SID_ID,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderList(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_root_sid						IN	security_pkg.T_SID_ID,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_root_sid						IN	security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateFolder(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	out_sid_id						OUT	security_pkg.T_SID_ID
);

PROCEDURE GetFolderScenarios(
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFolderScenarioRuns(
	in_parent_sid					IN 	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE Subscribe(
	in_scenario_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE Unsubscribe(
	in_scenario_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE GetPendingScenarioAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MarkScenarioAlertSent(
	in_app_sid						IN	scenario_alert.app_sid%TYPE,
	in_calc_job_id					IN	scenario_alert.calc_job_id%TYPE,
	in_user_sid						IN	scenario_alert.csr_user_sid%TYPE
);

END scenario_pkg;
/
