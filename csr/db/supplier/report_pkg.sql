CREATE OR REPLACE PACKAGE SUPPLIER.report_pkg
IS

--TYPE T_TAG_IDS IS TABLE OF tag.tag_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE SetReportSettings(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_period_id		IN user_report_settings.period_id%TYPE,
	in_show_unapproved	IN user_report_settings.show_unapproved%TYPE,
	in_sales_types		IN tag_pkg.T_TAG_IDS
);

PROCEDURE GetReportSettings(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetReportSalesTypes(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunSalesValueReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);


END report_pkg;
/
