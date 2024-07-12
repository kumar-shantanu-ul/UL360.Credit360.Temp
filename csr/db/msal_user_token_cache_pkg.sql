CREATE OR REPLACE PACKAGE csr.msal_user_token_cache_pkg AS

PROCEDURE GetUserTokenCacheByCacheKey (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE SaveUserTokenCache (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE,
	in_token				IN	msal_user_token_cache.token%TYPE,
	in_login_hint			IN	msal_user_token_cache.login_hint%TYPE
);

PROCEDURE DeleteUserTokenCache (
	in_cache_key			IN	msal_user_token_cache.cache_key%TYPE
);

PROCEDURE StartConsentFlow (
	in_redirect_url			IN  msal_user_consent_flow.redirect_url%TYPE,
	in_pkce					IN  msal_user_consent_flow.pkce%TYPE
);

PROCEDURE GetConsent (
	in_act_id				IN  msal_user_consent_flow.act_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE EndConsentFlow(
	in_act_id				IN  msal_user_consent_flow.act_id%TYPE
);

END;
/