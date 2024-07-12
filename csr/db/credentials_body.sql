CREATE OR REPLACE PACKAGE BODY csr.credentials_pkg AS

PROCEDURE GetCredentials(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cm.credential_id, cm.label, cm.auth_type_id, aut.auth_type_name, cm.created_dtm, cm.updated_dtm,
			CASE WHEN cm.cache_key IS NULL THEN 0 ELSE 1 END has_key, cm.auth_scope_id, aus.auth_scope_name, aus.auth_scope
		  FROM credential_management cm
		  JOIN authentication_type aut ON aut.auth_type_id =  cm.auth_type_id
		  LEFT JOIN authentication_scope aus ON aus.auth_scope_id = cm.auth_scope_id
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		ORDER BY label;
END;

PROCEDURE GetActiveCredentials(
	in_auth_type_id			IN	credential_management.auth_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cm.app_sid, cm.credential_id, cm.label, cm.auth_type_id, cm.created_dtm, cm.updated_dtm, cm.cache_key, cm.login_hint, cm.auth_scope_id, aus.auth_scope_name, aus.auth_scope
		  FROM credential_management cm
		  LEFT JOIN authentication_scope aus ON aus.auth_scope_id = cm.auth_scope_id
		 WHERE (in_auth_type_id IS NULL OR cm.auth_type_id = in_auth_type_id)
		   AND cache_key IS NOT NULL
		   AND login_hint IS NOT NULL
		 ORDER BY label;
END;

PROCEDURE GetSelectedCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cm.credential_id, cm.label, cm.auth_type_id, aut.auth_type_name, cm.created_dtm, cm.updated_dtm, cm.cache_key, cm.login_hint,
			CASE WHEN cm.cache_key IS NULL THEN 0 ELSE 1 END has_key, cm.auth_scope_id, aus.auth_scope_name, aus.auth_scope
		  FROM credential_management cm
		  JOIN authentication_type aut ON aut.auth_type_id = cm.auth_type_id
		  LEFT JOIN authentication_scope aus ON aus.auth_scope_id = cm.auth_scope_id
		 WHERE cm.credential_id = in_credential_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UpdateCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	in_label				IN	credential_management.label%TYPE,
	in_cache_key			IN	credential_management.cache_key%TYPE,
	in_login_hint			IN	credential_management.login_hint%TYPE
)
AS
	v_now	DATE := SYSDATE;
BEGIN
	UPDATE credential_management
	   SET label = in_label,
		   updated_dtm = v_now,
		   cache_key = in_cache_key,
		   login_hint = in_login_hint
	 WHERE credential_id = in_credential_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_CREDENTIAL_MANAGEMENT,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_credential_id,
		in_description					=> 'Credential Management Updated',
		in_param_1          			=> in_credential_id,
		in_param_2          			=> in_label,
		in_param_3          			=> v_now
	);
END;

PROCEDURE UpdateCredentialCacheKey(
	in_credential_id		IN	credential_management.credential_id%TYPE,
	in_cache_key			IN	credential_management.cache_key%TYPE,
	in_login_hint			IN	credential_management.login_hint%TYPE
)
AS
	v_now	DATE := SYSDATE;
BEGIN
	UPDATE credential_management
	   SET updated_dtm = v_now,
		   cache_key = in_cache_key,
		   login_hint = in_login_hint
	 WHERE credential_id = in_credential_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_CREDENTIAL_MANAGEMENT,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_credential_id,
		in_description					=> 'Credential Management CacheKey Updated',
		in_param_1          			=> in_credential_id,
		in_param_3          			=> v_now
	);
END;

PROCEDURE AddCredential(
	in_label			IN	credential_management.label%TYPE,
	in_auth_type_id		IN  credential_management.auth_type_id%TYPE,
	in_auth_scope_id	IN  credential_management.auth_scope_id%TYPE
)
AS
	v_now	DATE := SYSDATE;
BEGIN
	INSERT INTO credential_management (credential_id, label, auth_type_id, auth_scope_id, created_dtm, updated_dtm)
	VALUES (CREDENTIAL_MANAGEMENT_ID_SEQ.NEXTVAL, in_label, in_auth_type_id, in_auth_scope_id, v_now, v_now);

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_CREDENTIAL_MANAGEMENT,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> CREDENTIAL_MANAGEMENT_ID_SEQ.CURRVAL,
		in_description					=> 'Credential Management Added',
		in_param_1          			=> in_label,
		in_param_2          			=> in_auth_type_id,
		in_param_3          			=> v_now
	);
END;

PROCEDURE DeleteCredential(
	in_credential_id		IN	credential_management.credential_id%TYPE
)
AS
BEGIN
	DELETE FROM credential_management
	 WHERE credential_id = in_credential_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_CREDENTIAL_MANAGEMENT,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_credential_id,
		in_description					=> 'Credential Management Deleted',
		in_param_1          			=> in_credential_id,
		in_param_2          			=> null,
		in_param_3          			=> SYSDATE
	);
END;

PROCEDURE GetAuthenticationTypes (
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT auth_type_id, auth_type_name
		  FROM authentication_type;
END;

PROCEDURE GetAuthenticationScopes (
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT auth_scope_id, auth_type_id, auth_scope_name, auth_scope, hidden
		  FROM authentication_scope;
END;

END;

/
