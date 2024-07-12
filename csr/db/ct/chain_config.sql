BEGIN
	-- logon as builtin admin, no app
	security.user_pkg.logonadmin;

	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.CT_HOTSPOTTER, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_HOTSPOTTER, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_HOTSPOTTER, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CT_HOTSPOTTER, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.CT_HOTSPOTTER, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_WRITE);
		
END;
/
