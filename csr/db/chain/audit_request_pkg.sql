CREATE OR REPLACE PACKAGE  CHAIN.audit_request_pkg
IS

PROCEDURE CreateAuditRequest(
	in_auditor_company_sid			IN	audit_request.auditor_company_sid%TYPE,
	in_auditee_company_sid			IN	audit_request.auditee_company_sid%TYPE,
	in_notes						IN	audit_request.notes%TYPE,
	in_proposed_dtm					IN	audit_request.proposed_dtm%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditRequest(
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateRequestedAudit(
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE,
	in_label						IN	csr.internal_audit.label%TYPE,
	in_auditor_user_sid				IN	security_pkg.T_SID_ID,
	in_audit_dtm					IN	csr.internal_audit.audit_dtm%TYPE,
	in_notes						IN	csr.internal_audit.notes%TYPE,
	in_internal_audit_type			IN	csr.internal_audit.internal_audit_type_id%TYPE,
	out_audit_sid					OUT	security_pkg.T_SID_ID
);

PROCEDURE GetOpenAuditRequestsByAuditor(
	in_auditor_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOpenAuditRequestsByAuditee(
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOpenAuditRequests(
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAvailableAuditorsForAuditee(
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SearchPermissibleAuditees(
	in_search_term  				IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHistoricAuditRequests(
	in_auditor_company_sid			IN	security_pkg.T_SID_ID,
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRequestedAlertApps(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRequestedAlertData(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RecordRequestedAlertSent(
	in_audit_request_id				IN audit_request.audit_request_id%TYPE,
	in_user_sid						IN security_pkg.T_SID_ID
);

END audit_request_pkg;
/
