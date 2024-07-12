CREATE OR REPLACE PACKAGE csr.temp_csr_data_pkg AS

PROCEDURE WriteAuditLogEntry(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
);

END temp_csr_data_pkg;
/


CREATE OR REPLACE PACKAGE BODY csr.temp_csr_data_pkg AS

PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3, SUB_OBJECT_ID)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, in_sid_id, TruncateString(in_description,1023), TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048), in_sub_object_id);
END;

PROCEDURE WriteAuditLogEntry(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_audit_type_id				IN	audit_log.audit_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	audit_log.description%TYPE,
	in_param_1          			IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          			IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          			IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
    WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);
END;

END;
/