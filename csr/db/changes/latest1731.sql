-- Please update version.sql too -- this keeps clean builds in sync
define version=1731
@update_header

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host FROM csr.customer WHERE app_sid IN (SELECT app_sid FROM chain.customer_options WHERE use_type_capabilities = 1)
	) LOOP
		security.user_pkg.logonadmin(r.host);
		csr.csr_data_pkg.EnableCapability('Manage chain capabilities', 1);
	END LOOP;
END;
/

@update_tail
