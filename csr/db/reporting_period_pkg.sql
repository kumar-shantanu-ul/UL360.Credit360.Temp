CREATE OR REPLACE PACKAGE CSR.reporting_period_Pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE GetReportingPeriods(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateReportingPeriod(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_app_sid 				IN  security_pkg.T_SID_ID,
	in_name					IN	reporting_period.name%TYPE,
	in_start_dtm			IN	reporting_period.start_dtm%TYPE,
	in_end_dtm				IN	reporting_period.end_dtm%TYPE,
	in_copy_deleg_forward	IN 	NUMBER,
	out_sid					OUT	security_pkg.T_SID_ID
);

PROCEDURE AmendReportingPeriod(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_name					IN	reporting_period.name%TYPE,
	in_start_dtm			IN	reporting_period.start_dtm%TYPE,
	in_end_dtm				IN	reporting_period.end_dtm%TYPE
);

PROCEDURE GetCurrentPeriod(
	in_app_sid			IN		security_pkg.T_SID_ID,
	out_name			OUT		reporting_period.name%TYPE,
	out_start_dtm		OUT		reporting_period.start_dtm%TYPE,
	out_end_dtm			OUT		reporting_period.end_dtm%TYPE
);

PROCEDURE GetReportingPeriod(
	in_app_sid			IN		security.security_pkg.T_SID_ID,
	in_rp_sid			IN		security.security_pkg.T_SID_ID,
	out_cur				OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCurrentPeriod(
	in_reporting_period_sid	IN	security_pkg.T_SID_ID
);

END reporting_period_Pkg;
/
