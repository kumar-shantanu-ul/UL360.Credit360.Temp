CREATE OR REPLACE PACKAGE chain.integration_pkg
IS

PROCEDURE GetAmforiRequest(
	in_company_sid 					IN security.security_pkg.T_SID_ID,
	in_data_type					IN VARCHAR2,
	in_lookup_key					IN VARCHAR2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

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
);

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
);

PROCEDURE UNSEC_DeleteIntegrationRequest (
	in_tenant_id					IN	integration_request.tenant_id%TYPE,
	in_data_type					IN  integration_request.data_type%TYPE,
	in_data_id						IN  integration_request.data_id%TYPE,
	in_request_url					IN	integration_request.request_url%TYPE,
	in_last_updated_dtm				IN	integration_request.last_updated_dtm%TYPE,
	in_last_updated_message			IN	integration_request.last_updated_message%TYPE,
	in_correlation_id				IN	integration_request.correlation_id%TYPE
);

END integration_pkg;
/
