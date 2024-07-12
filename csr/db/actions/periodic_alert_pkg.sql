CREATE OR REPLACE PACKAGE  ACTIONS.periodic_alert_pkg
IS

PROCEDURE SetRecurrence(
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_recurrence_xml			IN	periodic_alert.recurrence_xml%TYPE
);

PROCEDURE GetAlertTypes(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE BeginBatchRun(	
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertData (
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_default_fire_date		IN	periodic_alert_user.next_fire_date%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordUserBatchRun(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_csr_user_sid				IN	csr.csr_user.csr_user_sid%TYPE,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_next_fire_date			IN	periodic_alert_user.next_fire_date%TYPE
);

PROCEDURE EndAppRun(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_next_fire_date			IN	periodic_alert_user.next_fire_date%TYPE
);

PROCEDURE EndBatchRun(
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE
);


-- SOME DIFFERENT ALERT DATA SELECTIONS

PROCEDURE GenericAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE OwnerAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DueAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE NonOwnerAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END periodic_alert_pkg;
/

