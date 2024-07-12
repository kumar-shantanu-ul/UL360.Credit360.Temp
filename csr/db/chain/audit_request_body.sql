CREATE OR REPLACE PACKAGE BODY CHAIN.audit_request_pkg
IS

PROCEDURE CreateAuditRequest(
	in_auditor_company_sid			IN	audit_request.auditor_company_sid%TYPE,
	in_auditee_company_sid			IN	audit_request.auditee_company_sid%TYPE,
	in_notes						IN	audit_request.notes%TYPE,
	in_proposed_dtm					IN	audit_request.proposed_dtm%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_requested_by_company_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_audit_request_id				audit_request.audit_request_id%TYPE;
	v_msg							message%ROWTYPE;
BEGIN

	IF NOT type_capability_pkg.CheckCapability(v_requested_by_company_sid, in_auditor_company_sid, chain_pkg.CREATE_AUDIT_REQUESTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to company with sid:' || v_requested_by_company_sid || ' creating an audit request for the auditor with sid:' || in_auditor_company_sid);
	END IF;
	
	-- EstablishRelationship checks for the ADD_REMOVE_RELATIONSHIPS capability, which we don't want to grant
	-- Start/Activate doesn't, and therefore probably should be private, but they aren't.
	chain.company_pkg.StartRelationship(
		in_purchaser_company_sid		=> in_auditor_company_sid,
		in_supplier_company_sid			=> in_auditee_company_sid
	);
	chain.company_pkg.ActivateRelationship(in_auditor_company_sid, in_auditee_company_sid);

	INSERT INTO audit_request (
		audit_request_id,
		auditor_company_sid,
		auditee_company_sid,
		notes,
		proposed_dtm
	) VALUES (
		audit_request_id_seq.NEXTVAL,
		in_auditor_company_sid,
		in_auditee_company_sid,
		in_notes,
		in_proposed_dtm
	) RETURNING audit_request_id INTO v_audit_request_id;

	-- enqueue an alert for everyone in the auditor company
	INSERT INTO audit_request_alert (audit_request_id, user_sid)
		 SELECT v_audit_request_id audit_request_id, user_sid
		   FROM v$company_member
		  WHERE company_sid = in_auditor_company_sid;

    -- send a chain message to everyone in the auditor company
	message_pkg.TriggerMessage(
		in_primary_lookup           => chain_pkg.AUDIT_REQUEST_CREATED,
		in_to_company_sid           => in_auditor_company_sid,
		in_re_company_sid           => v_requested_by_company_sid,
		in_re_user_sid				=> SYS_CONTEXT('SECURITY', 'SID'),
		in_re_secondary_company_sid => in_auditee_company_sid,
		in_due_dtm					=> in_proposed_dtm,
		in_re_audit_request_id		=> v_audit_request_id
	);

	chain_link_pkg.AuditRequested(
		in_auditor_company_sid => in_auditor_company_sid,
		in_auditee_company_sid => in_auditee_company_sid,
		in_requested_by_company_sid => v_requested_by_company_sid,
		in_audit_request_id => v_audit_request_id
	);
	
	v_msg := chain.message_pkg.FindMessage (
		in_primary_lookup			=> chain.chain_pkg.AUDIT_REQUEST_REQUIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> chain.helper_pkg.GetTopCompanySid,
		in_re_company_sid			=> in_auditee_company_sid,
		in_completed				=> FALSE
	);
	
	chain.message_pkg.CompleteMessageIfExists (
		in_primary_lookup			=> chain.chain_pkg.AUDIT_REQUEST_REQUIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> chain.helper_pkg.GetTopCompanySid,
		in_re_company_sid			=> in_auditee_company_sid
	);
	
	UPDATE message
	   SET re_secondary_company_sid = in_auditor_company_sid,
		   re_audit_request_id = v_audit_request_id
	 WHERE message_id = v_msg.message_id;
	
	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label
		  FROM v$audit_request
		 WHERE audit_request_id = v_audit_request_id;
END;

PROCEDURE GetAuditRequest(
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN

	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label
		  FROM v$audit_request
		 WHERE audit_request_id = in_audit_request_id
		   AND auditor_company_sid = v_company_sid
		    OR auditee_company_sid = v_company_sid
			OR requested_by_company_sid = v_company_sid;

END;

PROCEDURE CreateRequestedAudit(
	in_audit_request_id				IN	audit_request.audit_request_id%TYPE,
	in_label						IN	csr.internal_audit.label%TYPE,
	in_auditor_user_sid				IN	security_pkg.T_SID_ID,
	in_audit_dtm					IN	csr.internal_audit.audit_dtm%TYPE,
	in_notes						IN	csr.internal_audit.notes%TYPE,
	in_internal_audit_type			IN	csr.internal_audit.internal_audit_type_id%TYPE,
	out_audit_sid					OUT	security_pkg.T_SID_ID
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	v_audit_sid						security_pkg.T_SID_ID;
	v_auditor_company_sid			security_pkg.T_SID_ID;
	v_auditee_company_sid			security_pkg.T_SID_ID;
	v_requested_by_user_sid			security_pkg.T_SID_ID;
	v_requested_by_company_sid		security_pkg.T_SID_ID;
	
	v_survey_sid					security_pkg.T_SID_ID;
	v_created_by_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN

	SELECT auditor_company_sid, auditee_company_sid,
		   requested_by_user_sid, requested_by_company_sid, audit_sid
	  INTO v_auditor_company_sid, v_auditee_company_sid,
		   v_requested_by_user_sid, v_requested_by_company_sid, v_audit_sid
	  FROM audit_request
	 WHERE audit_request_id = in_audit_request_id;

	IF v_auditor_company_sid <> v_company_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only the auditor company may set the audit');
	END IF;

	IF v_audit_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'The audit request with ID ' || in_audit_request_id || ' already has an audit.');
	END IF;
	
	SELECT default_survey_sid
	  INTO v_survey_sid
	  FROM csr.internal_audit_type
	 WHERE internal_audit_type_id = in_internal_audit_type;
	
	BEGIN
		chain.helper_pkg.LogonUCD(v_company_sid);
		
		csr.audit_pkg.Save(
			in_sid_id		=> NULL,
			in_audit_ref	=> NULL,
			in_survey_sid 	=> v_survey_sid, 
			in_region_sid   => csr.supplier_pkg.GetRegionSid(v_auditee_company_sid),
			in_label		=> in_label,
			in_audit_dtm	=> in_audit_dtm,
			in_auditor_user_sid => in_auditor_user_sid,
			in_notes		=> in_notes,
			in_internal_audit_type => in_internal_audit_type,
			in_auditor_name => NULL,
			in_auditor_org 	=> company_pkg.GetCompanyName(v_auditor_company_sid),
			in_created_by_sid => v_created_by_sid,
			out_sid_id		=> out_audit_sid
		);
		
		-- set the auditor company sid
		csr.audit_pkg.SetAuditorCompanySid(out_audit_sid, v_auditor_company_sid);
		
		--keep a log of the internal audit in chain
		INSERT INTO supplier_audit (audit_sid, auditor_company_sid, supplier_company_sid, created_by_company_sid)
			VALUES(out_audit_sid, v_auditor_company_sid, v_auditee_company_sid, v_company_sid);
		
		--Add Read/write permission for auditor users group
		acl_pkg.AddACE(security_pkg.GetAct, acl_pkg.GetDACLIDForSID(out_audit_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, v_auditor_company_sid, chain_pkg.USER_GROUP), security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
		
		helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;

			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;

	UPDATE audit_request
	   SET audit_sid = out_audit_sid
	 WHERE audit_request_id = in_audit_request_id;

	message_pkg.CompleteMessage(
		in_primary_lookup           => chain_pkg.AUDIT_REQUEST_CREATED,
		in_to_company_sid           => v_auditor_company_sid,
		in_re_company_sid           => v_requested_by_company_sid,
		in_re_user_sid				=> v_requested_by_user_sid,
		in_re_secondary_company_sid => v_auditee_company_sid,
		in_re_audit_request_id		=> in_audit_request_id
	);
	 
	chain_link_pkg.AuditRequestAuditSet(
		in_audit_request_id => in_audit_request_id,
		in_auditor_company_sid => v_auditor_company_sid,
		in_auditee_company_sid => v_auditee_company_sid,
		in_audit_sid => out_audit_sid
	);

END;

PROCEDURE GetOpenAuditRequestsByAuditor(
	in_auditor_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN

	IF v_company_sid <> in_auditor_company_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only the auditor company may view these audit requests');
	END IF;

	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label
		  FROM v$audit_request
		 WHERE auditor_company_sid = in_auditor_company_sid
		   AND audit_closure_type_id IS NULL
		 ORDER BY proposed_dtm, audit_request_id;

END;

PROCEDURE GetOpenAuditRequestsByAuditee(
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN

	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label
		  FROM v$audit_request
		 WHERE auditee_company_sid = in_auditee_company_sid
		   AND requested_by_company_sid = v_company_sid
		   AND audit_closure_type_id IS NULL
		 ORDER BY audit_request_id;

END;

PROCEDURE GetOpenAuditRequests(
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_user_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_sid					security_pkg.T_SID_ID := NVL(in_company_sid, v_user_company_sid);
	v_table							security.T_SID_TABLE := csr.audit_pkg.GetAuditsForUserAsTable;
BEGIN

	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label,
			   CASE WHEN so.column_value IS NULL THEN 0 ELSE 1 END user_can_see_audit
		  FROM v$audit_request ar
		  LEFT JOIN TABLE(v_table) so ON ar.audit_sid = so.column_value
		 WHERE (
				( -- either we aren't looking an a specific company, so show all requests logged in user has access to
					v_company_sid = v_user_company_sid 
					AND (auditee_company_sid = v_user_company_sid 
					 OR auditor_company_sid = v_user_company_sid 
					 OR requested_by_company_sid = v_user_company_sid)
				)
				OR ( -- or we are, in which case show audit requests for that company that the logged in users' company created
					v_company_sid != v_user_company_sid 
					AND (auditee_company_sid = v_company_sid OR auditor_company_sid = v_company_sid) 
					AND requested_by_company_sid = v_user_company_sid
			   )
		   )
		   AND audit_closure_type_id IS NULL
		 ORDER BY audit_request_id;

END;

PROCEDURE GetAvailableAuditorsForAuditee(
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_create_audit_cap_id			capability.capability_id%TYPE := capability_pkg.GetCapabilityId(chain_pkg.CT_SUPPLIERS, chain_pkg.CREATE_SUPPLIER_AUDITS);
	v_request_audit_cap_id			capability.capability_id%TYPE := capability_pkg.GetCapabilityId(chain_pkg.CT_SUPPLIERS, chain_pkg.CREATE_AUDIT_REQUESTS);
	v_auditee_company_type_id		company.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_auditee_company_sid);
	v_my_company_type_id			company.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId;
	v_relationship_count			NUMBER;
	v_permissible_auditors			security.T_SID_TABLE DEFAULT type_capability_pkg.GetPermissibleCompanySids(chain_pkg.CREATE_AUDIT_REQUESTS);
BEGIN
	
	-- check we have a relationship to the company we're requesting for
	SELECT COUNT(*)
	  INTO v_relationship_count
	  FROM v$supplier_relationship
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_auditee_company_sid;
	
	-- Get companies that I can request to perform an audit, and they can create a supplier audit
	-- todo: query only checks whether the capability row exists but not the permission set
	OPEN out_cur FOR
		SELECT ac.*, cou.name country_name
		  FROM chain.company ac
		  JOIN chain.v$supplier_relationship sr ON ac.company_sid = sr.supplier_company_sid AND ac.app_sid = sr.app_sid
		  JOIN postcode.country cou on ac.country_code = cou.country
		  JOIN TABLE(v_permissible_auditors) pa ON ac.company_sid = pa.column_value --filter by permissible auditors
		 WHERE v_relationship_count > 0
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (ac.app_sid, ac.company_type_id) IN (
			SELECT ctc_request.app_sid, ctc_request.secondary_company_type_id
			  FROM company_type_capability ctc_request 
			  JOIN company_type_capability ctc_create 
				ON ctc_create.primary_company_type_id = ctc_request.secondary_company_type_id			  
			 WHERE ctc_request.capability_id = v_request_audit_cap_id 
			   AND ctc_request.primary_company_type_id = v_my_company_type_id -- i can request
			   AND ctc_create.capability_id = v_create_audit_cap_id 
			   AND ctc_create.secondary_company_type_id = v_auditee_company_type_id -- auditor can create
			   AND ROWNUM > 0 -- fully materialize, most of the time this is empty but sometimes it isn't
			);
END;

PROCEDURE SearchPermissibleAuditees(
	in_search_term  				IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results						security.T_SID_TABLE := security.T_SID_TABLE();
	v_create_audit_cap_id			capability.capability_id%TYPE := capability_pkg.GetCapabilityId(chain_pkg.CT_SUPPLIERS, chain_pkg.CREATE_SUPPLIER_AUDITS);
	v_request_audit_cap_id			capability.capability_id%TYPE := capability_pkg.GetCapabilityId(chain_pkg.CT_SUPPLIERS, chain_pkg.CREATE_AUDIT_REQUESTS);
BEGIN
	
	SELECT company_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT cee.company_sid
		  FROM v$company c
		  JOIN v$supplier_relationship sor ON sor.purchaser_company_sid = c.company_sid
		  JOIN v$company cor ON sor.supplier_company_sid = cor.company_sid
		  JOIN company_type_capability ctc_request 
		    ON ctc_request.capability_id = v_request_audit_cap_id 
		   AND ctc_request.primary_company_type_id = c.company_type_id 
		   AND ctc_request.secondary_company_type_id = cor.company_type_id -- I can request
		  JOIN v$supplier_relationship see ON see.purchaser_company_sid = c.company_sid
		  JOIN v$company cee  ON see.supplier_company_sid = cee.company_sid
		  JOIN company_type_capability ctc_create --where do we check against the permission set? 
		    ON ctc_create.capability_id = v_create_audit_cap_id 
		   AND ctc_create.primary_company_type_id = cor.company_type_id 
		   AND ctc_create.secondary_company_type_id = cee.company_type_id -- auditor can create
		 WHERE c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (LOWER(cee.name) LIKE v_search
			OR	(SELECT COUNT(*) 
				   FROM company_reference compref
				  WHERE compref.app_sid = cee.app_sid
					AND compref.company_sid = cee.company_sid
					AND	LOWER(compref.value) = LOWER(TRIM(in_search_term))) > 0
			)
		 GROUP BY cee.company_sid
	);
	
	company_pkg.CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);		

END;

PROCEDURE GetHistoricAuditRequests(
	in_auditor_company_sid			IN	security_pkg.T_SID_ID,
	in_auditee_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN

	IF v_company_sid <> in_auditor_company_sid THEN
		RAISE_APPLICATION_ERROR(-20001, 'Only the auditor company may view these audit requests');
	END IF;

	OPEN out_cur FOR
		SELECT audit_request_id, notes, proposed_dtm,
			   auditor_company_sid, auditor_company_name, auditee_company_sid, auditee_company_name,
			   requested_by_company_sid, requested_by_company_name, requested_by_user_sid,
			   requested_by_user_full_name, requested_by_user_email, requested_at_dtm,
			   audit_sid, audit_label, audit_dtm, audit_closure_type_id, audit_closure_type_label
		  FROM v$audit_request
		 WHERE auditor_company_sid = in_auditor_company_sid
		   AND auditee_company_sid = in_auditee_company_sid
		   AND audit_closure_type_id IS NOT NULL
		 ORDER BY audit_dtm, audit_request_id;

END;

PROCEDURE GetRequestedAlertApps(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM audit_request_alert
		 WHERE sent_dtm IS NULL;

END;

PROCEDURE GetRequestedAlertData(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT ar.audit_request_id, ara.user_sid to_user_sid,
			   ar.auditor_company_name, ar.auditee_company_name, ar.requested_by_company_name,
			   ar.requested_by_user_full_name, ar.req_by_user_friendly_name, ar.requested_by_user_email
		  FROM v$audit_request ar
		  JOIN audit_request_alert ara ON ara.app_sid = ar.app_sid AND ara.audit_request_id = ar.audit_request_id
		 WHERE ara.sent_dtm IS NULL
	  ORDER BY ar.requested_at_dtm;

END;

PROCEDURE RecordRequestedAlertSent(
	in_audit_request_id				IN audit_request.audit_request_id%TYPE,
	in_user_sid						IN security_pkg.T_SID_ID
)
AS
BEGIN

	UPDATE audit_request_alert
	   SET sent_dtm = SYSDATE
	 WHERE audit_request_id = in_audit_request_id
	   AND user_sid = in_user_sid;

END;

END audit_request_pkg;
/
