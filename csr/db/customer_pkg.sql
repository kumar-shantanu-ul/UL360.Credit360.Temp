CREATE OR REPLACE PACKAGE CSR.customer_pkg AS

PROCEDURE GetDetails(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDetailsForASP(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AmendDetails(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	customer.name%TYPE,
	in_contact_email			IN	customer.contact_email%TYPE,
	in_raise_reminders			IN	customer.raise_reminders%TYPE,
	in_ind_info_xml_fields		IN	customer.ind_info_xml_fields%TYPE,
	in_region_info_xml_fields	IN	customer.region_info_xml_fields%TYPE,
	in_user_info_xml_fields 	IN	customer.user_info_xml_fields%TYPE
);

PROCEDURE GetMessage(
	out_cur						OUT	SYS_REFCURSOR
);

/**
 * Return the application sid for the given host
 * NOTE: No security, use only in batch applications or command line tools
 * Raises security_pkg.OBJECT_NOT_FOUND if the host could not be found
 *
 * @param in_host				The host
 * @param out_app_sid			The application sid
 */
PROCEDURE GetAppSid(
	in_host							IN	customer.host%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
);

/**
 * Check language settings of the site. 
 * It corrects it if necessary.
 * 
 * @param in_act_id				The access token.
 */
PROCEDURE EnsureAppLanguageIsValid(
	in_act_id				IN	security_pkg.T_ACT_ID
);

/**
 * Check language settings of the site and users.
 * It corrects them if necessary.
 * 
 * @param in_act_id				The access token.
 */

PROCEDURE EnsureLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
);

/**
 * Gets file upload options
 */
PROCEDURE GetFileUploadOptions(
	out_file_type_cur		OUT	SYS_REFCURSOR,
	out_mime_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE RemoveRolesOnAccountExpiration(
	in_remove_from_roles	IN	customer.remove_roles_on_account_expir%type
);

/**
 * Gets custom aggregation periods for app
 */
PROCEDURE GetAggregationPeriods(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSchema (
	in_host				IN	VARCHAR2,
	out_schema_name		OUT	VARCHAR2
);

PROCEDURE RefreshCalcWindows;

PROCEDURE DisableSALoginJustification;

PROCEDURE GetSystemTranslations(
	in_languages			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetSystemTranslation(
	in_original			IN 	VARCHAR2,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translation		IN	VARCHAR2,
	in_delete			IN	NUMBER
);

PROCEDURE GetSysTransAuditLog(
	in_order_by 					IN 	VARCHAR2,
	in_description_filter			IN	sys_translations_audit_log.description%TYPE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_IsQuestionLibraryEnabled(
	out_is_enabled			OUT	NUMBER
);

FUNCTION UNSEC_GetHostFromTenantId(
	in_tenant_id		IN	security.tenant.tenant_id%TYPE
)
RETURN VARCHAR2;

PROCEDURE SetBackgroundJobsStatus(
	in_calc_jobs_disabled		IN	csr.customer.calc_jobs_disabled%TYPE,
	in_batch_jobs_disabled		IN	csr.customer.batch_jobs_disabled%TYPE,
	in_scheduled_tasks_disabled	IN	csr.customer.scheduled_tasks_disabled%TYPE
);

PROCEDURE GetCascadeReject(
	out_cascade_reject			OUT	customer.cascade_reject%TYPE
);

PROCEDURE SetOracleSchema(
	in_oracle_schema			IN	csr.customer.oracle_schema%TYPE,
	in_overwrite				IN	NUMBER DEFAULT 0
);

PROCEDURE ToggleRenderChartsAsSvg;

FUNCTION ScheduledTasksDisabled
RETURN NUMBER;

FUNCTION ScheduledTasksDisabled(
	in_app_sid					IN	security_pkg.T_SID_ID
)
RETURN NUMBER;

END;
/
