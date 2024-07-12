CREATE OR REPLACE PACKAGE ACTIONS.initiative_reporting_pkg
IS

PROCEDURE GetTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTagFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_tag_group_count	IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTagFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_tag_group_count	IN	NUMBER,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetMetricList (
	out_metrics						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReportTemplateList (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReportTemplateXml (
	in_template_id				IN	periodic_report_template.report_template_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE PeriodicReport (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_statuses					IN	security_pkg.T_SID_IDS,
	out_task					OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR
);

END initiative_reporting_pkg;
/
