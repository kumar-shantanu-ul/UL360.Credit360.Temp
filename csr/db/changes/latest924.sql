-- Please update version.sql too -- this keeps clean builds in sync
define version=924
@update_header

ALTER TABLE CHAIN.SUPPLIER_FOLLOWER ADD (
 	IS_PRIMARY               NUMBER(1, 0),
    CHECK (IS_PRIMARY IS NULL OR IS_PRIMARY = 1)
);

CREATE UNIQUE INDEX CHAIN.IDX_PRIMARY_SUPPLIER_FOLLOWER ON CHAIN.SUPPLIER_FOLLOWER(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID, NVL(IS_PRIMARY, USER_SID));

@latest924_packages

BEGIN
	security.user_pkg.LogonAdmin;
	
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER, chain.chain_pkg.BOOLEAN_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CHANGE_SUPPLIER_FOLLOWER, chain.chain_pkg.ADMIN_GROUP);
	
	chain.card_pkg.RegisterCardGroup(26, 'My Suppliers', 'Lists a users suppliers');
	
	chain.card_pkg.RegisterCard(
		'Lists suppliers that a user is following', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/followingSuppliers.js', 
		'Chain.Cards.FollowingSuppliers'
	);

	chain.card_pkg.RegisterCard(
		'Lists users that are following a supplier', 
		'Credit360.Chain.Cards.SupplierFollowers',
		'/csr/site/chain/cards/supplierFollowers.js', 
		'Chain.Cards.SupplierFollowers'
	);
	
	FOR r IN (SELECT host FROM chain.v$chain_host) LOOP
		security.user_pkg.LogonAdmin(r.host);
		chain.company_pkg.VerifySOStructure;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/

@update_tail
