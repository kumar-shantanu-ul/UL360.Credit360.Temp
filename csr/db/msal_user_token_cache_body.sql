CREATE OR REPLACE PACKAGE BODY csr.msal_user_token_cache_pkg AS

PROCEDURE GetUserTokenCacheByCacheKey (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cache_key, token, login_hint
		  FROM csr.msal_user_token_cache
		 WHERE app_sid = SYS_CONTEXT('security', 'app')
		   AND cache_key = in_cache_key;
END;

PROCEDURE SaveUserTokenCache (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE,
	in_token				IN	msal_user_token_cache.token%TYPE,
	in_login_hint			IN	msal_user_token_cache.login_hint%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO csr.msal_user_token_cache (app_sid, cache_key, token, login_hint)
		VALUES (sys_context('security', 'app'), in_cache_key, in_token, in_login_hint);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.msal_user_token_cache
			   SET token = in_token, login_hint = in_login_hint
			 WHERE app_sid = SYS_CONTEXT('security', 'app')
			   AND cache_key = in_cache_key;
	END;
END;

PROCEDURE DeleteUserTokenCache (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE
)
AS
BEGIN
	DELETE FROM csr.msal_user_token_cache 
	 WHERE app_sid = SYS_CONTEXT('security', 'app') 
	   AND cache_key = in_cache_key;
END;

PROCEDURE StartConsentFlow (
	in_redirect_url			IN  msal_user_consent_flow.redirect_url%TYPE,
	in_pkce					IN  msal_user_consent_flow.pkce%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO msal_user_consent_flow (act_id, redirect_url, pkce)
		VALUES (sys_context('security', 'act'), in_redirect_url, in_pkce);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.msal_user_consent_flow
			   SET redirect_url = in_redirect_url, pkce = in_pkce
			 WHERE act_id = sys_context('security', 'act');
	END;
END;

PROCEDURE GetConsent (
	in_act_id				IN  msal_user_consent_flow.act_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT redirect_url, pkce
		  FROM msal_user_consent_flow
		 WHERE act_id = in_act_id;
END;

PROCEDURE EndConsentFlow (
	in_act_id				IN  msal_user_consent_flow.act_id%TYPE
)
AS
BEGIN
	DELETE FROM msal_user_consent_flow
	 WHERE act_id = in_act_id;
END;

END;
/