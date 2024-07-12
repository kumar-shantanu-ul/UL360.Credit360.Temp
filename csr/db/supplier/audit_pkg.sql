CREATE OR REPLACE PACKAGE SUPPLIER.audit_pkg 
IS

TYPE T_VARCHAR2_VALUES IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;

PROCEDURE AuditValueChange(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_sub_object_id	IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
);

-- for a single tag
PROCEDURE AuditTagChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_description	IN	tag_group.description%TYPE,
	in_old_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_new_tag_id				IN  tag.tag_id%TYPE,
	in_clear_old_tag_ids		IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditTagChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_description	IN	tag_group.description%TYPE,
	in_old_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_new_tag_ids				IN  tag_pkg.T_TAG_IDS,
	in_clear_old_tag_ids		IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditVarcharListChange(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_audit_type_id			IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_add_description			IN	csr.audit_log.description%TYPE,
	in_remove_description		IN	csr.audit_log.description%TYPE,
	in_param_1          		IN  csr.audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          		IN  csr.audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          		IN  csr.audit_log.param_3%TYPE DEFAULT NULL,
	in_old_values				IN  T_VARCHAR2_VALUES,
	in_new_values				IN  T_VARCHAR2_VALUES,
	in_clear_values				IN	NUMBER,
	in_sub_object_id			IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	csr.audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	csr.audit_log.description%TYPE,
	in_param_1          IN  csr.audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  csr.audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  csr.audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	csr.audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE GetAuditLogForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditLogForCompany(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditLogForProdQuests(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_id		IN	csr.audit_log.sub_object_id%TYPE,
	in_start			IN NUMBER,
	in_page_size		IN NUMBER,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditLogForProdQuestsCount(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_product_id		IN	csr.audit_log.sub_object_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for dyn list output
	out_cnt				OUT	NUMBER
);

END audit_pkg;
/

