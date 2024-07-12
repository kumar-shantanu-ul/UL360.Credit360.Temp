CREATE OR REPLACE PACKAGE BODY SUPPLIER.sales_pkg
IS

PROCEDURE GetReportingPeriods(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN customer_period.app_sid%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	OPEN out_cur FOR
		SELECT p.period_id, p.name, p.from_dtm, p.to_dtm
		  FROM period p, customer_period c
		 WHERE c.app_sid = in_app_sid
		   AND p.period_id = c.period_id
		   	ORDER BY p.from_dtm;
END;

END sales_pkg;
/
