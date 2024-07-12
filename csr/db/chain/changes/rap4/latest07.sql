define rap4_version=7
@update_header

@..\..\card_pkg
@..\..\card_body

-- register component cards
BEGIN
	user_pkg.logonadmin;
	
	FOR r IN (
		SELECT card_id FROM card
	) LOOP
		BEGIN
			INSERT INTO card_progression_action
			(card_id, action)
			VALUES
			(r.card_id, 'default');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	
	/*** COMPONENT BUILDER - COMPONENT SOURCE ***/
	card_pkg.RegisterCard(
		'Asks where a component comes from', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilderCards.js', 
		'Chain.Cards.ComponentBuilder.ComponentSource',
		T_STRING_LIST('supplied', 'internal', 'rawmaterial', 'notsure')
	);
	
	/*** COMPONENT BUILDER - ADD MORE CHILDREN ***/
	card_pkg.RegisterCard(
		'Lists the child components of the current component and gives the option to add more', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilderCards.js', 
		'Chain.Cards.ComponentBuilder.AddMoreChildren',
		T_STRING_LIST('yes', 'no')
	);
	
	/*** COMPONENT BUILDER - RAW MATERIAL ***/
	card_pkg.RegisterCard(
		'This needs to handle the component being a raw material', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilderCards.js', 
		'Chain.Cards.ComponentBuilder.RawMaterial'
	);
	
	/*** COMPONENT BUILDER - NOT SURE ***/
	card_pkg.RegisterCard(
		'You are dumb as rocks, how can you not know where your components come from?', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilderCards.js', 
		'Chain.Cards.ComponentBuilder.NotSure'
	);
	
	/*** COMPONENT BUILDER - END POINT ***/
	card_pkg.RegisterCard(
		'A friendly message thanking you for using the Component Builder wizard', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilderCards.js', 
		'Chain.Cards.ComponentBuilder.EndPoint'
	);
	
END;
/



@update_tail