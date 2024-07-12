-- Please update version.sql too -- this keeps clean builds in sync
define version=2260
@update_header

ALTER TABLE CSR.customer_saml_sso ADD (
	CONSUMER_URL	VARCHAR2(2048)	NULL
);

@..\saml_pkg
@..\saml_body

@update_tail