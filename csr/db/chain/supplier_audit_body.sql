CREATE OR REPLACE PACKAGE BODY CHAIN.supplier_audit_pkg
IS

PROCEDURE GetAudit(
	in_audit_survey_sid		IN security_pkg.T_SID_ID,
	in_survey_response_id	IN csr.quick_survey_response.survey_response_id%TYPE,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS 
	v_audit_sid		security_pkg.T_SID_ID;
	v_perm			NUMBER;
	v_has_cap_ac	NUMBER;
BEGIN
	SELECT internal_audit_sid
	  INTO v_audit_sid
	  FROM csr.internal_audit
	 WHERE app_sid = security_pkg.getApp
	   AND survey_sid = in_audit_survey_sid
	   AND survey_response_id = in_survey_response_id; 
	
	IF NOT (csr.audit_pkg.HasReadAccess(v_audit_sid)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||v_audit_sid);
	END IF;

	v_has_cap_ac := csr.audit_pkg.SQL_HasCapabilityAccess(v_audit_sid, csr.csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ);
	v_perm := csr.audit_pkg.GetPermissionOnAudit(v_audit_sid);

	OPEN out_result_cur FOR
		SELECT sa.audit_sid, sa.auditor_company_sid, ac.name auditor_company_name, sa.supplier_company_sid, sc.name supplier_company_name,			
			sa.created_by_company_sid, cbc.name created_by_company_name, a.audit_type_label, a.created_dtm, a.label audit_label,
			a.survey_completed survey_completed_dtm, a.open_non_compliances, 
			CASE WHEN a.flow_item_id IS NULL OR v_has_cap_ac = 1 THEN 
				a.audit_closure_type_id 
			ELSE NULL 
			END audit_closure_type_id,
			a.flow_sid, a.flow_label, a.flow_item_id, a.current_state_id, a.flow_state_label, 
			v_perm permission_level
		  FROM csr.v$audit a
		  JOIN chain.supplier_audit sa ON a.internal_audit_sid = sa.audit_sid
		  JOIN chain.company ac ON sa.auditor_company_sid = ac.company_sid
		  JOIN chain.company sc ON sa.supplier_company_sid = sc.company_sid
		  JOIN chain.company cbc ON sa.created_by_company_sid = cbc.company_sid
		 WHERE a.app_sid = security_pkg.getApp
		   AND a.survey_sid = in_audit_survey_sid
		   AND a.survey_response_id = in_survey_response_id;
	   
END;

PROCEDURE ResetAuditPermissions(
	in_auditor_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_action					IN  T_REGRANT_REVOKE_ACTION
)
AS
	v_audits_sid				security_pkg.T_SID_ID;
	v_auditor_users_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_auditor_company_sid, chain_pkg.USER_GROUP);
