define version=1
@update_header

@..\chain_pkg

DECLARE
	v_card_id			card.card_id%TYPE;
BEGIN
	INSERT INTO card_group
	(card_group_id, name, description, require_all_cards)
	VALUES
	(7, 'My Company', 'Allows users to manage their company details', 0);

	v_card_id := card_pkg.RegisterCard(
		'Displays tasks for a particular supplier', 
		'Credit360.Chain.Cards.CreateCompanyUser',
		'/csr/site/chain/cards/createCompanyUser.js', 
		'Chain.Cards.CreateCompanyUser',
		null
	);
	
	INSERT INTO capability (capability_name, perm_type) VALUES (chain_pkg.CREATE_COMPANY_USERS, chain_pkg.BOOLEAN_PERMISSION);
	
	UPDATE action_type 
	   SET for_company_url = '<a href="/csr/site/chain/myCompany.acds?confirm=true">{forCompanyName}</a>' 
	 WHERE for_company_url IS NOT NULL;
	
	user_pkg.logonadmin;
	
	capability_pkg.GrantCapability(chain_pkg.CREATE_COMPANY_USERS, chain_pkg.ADMIN_GROUP);
	
	FOR r IN (
		SELECT app_sid
		  FROM customer_options
	) LOOP
		security_pkg.SetACT(security_pkg.GetAct, r.app_sid);
		company_pkg.VerifySOStructure;
	END LOOP;
END;
/

@..\company_user_pkg


@..\company_user_body
@..\invitation_body

@update_tail