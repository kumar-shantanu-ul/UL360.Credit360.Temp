create or replace package supplier.report_wood_pkg 
IS

PROCEDURE RunWRMEReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunWWFStyleWRMEReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunAccreditationValueReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunWoodDataDumpReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunWoodDataDumpReportTEST(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

END report_wood_pkg;
/
