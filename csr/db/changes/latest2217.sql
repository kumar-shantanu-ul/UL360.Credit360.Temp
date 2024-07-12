-- Please update version.sql too -- this keeps clean builds in sync
define version=2217
@update_header

ALTER TABLE csr.customer_saml_sso_cert DROP CONSTRAINT PK_CUSTOMER_SAML_SSO_CERT;
ALTER TABLE csr.customer_saml_sso_cert DROP COLUMN EXPIRY_DTM;

ALTER TABLE csr.customer_saml_sso_cert ADD (
	SSO_CERT_ID			NUMBER(10),
	CONSTRAINT PK_CUSTOMER_SAML_SSO_CERT PRIMARY KEY (APP_SID, SSO_CERT_ID)
);

CREATE SEQUENCE CSR.SSO_CERT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

@..\saml_pkg
@..\saml_body

@update_tail
