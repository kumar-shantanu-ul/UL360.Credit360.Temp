CREATE OR REPLACE PACKAGE CHAIN.supplier_audit_pkg
IS

SUBTYPE T_REGRANT_REVOKE_ACTION		IS NUMBER;
REVOKE_ACTION						CONSTANT T_REGRANT_REVOKE_ACTION := 0;
REGRANT_ACTION						CONSTANT T_REGRANT_REVOKE_ACTION := 1;

PROCEDURE GetAudit(
	in_audit_survey_sid		IN security_pkg.T_SID_ID,
	in_survey_response_id	IN csr.quick_survey_response.survey_response_id%TYPE,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetAuditPermissions(
	in_auditor_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_action					IN 	T_REGRANT_REVOKE_ACTION
);

PROCEDURE SearchPermissibleAuditees(
	in_search_term  				IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchPermissibleAuditors(
	in_supplier_company_sid			IN	security_pkg.T_SID_ID,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAudits(
	in_auditor_company_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur					    OUT security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SaveAudit(
	in_audit_sid				IN	csr.internal_audit.internal_audit_sid%TYPE,
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_auditor_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID,	
	in_label					IN	csr.internal_audit.label%TYPE,
	in_audit_dtm				IN	csr.internal_audit.audit_dtm%TYPE,
	in_notes					IN	csr.internal_audit.notes%TYPE,
	in_internal_audit_type		IN	csr.internal_audit.internal_audit_type_id%TYPE,
	in_auditor_user_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_sid_id					OUT	csr.internal_audit.internal_audit_sid%TYPE
);

END supplier_audit_pkg;
/

