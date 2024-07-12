CREATE OR REPLACE PACKAGE csr.credentials_pkg AS

PROCEDURE GetCredentials(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetActiveCredentials(
	in_auth_type_id			IN	credential_management.auth_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSelectedCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpdateCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	in_label				IN	credential_management.label%TYPE,
	in_cache_key			IN	credential_management.cache_key%TYPE,
	in_login_hint			IN	credential_management.login_hint%TYPE
);

PROCEDURE UpdateCredentialCacheKey(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	in_cache_key			IN	credential_management.cache_key%TYPE,
	in_login_hint			IN	credential_management.login_hint%TYPE
);

PROCEDURE AddCredential(
	in_label				IN	credential_management.label%TYPE,
	in_auth_type_id			IN  credential_management.auth_type_id%TYPE,
	in_auth_scope_id		IN  credential_management.auth_scope_id%TYPE
);

PROCEDURE DeleteCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE
);

PROCEDURE GetAuthenticationTypes(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAuthenticationScopes(
	out_cur					OUT	SYS_REFCURSOR
);

END;
/
