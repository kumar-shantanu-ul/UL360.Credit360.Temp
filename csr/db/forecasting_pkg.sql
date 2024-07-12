CREATE OR REPLACE PACKAGE csr.forecasting_pkg AS

-- Forecasting folder name
FORECASTING_FOLDER CONSTANT VARCHAR(50) := 'Forecasting datasets';

-- Rule Types
RULE_TYPE_FULL_PERIOD			CONSTANT NUMBER(1) := 0;
RULE_TYPE_PER_INTERVAL			CONSTANT NUMBER(1) := 1;

/* 
** SECURABLE OBJECT CALLBACKS
*/
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

FUNCTION CanEditForecast_sql(
	in_scenario_sid					IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER;

FUNCTION CanDeleteForecast_sql(
	in_scenario_sid					IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER;

PROCEDURE CreateForecast(
	in_description					IN	scenario.description%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_include_all_inds				IN	scenario.include_all_inds%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	scenario.start_dtm%TYPE,
	in_end_dtm						IN	scenario.end_dtm%TYPE,
	in_period_set_id				IN	scenario.period_set_id%TYPE,
	in_period_interval_id			IN	scenario.period_interval_id%TYPE,
	in_parent_folder_sid			IN	security_pkg.T_SID_ID	DEFAULT NULL,
	out_scenario_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE RecalculateForecast(
	in_scenario_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE GetFolderPath(
	in_folder_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetForecastList(
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION GetForecastCount
RETURN NUMBER;

PROCEDURE GetChildForecasts(
	in_parent_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UpdateRule(
	in_scenario_sid					IN	security_pkg.T_SID_ID,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE
);

PROCEDURE SaveRule(
	in_scenario_sid					IN	forecasting_rule.scenario_sid%TYPE,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE,
	in_ind_sid						IN	forecasting_rule.ind_sid%TYPE,
	in_region_sid					IN	forecasting_rule.region_sid%TYPE,
	in_start_dtm					IN	forecasting_rule.start_dtm%TYPE,
	in_end_dtm						IN	forecasting_rule.end_dtm%TYPE,
	in_rule_type					IN	forecasting_rule.rule_type%TYPE,
	in_rule_val						IN	forecasting_rule.rule_val%TYPE
);

PROCEDURE DeleteRule(
	in_slot_sid						IN	forecasting_rule.scenario_sid%TYPE,
	in_rule_id						IN	forecasting_rule.rule_id%TYPE,
	in_ind_sid						IN	forecasting_rule.ind_sid%TYPE,
	in_region_sid					IN	forecasting_rule.region_sid%TYPE
);

PROCEDURE GetRules(
	in_scenario_sid					IN	security_pkg.T_SID_ID,
	out_rules_cur					OUT	SYS_REFCURSOR
);

END;
/
