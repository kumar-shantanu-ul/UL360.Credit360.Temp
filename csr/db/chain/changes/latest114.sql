define version=114
@update_header

@latest111_packages
@latest114_chain_pkg

exec user_pkg.logonadmin;
BEGIN
	chain.capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.PRODUCT_CODE_TYPES, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.PRODUCT_CODE_TYPES, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);
END;
/

@..\chain_pkg

@update_tail