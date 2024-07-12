-- Please update version.sql too -- this keeps clean builds in sync
define version=2442
@update_header

ALTER TABLE csr.customer_saml_sso ADD (
	USE_HTTP_REDIRECT	NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_USE_HTTP_REDIRECT CHECK (USE_HTTP_REDIRECT IN (0,1))
);

@..\saml_pkg
@..\saml_body

@update_tail