CREATE OR REPLACE PACKAGE CSR.saml_pkg AS

/**
 * Called when a SAML request begins to get a request id to use to tie log entries together.
 *
 * @param in_saml_assertion			The raw SAML assertion
 * @param out_saml_request_id		The SAML request id
 */
PROCEDURE BeginRequest(
	in_app_sid						IN	customer.app_sid%TYPE,
	out_saml_request_id				OUT	NUMBER
);

/**
 * Called when a SAML request begins to get a request id to use to tie log entries together.
 * Also logs the raw SAML data in case it's needed.
 *
 * @param in_saml_assertion			The raw SAML assertion
 * @param out_saml_request_id		The SAML request id
 */
PROCEDURE BeginRequest(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_assertion				IN	saml_assertion_log.saml_assertion%TYPE,
	out_saml_request_id				OUT	NUMBER
);

/**
 * Logs the raw SAML data in case it's needed. Repeated calls overwrite the log entry for that request ID.
 * Not needed if the assertion was logged via BeginRequest.
 *
 * @param in_saml_request_id		The request id issued by BeginRequest
 * @param in_saml_assertion			The raw SAML assertion
 */
PROCEDURE LogAssertion(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_request_id				IN	saml_log.saml_request_id%TYPE,
	in_saml_assertion				IN	saml_assertion_log.saml_assertion%TYPE
);

/**
 * Logs a message relating to a SAML request
 *
 * @param in_saml_request_id		The request id issued by BeginRequest
 * @param in_message_sequence		The message sequence number (incremented per message)
 * @param in_message				The message to log
 */
PROCEDURE LogMessage(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_request_id				IN	saml_log.saml_request_id%TYPE,
	in_message_sequence				IN	saml_log.message_sequence%TYPE,
	in_message						IN	saml_log.message%TYPE
);

/**
 * Cache a SAML assertion id to prevent later re-use
 *
 * @param in_assertion_id			The SAML assertion id
 * @param in_expires				The expiry time of the cache entry
 * @param out_already_used			A flag which says if the SAML assertion has already been used
 */
PROCEDURE CacheAssertion(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_assertion_id					IN	saml_assertion_cache.assertion_id%TYPE,
	in_expires						IN	saml_assertion_cache.expires%TYPE,
	out_already_used				OUT	NUMBER
);

PROCEDURE CheckDefSsoUserPermitted (
	in_default_logon_user_sid	security_pkg.T_SID_ID	
);

PROCEDURE GetDefSsoUserInfo (
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserSIDFromUserName(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	out_user_sid					OUT	csr_user.csr_user_sid%TYPE
);

/**
 * Query whether SSO is permitted for this user
 *
 * @param in_user_name				The user name from
 * @param out_result				0 for false; 1 for true
 */
PROCEDURE IsLogonAsUserAllowed(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	out_result						OUT	BINARY_INTEGER
);

/**
 * Log on an user after they have been authenticated by SAML
 *
 * @param in_user_name				The user name from the SAML assertion
 * @param in_host					The host that received the request (used to set the act timeout)
 * @param out_act					The issued access token
 */
PROCEDURE LogonUser(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	in_host							IN	security.website.website_name%TYPE,
	out_act							OUT	security_pkg.T_ACT_ID
);

PROCEDURE LogonUser(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_sid						IN	csr_user.csr_user_sid%TYPE,
	in_host							IN	security.website.website_name%TYPE,
	out_act							OUT	security_pkg.T_ACT_ID
);

/**
 * Called from an oracle scheduler job to remove old expired entries
 */
PROCEDURE CleanAssertionCache;

/**
 * Called from an oracle scheduler job to remove old log entries
 */
PROCEDURE CleanRequestLog;

/**
 * Validate the provided message and hash given the secret key stored in the database.
 *
 * @param in_message				The message that has been signed
 * @param in_hash					The signature
 * @param out_expected_hash			NULL if the given signature is valid for the given message, otherwise what the signature should have been
 */
PROCEDURE ValidateHMAC(
	in_message				RAW,
	in_hash					RAW,
	out_expected_hash	OUT	RAW
);

PROCEDURE GetCertificates(
	in_app_sid		IN	customer.app_sid%TYPE,
	out_certs_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSsoConfig(
	in_app_sid		IN	customer.app_sid%TYPE,
	out_config_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_certs_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddSigningCert(
	in_cert			IN	customer_saml_sso_cert.public_signing_cert%TYPE,
	out_cert_id		OUT	customer_saml_sso_cert.sso_cert_id%TYPE
);

PROCEDURE AddSigningCert(
	in_cache_key		IN	VARCHAR2,
	out_cert_id			OUT	customer_saml_sso_cert.sso_cert_id%TYPE
);

PROCEDURE DeleteSigningCert(
	in_sso_cert_id	IN	customer_saml_sso_cert.sso_cert_id%TYPE
);

PROCEDURE SetSsoConfig(
	in_idp_url						IN customer_saml_sso.idp_url%TYPE,
	in_sign_auth_request			IN customer_saml_sso.sign_auth_request%TYPE,
	in_signed_response_req			IN customer_saml_sso.signed_response_req%TYPE,
	in_use_name_id					IN customer_saml_sso.use_name_id%TYPE,
	in_name_attribute				IN customer_saml_sso.name_attribute%TYPE,
	in_full_name_attribute			IN customer_saml_sso.full_name_attribute%TYPE,
	in_first_name_attribute			IN customer_saml_sso.first_name_attribute%TYPE,
	in_last_name_attribute			IN customer_saml_sso.last_name_attribute%TYPE,
	in_email_attribute				IN customer_saml_sso.email_attribute%TYPE,
	in_logout_redirect_url			IN customer_saml_sso.logout_redirect_url%TYPE,
	in_consumer_url					IN customer_saml_sso.consumer_url%TYPE,
	in_use_http_redirect			IN customer_saml_sso.use_http_redirect%TYPE,
	in_show_sso_option_login		IN customer_saml_sso.show_sso_option_login%TYPE,
	in_use_default_user_acc			IN customer_saml_sso.use_default_user_acc%TYPE,
	in_use_basic_user_mgmt			IN customer_saml_sso.use_basic_user_management%TYPE,
	in_use_first_last_name_attrs	IN customer_saml_sso.use_first_last_name_attrs%TYPE
);

PROCEDURE GetLogEntries(
	in_start_row					IN  NUMBER,
	in_end_row					  	IN  NUMBER,
	in_search_string				IN  VARCHAR2,
	in_order_by					 	IN  VARCHAR2,
	in_order_dir					IN  VARCHAR2,
	out_total_rows				  	OUT NUMBER,
	out_logs_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetLoginRedirectURLById(
	in_redirect_url_id			  	IN NUMBER
);

PROCEDURE GetAllowedLoginRedirectURLs(
	out_cur						 	OUT SYS_REFCURSOR
);

PROCEDURE GetLoginRedirectURLId(
	out_url_id					  	OUT NUMBER
);

END;
/
