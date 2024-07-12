CREATE OR REPLACE PACKAGE BODY chain.integration_pkg
IS

FUNCTION AmforiRequestExists(
	in_reference_id		IN VARCHAR2,
	in_tenant_id		IN VARCHAR2,
	in_data_type		IN VARCHAR2
) RETURN BOOLEAN
AS
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM integration_request r
	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND r.tenant_id = in_tenant_id
	   AND UPPER(r.data_type) = in_data_type
	   AND r.data_id = in_reference_id;

	IF v_count > 0 THEN 
		RETURN TRUE;
	END IF;

	RETURN FALSE;
END;
  
PROCEDURE GetAmforiRequest(
	in_company_sid 					IN security.security_pkg.T_SID_ID,
	in_data_type					IN VARCHAR2,
	in_lookup_key					IN VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tenant_id			VARCHAR2(64) := NULL;
	v_reference_id		chain.reference.reference_id%TYPE;
	v_company_reference_value	VARCHAR2(64) := NULL;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '|| in_company_sid);
	END IF;
	
	BEGIN
		SELECT tenant_id
		  INTO v_tenant_id
		  FROM security.tenant
		 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_tenant_id IS NULL OR LENGTH(v_tenant_id) = 0 THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_NO_TENANT, 'No Tenant Id for app '|| SYS_CONTEXT('SECURITY', 'APP'));
	END IF;
	
	BEGIN
		SELECT reference_id
		  INTO v_reference_id
		  FROM chain.reference
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND UPPER(lookup_key) = in_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_reference_id IS NULL OR v_reference_id <= 0 THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_NO_LOOKUP_KEY, 'No Reference for lookup key '||in_lookup_key||' in app '|| SYS_CONTEXT('SECURITY', 'APP'));
	END IF;

	BEGIN
		SELECT value
		  INTO v_company_reference_value
		  FROM chain.company_reference
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND reference_id = v_reference_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_company_reference_value IS NULL OR LENGTH(v_company_reference_value) = 0 THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_NO_SITE_ID, 'No Company Reference for lookup key '||in_lookup_key||' in app '|| SYS_CONTEXT('SECURITY', 'APP'));
	END IF;

	IF NOT AmforiRequestExists(v_company_reference_value, v_tenant_id, in_data_type)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Unknown Id '|| v_company_reference_value);
	END IF;
	
	OPEN out_cur FOR
		SELECT 
			in_company_sid company_sid,
			v_company_reference_value integration_id,
			r.last_updated_dtm,
			r.request_verb,
			r.request_json
		  FROM integration_request r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.tenant_id = v_tenant_id
		   AND UPPER(r.data_type) = in_data_type
		   AND r.data_id = v_company_reference_value
		ORDER BY last_updated_dtm desc
		 ;
END;

PROCEDURE GetIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, tenant_id, data_type, data_id, request_url, request_verb, last_updated_dtm,
			last_updated_message, request_json
		  FROM integration_request
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tenant_id = in_tenant_id
		   AND data_type = in_data_type
		   AND data_id = in_data_id;
END;

-- UNSEC only called from Chain Integration Message Listener
PROCEDURE UNSEC_CreateIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	in_request_url					IN	integration_request.request_url%TYPE,
	in_request_verb					IN	integration_request.request_verb%TYPE,
	in_last_updated_dtm				IN	integration_request.last_updated_dtm%TYPE,
	in_last_updated_message			IN	integration_request.last_updated_message%TYPE,
	in_request_json					IN	integration_request.request_json%TYPE,
	in_correlation_id				IN	integration_request.correlation_id%TYPE
)
AS
BEGIN
	INSERT INTO integration_request (
		app_sid,
		tenant_id,
		data_type,
		data_id,
		request_url,
		request_verb,
		last_updated_dtm,
		last_updated_message,
		request_json,
		correlation_id
	) VALUES (
		SYS_CONTEXT('SECURITY', 'APP'),
		in_tenant_id,
		in_data_type,
		in_data_id,
		in_request_url,
		in_request_verb,
		in_last_updated_dtm,
		NVL(in_last_updated_message, 'Created on ' || SYSDATE),
		in_request_json,
		in_correlation_id
	);
END;

-- UNSEC only called from Chain Integration Message Listener
PROCEDURE UNSEC_UpdateIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	in_request_url					IN	integration_request.request_url%TYPE,
	in_request_verb					IN	integration_request.request_verb%TYPE,
	in_last_updated_dtm				IN	integration_request.last_updated_dtm%TYPE,
	in_last_updated_message			IN	integration_request.last_updated_message%TYPE,
	in_request_json					IN	integration_request.request_json%TYPE,
	in_correlation_id				IN	integration_request.correlation_id%TYPE
)
AS
BEGIN
	UPDATE integration_request
	   SET request_url = in_request_url,
		request_verb = in_request_verb,
		last_updated_dtm = in_last_updated_dtm,
		last_updated_message = NVL(in_last_updated_message, 'Updated on ' || SYSDATE),
		request_json = in_request_json,
		correlation_id = in_correlation_id
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  AND tenant_id = in_tenant_id
	  AND data_type = in_data_type
	  AND data_id = in_data_id;
END;

PROCEDURE UNSEC_DeleteIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	in_request_url					IN	integration_request.request_url%TYPE,
	in_last_updated_dtm				IN	integration_request.last_updated_dtm%TYPE,
	in_last_updated_message			IN	integration_request.last_updated_message%TYPE,
	in_correlation_id				IN	integration_request.correlation_id%TYPE
)
AS
BEGIN
	UPDATE integration_request
	   SET request_url = in_request_url,request_verb = 'DELETE',last_updated_dtm = in_last_updated_dtm,
		   last_updated_message = NVL(in_last_updated_message, 'Updated on ' || SYSDATE),
		   correlation_id = in_correlation_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tenant_id = in_tenant_id
	   AND data_type = in_data_type
	   AND data_id = in_data_id;
END;

END integration_pkg;
/
