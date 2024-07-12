CREATE OR REPLACE PACKAGE BODY CSR.saml_pkg AS

PROCEDURE InitializeLog(
	in_app_sid						IN	customer.app_sid%TYPE,
	out_saml_request_id				OUT	NUMBER
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	INSERT INTO saml_assertion_log
		(app_sid, saml_request_id)
	VALUES
		(in_app_sid, saml_request_id_seq.nextval)
	RETURNING
		saml_request_id INTO out_saml_request_id;
	COMMIT;
END;

-- There is no security in this package because it is used to authenticate users
PROCEDURE BeginRequest(
	in_app_sid						IN	customer.app_sid%TYPE,
	out_saml_request_id				OUT	NUMBER
)
AS
BEGIN
	InitializeLog(in_app_sid, out_saml_request_id);
END;

PROCEDURE BeginRequest(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_assertion				IN	saml_assertion_log.saml_assertion%TYPE,
	out_saml_request_id				OUT	NUMBER
)
AS
BEGIN
	BeginRequest(in_app_sid, out_saml_request_id);
	LogAssertion(in_app_sid, out_saml_request_id, in_saml_assertion);
END;

PROCEDURE LogAssertion(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_request_id				IN	saml_log.saml_request_id%TYPE,
	in_saml_assertion				IN	saml_assertion_log.saml_assertion%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE saml_assertion_log
	   SET saml_assertion = in_saml_assertion
	 WHERE app_sid = in_app_sid AND saml_request_id = in_saml_request_id;
	COMMIT;
END;

PROCEDURE LogMessage(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_saml_request_id				IN	saml_log.saml_request_id%TYPE,
	in_message_sequence				IN	saml_log.message_sequence%TYPE,
	in_message						IN	saml_log.message%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	INSERT INTO saml_log
		(app_sid, saml_request_id, message_sequence, message)
	VALUES
		(in_app_sid, in_saml_request_id, in_message_sequence, in_message);
	COMMIT;
END;

PROCEDURE CacheAssertion(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_assertion_id					IN	saml_assertion_cache.assertion_id%TYPE,
	in_expires						IN	saml_assertion_cache.expires%TYPE,
	out_already_used				OUT	NUMBER
)
AS
BEGIN
	-- delete expired assertions
	DELETE FROM saml_assertion_cache
	 WHERE app_sid = in_app_sid
	   AND assertion_id = in_assertion_id
	   AND expires < SYSDATE;

	-- add the assertion, checking if it already exists
	BEGIN
		INSERT INTO saml_assertion_cache
			(app_sid, assertion_id, expires)
		VALUES
			(in_app_sid, in_assertion_id, in_expires);

		out_already_used := 0;
	EXCEPTION
		WHEN dup_val_on_index THEN
			out_already_used := 1;
	END;
END;

PROCEDURE CheckDefSsoUserPermitted (
	in_default_logon_user_sid	security_pkg.T_SID_ID	
)
AS
BEGIN
	IF in_default_logon_user_sid IS NULL THEN
		RETURN; -- doesn't have to be set
	END IF;

	-- in case someone has done something super stupid with a script - this covers some basics when they try and turn on where default account is set
	IF csr_user_pkg.IsSuperAdmin(in_default_logon_user_sid) = 1 OR in_default_logon_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot use BuiltinAdministrator or super admin account as default SSO user');
	END IF;	
END;

PROCEDURE GetDefSsoUserInfo (
	out_use_default_user_acc		OUT customer_saml_sso.use_default_user_acc%TYPE,
	out_default_logon_user_sid		OUT security_pkg.T_SID_ID,
	out_is_in_trash					OUT NUMBER,
	out_user_name					OUT csr_user.user_name%TYPE
) 
AS
BEGIN
	-- what's the configuration for using a default SSO account for users who don't have a matching account
	BEGIN
		SELECT css.use_default_user_acc, css.default_logon_user_sid, NVL2(t.trash_sid, 1, 0), cu.user_name
		  INTO out_use_default_user_acc, out_default_logon_user_sid, out_is_in_trash, out_user_name
		  FROM customer_saml_sso css
		  JOIN csr_user cu ON cu.csr_user_sid = css.default_logon_user_sid AND cu.app_sid = css.app_sid
		  LEFT JOIN trash t ON css.default_logon_user_sid = t.trash_sid
		 WHERE css.app_sid = security_pkg.getApp;
	EXCEPTION	
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE GetDefSsoUserInfo (
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_use_default_user_acc			customer_saml_sso.use_default_user_acc%TYPE;
	v_default_logon_user_sid		security_pkg.T_SID_ID;
	v_is_in_trash					NUMBER;
	v_user_name						csr_user.user_name%TYPE;
BEGIN
	GetDefSsoUserInfo(v_use_default_user_acc, v_default_logon_user_sid, v_is_in_trash, v_user_name);

	OPEN out_cur FOR	
		SELECT 
			v_use_default_user_acc use_default_user_acc,
			v_default_logon_user_sid default_logon_user_sid,
			v_user_name user_name,
			v_is_in_trash is_in_trash
		  FROM dual;
END;

PROCEDURE GetUserSIDFromUserName(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	out_user_sid					OUT	csr_user.csr_user_sid%TYPE
)
AS
	v_use_default_user_acc			customer_saml_sso.use_default_user_acc%TYPE;
	v_is_in_trash					NUMBER;
	v_user_name						csr_user.user_name%TYPE;
BEGIN
	-- IMPORTANT:
	-- It is essential this lookup *excludes* Super Admins as external
	-- systems should not be able to assert authority for any account
	-- other than a user on the site that SSO configured for.
	BEGIN
		SELECT cu.csr_user_sid
		  INTO out_user_sid
		  FROM csr_user cu
		  LEFT JOIN superadmin sa ON cu.csr_user_sid = sa.csr_user_sid
		  LEFT JOIN trash tr ON cu.app_sid = tr.app_sid AND cu.csr_user_sid = tr.trash_sid
		 WHERE cu.app_sid = in_app_sid
		   AND cu.hidden = 0
		   AND cu.csr_user_sid != 3 -- is not built in admin
		   AND sa.csr_user_sid IS NULL -- is not a super admin
		   AND tr.trash_sid IS NULL -- is not trashed
		   AND LOWER(cu.user_name) = LOWER(in_user_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- what's the configuration for using a default SSO account for users who don't have a matching account
			GetDefSsoUserInfo(v_use_default_user_acc, out_user_sid, v_is_in_trash, v_user_name);

			IF v_use_default_user_acc = 1 AND out_user_sid IS NOT NULL AND v_is_in_trash = 0 THEN
				
				CheckDefSsoUserPermitted(out_user_sid);
			ELSE
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The SAML username '||in_user_name||' could not be mapped to a csr user');			
			END IF;
	END;
END;

PROCEDURE IsLogonAsUserAllowed(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	out_result						OUT	BINARY_INTEGER
)
AS
	v_user_sid						csr_user.csr_user_sid%TYPE;
BEGIN
	GetUserSIDFromUserName(in_app_sid, in_user_name, v_user_sid);

	csr_user_pkg.IsLogonAsUserAllowed(security_pkg.GetACT, v_user_sid, out_result);
END;

PROCEDURE LogonUser(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_name					IN	csr_user.user_name%TYPE,
	in_host							IN	security.website.website_name%TYPE,
	out_act							OUT	security_pkg.T_ACT_ID
)
AS
	v_user_sid						csr_user.csr_user_sid%TYPE;
BEGIN
	GetUserSIDFromUserName(in_app_sid, in_user_name, v_user_sid);

	LogonUser(in_app_sid, v_user_sid, in_host, out_act);
END;

PROCEDURE LogonUser(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_user_sid						IN	csr_user.csr_user_sid%TYPE,
	in_host							IN	security.website.website_name%TYPE,
	out_act							OUT	security_pkg.T_ACT_ID
)
AS
	v_act_timeout					security.website.act_timeout%TYPE;
BEGIN
	-- We've decided which user the SAML assertion has identified, so log them on
	-- and return an ACT for them

	-- figure out the timeout (which varies by host, not just application)
	BEGIN
		SELECT act_timeout
		  INTO v_act_timeout
		  FROM security.website
		 WHERE application_sid_id = in_app_sid
		   AND LOWER(website_name) = LOWER(in_host);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,
				'The website ' || in_host || ' could not be found');
	END;

	csr_user_pkg.LogonSSOUser(in_user_sid, in_app_sid, v_act_timeout, out_act);
END;

-- Called from an oracle scheduler job to remove old expired entries
PROCEDURE CleanAssertionCache
AS
BEGIN
	DELETE FROM saml_assertion_cache
	 WHERE expires < SYSDATE;
END;

-- Called from an oracle scheduler job to remove old log entries
PROCEDURE CleanRequestLog
AS
	v_clean_to						DATE := ADD_MONTHS(SYSDATE, -3);
BEGIN
	DELETE FROM saml_log
	 WHERE (app_sid, saml_request_id) IN (SELECT app_sid, saml_request_id
	 										FROM saml_assertion_log
	 									   WHERE received_dtm <= v_clean_to);
	DELETE FROM saml_assertion_log
	 WHERE received_dtm <= v_clean_to;
END;

PROCEDURE SignHMAC(
	in_message		RAW,
	out_hash	OUT	RAW
)
AS
	v_hash		RAW(20);
	v_key		hmac.shared_secret%TYPE;
BEGIN
	SELECT shared_secret
	  INTO v_key
	  FROM hmac
	 WHERE app_sid = security_pkg.GetApp;

	out_hash := dbms_crypto.mac(in_message, dbms_crypto.hmac_sh1, v_key);
END;

PROCEDURE ValidateHMAC(
	in_message				RAW,
	in_hash					RAW,
	out_expected_hash	OUT	RAW
)
AS
	v_hash		RAW(20);
	v_match		NUMBER;
BEGIN
	saml_pkg.SignHMAC(in_message, v_hash);
	v_match := utl_raw.compare(v_hash, in_hash);

	security_pkg.debugmsg(rawtohex(v_hash));
	security_pkg.debugmsg(rawtohex(in_hash));

	IF v_match = 0 THEN
		out_expected_hash := NULL;
	ELSE
		out_expected_hash := v_hash;
	END IF;
END;

PROCEDURE GetCertificates(
	in_app_sid			IN	customer.app_sid%TYPE,
	out_certs_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_certs_cur FOR
		SELECT sso_cert_id, public_signing_cert
		  FROM customer_saml_sso_cert
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetSsoConfig(
	in_app_sid			IN	customer.app_sid%TYPE,
	out_config_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_certs_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_config_cur FOR
		SELECT idp_url, sign_auth_request, signed_response_req, use_name_id, name_attribute, logout_redirect_url, consumer_url, use_http_redirect,
			   show_sso_option_login, use_default_user_acc, use_basic_user_management, full_name_attribute, email_attribute, use_first_last_name_attrs,
			   first_name_attribute, last_name_attribute
		  FROM customer_saml_sso
		 WHERE app_sid = in_app_sid;

	GetCertificates(in_app_sid, out_certs_cur);
END;

PROCEDURE AddSigningCert(
	in_cert			IN	customer_saml_sso_cert.public_signing_cert%TYPE,
	out_cert_id		OUT	customer_saml_sso_cert.sso_cert_id%TYPE
)
AS
BEGIN
	SELECT sso_cert_id_seq.nextval
	  INTO out_cert_id
	  FROM DUAL;

	INSERT INTO customer_saml_sso_cert (sso_cert_id, public_signing_cert)
	VALUES (out_cert_id, in_cert);
END;

PROCEDURE AddSigningCert(
	in_cache_key		IN	VARCHAR2,
	out_cert_id			OUT	customer_saml_sso_cert.sso_cert_id%TYPE
)
AS
BEGIN
	SELECT sso_cert_id_seq.nextval
	  INTO out_cert_id
	  FROM DUAL;

	INSERT INTO customer_saml_sso_cert (sso_cert_id, public_signing_cert)
	SELECT out_cert_id, object
	  FROM aspen2.filecache
	 WHERE cache_key = in_cache_key;

	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END IF;
END;

PROCEDURE DeleteSigningCert(
	in_sso_cert_id			IN customer_saml_sso_cert.sso_cert_id%TYPE
)
AS
BEGIN
	DELETE FROM customer_saml_sso_cert
		WHERE sso_cert_id = in_sso_cert_id;
END;

FUNCTION INTERNALPrepareDefSsoUserAcc (
	in_new_use_default_user_acc	IN customer_saml_sso.use_default_user_acc%TYPE
)
RETURN security_pkg.T_SID_ID
AS
	v_user_sids				security_pkg.T_SID_IDS;
	v_sso_users_group_sid	security_pkg.T_SID_ID;
	
	v_curr_use_def_acc		customer_saml_sso.use_default_user_acc%TYPE;
	v_def_user_sid			security_pkg.T_SID_ID;				
	v_is_in_trash			NUMBER;					
	v_user_name				csr_user.user_name%TYPE;
BEGIN
	GetDefSsoUserInfo(v_curr_use_def_acc, v_def_user_sid, v_is_in_trash, v_user_name);
	
	-- if we are turning on use of default account ensure there is a default account, it is active and not in recycling bin - and get it's sid
	-- if we are turning off use of default account, deactivate the account - and return null
	IF in_new_use_default_user_acc = 1 AND v_def_user_sid IS NULL THEN
		BEGIN
			v_sso_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.getApp, 'Groups/SSO Users');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'SSO Users group not found');
		END;

		csr_user_pkg.createUser(
			in_act			 			=> security.security_pkg.getACT,
			in_app_sid					=> security.security_pkg.getApp,
			in_user_name				=> 'Default SSO User',
			in_password 				=> NULL, 
			in_full_name				=> 'Default SSO User',
			in_friendly_name			=> 'Default SSO User',
			in_email		 			=> 'no-reply@cr360.com',
			in_info_xml					=> NULL,
			in_send_alerts				=> 0,
			in_account_expiry_enabled	=> 0,
			out_user_sid 				=> v_def_user_sid
		);
		
		-- put into SSO users group
		security.group_pkg.AddMember(security.security_pkg.getACT, v_def_user_sid, v_sso_users_group_sid);
		
	ELSIF in_new_use_default_user_acc = 1 AND v_def_user_sid IS NOT NULL AND v_is_in_trash = 0 THEN
		csr_user_pkg.activateUser(
			in_act							=> security_pkg.GetAct, 
			in_user_sid						=> v_def_user_sid
		);
				
		CheckDefSsoUserPermitted(v_def_user_sid);
		
	ELSIF in_new_use_default_user_acc = 0 AND v_def_user_sid IS NOT NULL THEN
		csr_user_pkg.deactivateUser(
			in_act							=> security_pkg.GetAct, 
			in_user_sid						=> v_def_user_sid,
			in_raise_user_inactive_alert	=> 0
		);
		
	END IF;
	
	-- may be null if default account never used
	RETURN v_def_user_sid;
END;

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
)
AS
	v_def_user_sid			security_pkg.T_SID_ID;
BEGIN

	IF NOT (csr.csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied setting SSO config, only BuiltinAdministrator or super admins can do this.');
	END IF;

	v_def_user_sid := INTERNALPrepareDefSsoUserAcc(in_use_default_user_acc);
	CheckDefSsoUserPermitted(v_def_user_sid);

	BEGIN
		INSERT INTO customer_saml_sso (idp_url, sign_auth_request, signed_response_req, use_name_id, name_attribute, full_name_attribute, email_attribute, logout_redirect_url, consumer_url, use_http_redirect, show_sso_option_login, use_default_user_acc, default_logon_user_sid, use_basic_user_management, use_first_last_name_attrs, first_name_attribute, last_name_attribute)
		VALUES (in_idp_url, in_sign_auth_request, in_signed_response_req, in_use_name_id, in_name_attribute, in_full_name_attribute, in_email_attribute, in_logout_redirect_url, in_consumer_url, in_use_http_redirect, in_show_sso_option_login, in_use_default_user_acc, v_def_user_sid, in_use_basic_user_mgmt, in_use_first_last_name_attrs, in_first_name_attribute, in_last_name_attribute);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE customer_saml_sso
			   SET idp_url = in_idp_url,
				   sign_auth_request = in_sign_auth_request,
				   signed_response_req = in_signed_response_req,
				   use_name_id = in_use_name_id,
				   name_attribute = in_name_attribute,
				   full_name_attribute = in_full_name_attribute,
				   first_name_attribute = in_first_name_attribute,
				   last_name_attribute = in_last_name_attribute,
				   email_attribute = in_email_attribute,
				   logout_redirect_url = in_logout_redirect_url,
				   consumer_url = in_consumer_url,
				   use_http_redirect = in_use_http_redirect,
				   show_sso_option_login = in_show_sso_option_login,
				   use_default_user_acc = in_use_default_user_acc,
				   default_logon_user_sid = v_def_user_sid,
				   use_basic_user_management = in_use_basic_user_mgmt,
				   use_first_last_name_attrs = in_use_first_last_name_attrs;
	END;
END;

PROCEDURE GetLogEntries(
	in_start_row					IN  NUMBER,
	in_end_row					  	IN  NUMBER,
	in_search_string				IN  VARCHAR2,
	in_order_by					 	IN  VARCHAR2,
	in_order_dir					IN  VARCHAR2,
	out_total_rows				  	OUT NUMBER,
	out_logs_cur					OUT	SYS_REFCURSOR
)
AS
	v_search_query				  	VARCHAR2(256);
	v_selected_rows				 	csr.t_sso_log_table := csr.t_sso_log_table();
BEGIN
	IF NOT (csr.csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to SSO logs, only BuiltinAdministrator or super admins can do this.');
	END IF;
	
	v_search_query := '%' || LOWER(in_search_string) || '%';

	SELECT T_SSO_LOG_ROW(saml_log_host, log_dtm, saml_request_id, message_sequence,
		   saml_log_msg, saml_log_data)
	  BULK COLLECT INTO v_selected_rows
	  FROM (
	  	SELECT ROWNUM rn, x.saml_log_host, x.log_dtm, x.saml_request_id, x.message_sequence,
		   x.saml_log_msg, x.saml_log_data
		  FROM (
			SELECT saml_log_host, log_dtm, saml_request_id, message_sequence,
			   saml_log_msg, saml_log_data
			  FROM csr.v$sso_log
			 WHERE v_search_query IS NULL OR
			   LOWER(saml_log_host) LIKE v_search_query OR
			   TO_CHAR(saml_request_id) LIKE v_search_query OR
			   LOWER(saml_log_msg) LIKE v_search_query
			ORDER BY
				CASE LOWER(in_order_dir) WHEN 'asc' THEN
					CASE LOWER(in_order_by)
						WHEN 'dtm' THEN TO_CHAR(log_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'host' THEN saml_log_host
						WHEN 'requestid' THEN TO_CHAR(saml_request_id)
						ELSE TO_CHAR(log_dtm, 'YYYY-MM-DD HH24:MI:SS')
						END
				END	ASC,
				CASE LOWER(in_order_dir) WHEN 'desc' THEN
					CASE LOWER(in_order_by)
						WHEN 'dtm' THEN TO_CHAR(log_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'host' THEN saml_log_host
						WHEN 'requestid' THEN TO_CHAR(saml_request_id)
						ELSE TO_CHAR(log_dtm, 'YYYY-MM-DD HH24:MI:SS')
						END
				END DESC, log_dtm, saml_request_id,	message_sequence
		 ) x
		 WHERE ROWNUM <= in_end_row
	 )
	 WHERE rn > in_start_row;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM csr.v$sso_log;
	
	OPEN out_logs_cur FOR
		SELECT saml_log_host, log_dtm, saml_request_id, message_sequence, message,
			   saml_log_data
		  FROM TABLE(v_selected_rows);
END;

PROCEDURE SetLoginRedirectURLById(
	in_redirect_url_id				IN NUMBER
)
AS
	v_new_url						csr.allowed_sso_login_redirect.url%TYPE;
BEGIN
	IF NOT (csr.csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied setting login redirect, only BuiltinAdministrator or super admins can do this.');
	END IF;
	
	SELECT url
	  INTO v_new_url
	  FROM csr.allowed_sso_login_redirect
	 WHERE id = in_redirect_url_id;

	UPDATE aspen2.application
	   SET logon_url = v_new_url
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetAllowedLoginRedirectURLs(
	out_cur						 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT url, display_name, id
		  FROM csr.allowed_sso_login_redirect;
END;

PROCEDURE GetLoginRedirectURLId(
	out_url_id						OUT NUMBER
)
AS
	v_current_url					csr.allowed_sso_login_redirect.url%TYPE;
BEGIN
	SELECT logon_url
	  INTO v_current_url
	  FROM aspen2.application
	 WHERE app_sid = security_pkg.GetApp;

	SELECT id
	  INTO out_url_id
	  FROM csr.allowed_sso_login_redirect
	 WHERE url = v_current_url;
END;

END;
/
