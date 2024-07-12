CREATE OR REPLACE PACKAGE SUPPLIER.options_pkg
IS

PROCEDURE GetCustomerOptions (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END options_pkg;
/