BEGIN	

	BEGIN
		v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN; --It's ok if audits are not enabled
	END;
	
	/* revoke, regrant audit permissions from/ to the purchaser on the supplier audits (logged user should have change_permissions permissions on the audit)*/
	FOR r IN (
		SELECT sa.audit_sid
		  FROM chain.supplier_audit sa
		  JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_CHANGE_PERMISSIONS)) sec_tbl ON sec_tbl.sid_id = sa.audit_sid
		 WHERE sa.app_sid = security_pkg.getApp
		   AND sa.auditor_company_sid = in_auditor_company_sid
		   AND sa.supplier_company_sid	= in_supplier_company_sid		
	)
	LOOP
		IF in_action = REVOKE_ACTION THEN
			acl_pkg.RemoveACEsForSid(security_pkg.GetAct, acl_pkg.GetDACLIDForSID(r.audit_sid), v_auditor_users_sid);
		ELSIF in_action = REGRANT_ACTION THEN 
			acl_pkg.AddACE(security_pkg.GetAct, acl_pkg.GetDACLIDForSID(r.audit_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_auditor_users_sid, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		END IF;
	END LOOP;
END;

/* Search for companies that can be audited based on the "Create supplier audit on behalf of" capability */
PROCEDURE SearchPermissibleAuditees(
	in_search_term  				IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_chain_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_perm_cts				T_PERMISSIBLE_TYPES_TABLE;
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN

	--todo: maybe needless as v_permissible_table would be empty in that case, but just to be clear
	IF v_chain_company_sid <> chain.helper_pkg.GetTopCompanySid THEN
		RAISE_APPLICATION_ERROR(-20001, 'SearchPermissibleAuditees can be run only when the logged chain company is the top company');
	END IF;
	
	v_perm_cts := type_capability_pkg.GetPermissibleCompanyTypes(v_chain_company_sid, chain_pkg.CREATE_SUPPL_AUDIT_ON_BEHLF_OF);
	
	SELECT company_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT DISTINCT c.company_sid
		  FROM company c
		  JOIN TABLE(v_perm_cts) pt ON c.company_type_id = pt.tertiary_company_type_id
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND (LOWER(c.name) LIKE v_search
			OR	(SELECT COUNT(*) 
				   FROM company_reference compref
				  WHERE compref.app_sid = c.app_sid
					AND compref.company_sid = c.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			)
		   AND c.active = chain_pkg.ACTIVE
		   AND c.deleted <> chain_pkg.DELETED
		);	 
	
	company_pkg.CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);		

END;

/* Search for companies that can be the supplier's auditor based on the supplier_relationship and "Create supplier audit on behalf of" capability */
PROCEDURE SearchPermissibleAuditors(
	in_supplier_company_sid			IN security_pkg.T_SID_ID,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_permissible_table		security.T_SID_TABLE; --permissible companies for CREATE_SUPPL_AUDIT_ON_BEHLF_OF
	v_reltnshp_perms_tbl	security.T_SID_TABLE; --permissible companies for ADD_REMOVE_RELATIONSHIPS
	v_supplier_ct_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
BEGIN
	-- Get company sids (auditors) we can create an audit on behalf of
	v_permissible_table := type_capability_pkg.GetPermCompanySidsByTypes(chain_pkg.CREATE_SUPPL_AUDIT_ON_BEHLF_OF, NULL, v_supplier_ct_id);
	
	-- Get company sids (auditors) we can create relationships on
	v_reltnshp_perms_tbl := type_capability_pkg.GetPermCompanySidsByTypes(chain_pkg.ADD_REMOVE_RELATIONSHIPS, NULL, v_supplier_ct_id);
	
	-- Return companies that we can create audits on behalf of the passed in supplier
	-- We either need the capability to create a relationship between the two, or for a 
	-- relationship to exist already
	OPEN out_result_cur FOR
		SELECT DISTINCT c.company_sid, c.name, cnt.country country_name
		  FROM company c
		  JOIN postcode.country cnt ON cnt.country = c.country_code
		  JOIN TABLE(v_permissible_table) pt ON c.company_sid = pt.column_value
		  LEFT JOIN supplier_relationship sr
		    ON c.company_sid = sr.purchaser_company_sid
		   AND in_supplier_company_sid = sr.supplier_company_sid
		   AND sr.active = chain_pkg.ACTIVE
		   AND sr.deleted <> chain_pkg.DELETED
		  LEFT JOIN TABLE(v_reltnshp_perms_tbl) rpt ON c.company_sid = rpt.column_value
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.active = chain_pkg.ACTIVE
		   AND (sr.supplier_company_sid IS NOT NULL OR rpt.column_value IS NOT NULL)
		 ORDER BY LOWER(c.name);

END;

/* Get the audits of a supplier and/or auditor joined with the permission table on the audit sid*/
PROCEDURE GetAudits(
	in_auditor_company_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_supplier_company_sid 	IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur					    OUT security_pkg.T_OUTPUT_CUR	
)
AS
	--top company can search against all auditors
	v_auditor_company_sid 	security_pkg.T_SID_ID := NVL(in_auditor_company_sid, CASE helper_pkg.IsTopCompany WHEN 1 THEN NULL ELSE SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')END);
	v_audits_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
BEGIN
	
	IF in_supplier_company_sid IS NOT NULL THEN
		IF NOT type_capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.VIEW_SUPPLIER_AUDITS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing the audits of the supplier with sid:' || in_supplier_company_sid);
		END IF;
	END IF;
	--TODO: permissions when the supplier_company_sid is null

	OPEN out_cur FOR
		SELECT sa.audit_sid, sa.auditor_company_sid, ac.name auditor_company_name, sa.supplier_company_sid, sc.name supplier_company_name,			
			sa.created_by_company_sid, cbc.name created_by_company_name, a.audit_type_label, a.created_dtm, a.label audit_label,
			a.survey_completed survey_completed_dtm, a.open_non_compliances
		  FROM chain.supplier_audit sa
		  JOIN csr.v$audit a ON sa.audit_sid = a.internal_audit_sid
		  JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_READ)) sec_tbl ON sec_tbl.sid_id = a.internal_audit_sid
		  JOIN chain.company ac ON sa.auditor_company_sid = ac.company_sid
		  JOIN chain.company sc ON sa.supplier_company_sid = sc.company_sid
		  JOIN chain.company cbc ON sa.created_by_company_sid = cbc.company_sid
		 WHERE sa.app_sid = security_pkg.GetApp
		   AND (v_auditor_company_sid IS NULL OR sa.auditor_company_sid = v_auditor_company_sid)
		   AND (in_supplier_company_sid IS NULL OR sa.supplier_company_sid = in_supplier_company_sid);	

END;

/* Procedure that wraps saving internal audits for suppliers*/
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
)
AS
BEGIN
	csr.audit_pkg.Save(
		in_sid_id					=> in_audit_sid,
		in_audit_ref				=> NULL,
		in_survey_sid				=> in_survey_sid, 
		in_region_sid				=> NULL,
		in_label					=> in_label,
		in_audit_dtm				=> in_audit_dtm,
		in_auditor_user_sid			=> in_auditor_user_sid,
		in_notes					=> in_notes,
		in_internal_audit_type		=> in_internal_audit_type,
		in_auditor_name				=> NULL,
		in_auditor_org				=> NULL,
		in_response_to_audit		=> NULL,
		in_created_by_sid			=> NULL,
		in_auditee_user_sid			=> NULL,
		in_auditee_company_sid		=> in_supplier_company_sid,
		in_auditor_company_sid		=> in_auditor_company_sid,
		in_created_by_company_sid	=> NULL,
		in_permit_id				=> NULL,
		out_sid_id					=> out_sid_id
	);
END;

END supplier_audit_pkg;
/
