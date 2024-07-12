-- Please update version.sql too -- this keeps clean builds in sync
define version=2215
@update_header

CREATE TABLE CSR.CUSTOMER_SAML_SSO (
	APP_SID						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	IDP_URL						VARCHAR(1024)	NOT NULL,
	SIGN_AUTH_REQUEST			NUMBER(1)		NOT NULL,
	SIGNED_RESPONSE_REQ			NUMBER(1)		NOT NULL,
	USE_NAME_ID					NUMBER(1)		NOT NULL,
	NAME_ATTRIBUTE				VARCHAR(255)	NULL,
	LOGOUT_REDIRECT_URL			VARCHAR(1024)	NULL,
	CONSTRAINT CHK_SIGN_AUTH_REQUEST CHECK (SIGN_AUTH_REQUEST IN (0,1)),
	CONSTRAINT CHK_SIGNED_RESPONSE_REQ CHECK (SIGNED_RESPONSE_REQ IN (0,1)),
	CONSTRAINT CHK_USE_NAME_ID CHECK (USE_NAME_ID IN (0,1)),
	CONSTRAINT CHK_NAME_ATTRIBUTE CHECK ((USE_NAME_ID = 1 AND NAME_ATTRIBUTE IS NULL) OR (USE_NAME_ID = 0 AND NAME_ATTRIBUTE IS NOT NULL)),
	CONSTRAINT PK_CUSTOMER_SAML_SSO PRIMARY KEY (APP_SID)
);

CREATE TABLE CSR.CUSTOMER_SAML_SSO_CERT (
	APP_SID						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	EXPIRY_DTM					DATE			NOT NULL,
	PUBLIC_SIGNING_CERT			BLOB			NOT NULL,
	CONSTRAINT PK_CUSTOMER_SAML_SSO_CERT PRIMARY KEY (APP_SID, EXPIRY_DTM),
	CONSTRAINT FK_CUSTOMER_SAML_SSO FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER_SAML_SSO (APP_SID)
);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_SAML_SSO',
		policy_name     => 'CUSTOMER_SAML_SSO_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_SAML_SSO_CERT',
		policy_name     => 'CUSTOMER_SAML_SSO_CERT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
END;
/

@..\saml_pkg
@..\saml_body

@update_tail
