CREATE OR REPLACE PACKAGE CSR.csr_app_pkg AS

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

PROCEDURE DeleteApp(
	in_reduce_contention			IN	NUMBER	DEFAULT 0,
	in_debug_log_deletes			IN	NUMBER	DEFAULT 0,
	in_logoff_before_delete_so		IN	NUMBER	DEFAULT 0
);

/**
 * Add a translation for the given application
 *
 * @param in_application_sid	The application to add the translation for
 * @param in_lang_id			The lang id of the language to add a translation for
 */
PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
);

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
);

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	in_site_type					IN  customer.site_type%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
);

PROCEDURE AddAdminAndPublicSubFolders(
	in_parent_sid		IN	security_pkg.T_SID_ID
);

/**
 * Return the version number of the database
 * NOTE: No security. For use by the REST API, needs to work even for guests.
 *
 * @param in_act_id				The access topen
 * @param out_db_version		The DB version
 */
PROCEDURE GetDBVersion(
	out_db_version				OUT	version.db_version%TYPE
);

PROCEDURE WriteAudit(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_description				IN	audit_log.description%TYPE,
	in_param_1					IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2					IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3					IN  audit_log.param_3%TYPE DEFAULT NULL
);

PROCEDURE WriteNewSiteAuditDetails(
	in_original_sitename		IN	csr.site_audit_details.original_sitename%TYPE,
	in_created_by				IN	csr.site_audit_details.created_by%TYPE,
	in_created_dtm				IN	csr.site_audit_details.created_dtm%TYPE,
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_contract_reference		IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_expiry_dtm				IN	csr.site_audit_details.original_expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE,
	in_enabled_modules			IN	csr.site_audit_details.enabled_modules%TYPE
);

PROCEDURE WriteSiteAuditDetailsToExisting(
	in_sitename					IN	csr.site_audit_details.original_sitename%TYPE,
	in_created_by				IN	csr.site_audit_details.created_by%TYPE,
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_contract_reference		IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_expiry_dtm				IN	csr.site_audit_details.original_expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE
);

PROCEDURE AddClientNameToAuditDetails(
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_user_sid					IN	csr.site_audit_details_client_name.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
);

PROCEDURE UpdateExpiryDtmOnAuditDetails(
	in_expiry_dtm				IN	csr.site_audit_details_expiry.expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_expiry.reason%TYPE
);

PROCEDURE UpdateReasonOnAuditDetails(
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE,
	in_user_sid					IN	csr.site_audit_details_reason.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
);

PROCEDURE AddContractRefToAuditDetails(
	in_contract_ref				IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_user_sid					IN	csr.site_audit_details_contract_ref.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
);

PROCEDURE UpdateSiteType(
	in_site_type				IN	csr.customer.site_type%TYPE
);

PROCEDURE GetSiteAuditDetails(
	out_details_cur			OUT	SYS_REFCURSOR,
	out_client_names_cur	OUT	SYS_REFCURSOR,
	out_expiry_dates_cur	OUT	SYS_REFCURSOR,
	out_reasons_cur			OUT	SYS_REFCURSOR,
	out_contract_refs_cur	OUT	SYS_REFCURSOR
);

END;
/
