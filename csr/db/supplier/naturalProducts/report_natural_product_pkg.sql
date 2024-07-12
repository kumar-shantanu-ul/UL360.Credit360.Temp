create or replace package supplier.report_natural_product_pkg 
IS

PROCEDURE RunNPDataDumpReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	csr.utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

END report_natural_product_pkg;
/
