-- Please update version.sql too -- this keeps clean builds in sync
define version=1580
@update_header

--Snapshot of chain.card_pkg for RegisterCard and SetGroupsCards
@@latest1580_packages
	
BEGIN
	--logon as builtin admin, no app
	security.user_pkg.logonadmin;
	
	chain.temp_card_pkg.RegisterCardGroup(9, 'Add Existing Contacts Wizard', 'Wizard used to collect registered, unregistered contacts');
	
	--AddExistingSuppliers card
	chain.temp_card_pkg.RegisterCard(
		'Add existing suppliers',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addExistingSuppliers.js',
		'Chain.Cards.AddExistingSuppliers'
	);
	
	--AddExistingUsers card
	chain.temp_card_pkg.RegisterCard(
		'Add existing users',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addExistingUsers.js',
		'Chain.Cards.AddExistingUsers'
	);

	FOR r IN (	
		SELECT DISTINCT h.host
		  FROM chain.v$chain_host h
	) 
	LOOP 
		security.user_pkg.LogonAdmin(r.host);
				
		chain.temp_card_pkg.SetGroupCards('Add Existing Contacts Wizard', chain.T_STRING_LIST(
			'Chain.Cards.AddExistingSuppliers',
			'Chain.Cards.AddExistingUsers'
		));		
	END LOOP;
	security.user_pkg.logonadmin;
END;
/


@..\chain\company_user_pkg
@..\chain\company_user_body

@update_tail