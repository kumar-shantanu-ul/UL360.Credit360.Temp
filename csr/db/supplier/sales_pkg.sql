CREATE OR REPLACE PACKAGE SUPPLIER.sales_pkg
IS

PROCEDURE GetReportingPeriods(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN customer_period.app_sid%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

END sales_pkg;
/

