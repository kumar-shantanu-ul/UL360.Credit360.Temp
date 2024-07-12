-- Please update version.sql too -- this keeps clean builds in sync
define version=2324
@update_header

BEGIN
	dbms_rls.drop_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_SAML_SSO_CERT',
		policy_name     => 'CUSTOMER_SAML_SSO_CERT_POLICY'
	);
END;
/

@update_tail