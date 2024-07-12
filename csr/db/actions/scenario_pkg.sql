CREATE OR REPLACE PACKAGE ACTIONS.scenario_pkg
IS

PROCEDURE GetStatusFilterList(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	out_details						OUT	security_pkg.T_OUTPUT_CUR,
	out_statuses					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	in_description					IN	csr.scenario.description%TYPE,
	in_status_ids					IN	security_pkg.T_SID_IDS
);

PROCEDURE SaveStatusFilter(
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	in_description					IN	csr.scenario.description%TYPE,
	in_status_ids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatusFilterInds (
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE OnTaskStatusChanged(
	in_task_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnTaskStatusChanged(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_from_status_id			task_status.task_status_id%TYPE,
	in_to_status_id				task_status.task_status_id%TYPE
);

PROCEDURE DeleteStatusFilter (
	in_scenario_sid					IN	csr.scenario.scenario_sid%TYPE,
	in_rule_id						IN	csr.scenario_rule.rule_id%TYPE
);

PROCEDURE GetFilterableStatuses (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

END scenario_pkg;
/
