define version=57
@update_header

-- this is useless
ALTER TABLE CARD_GROUP DROP COLUMN REQUIRE_ALL_CARDS;

-- set some defaults
ALTER TABLE COMPONENT MODIFY CREATED_BY_SID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
ALTER TABLE COMPONENT MODIFY COMPANY_SID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

-- make component source data assignable to a specific card group
ALTER TABLE COMPONENT_SOURCE ADD (CARD_GROUP_ID         NUMBER(10, 0));
ALTER TABLE COMPONENT_SOURCE ADD CONSTRAINT RefCARD_GROUP542 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES CARD_GROUP(CARD_GROUP_ID)
;

@latest57_packages

-- reg any changes
BEGIN
	user_pkg.logonadmin;
	
	card_pkg.RegisterCardGroup(16, 'Not Sure Component Wizard', 'Used to convert a not sure component to another type');
	card_pkg.RegisterCardGroup(17, 'Add Existing Component Wizard', 'Used to add an existing component');
	
	/*** SEARCH COMPONENT SUPPLIER ***/
	card_pkg.RegisterCard(
		'Chain.Cards.SearchCompany extension for picking component suppliers', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponentSupplier.js', 
		'Chain.Cards.SearchComponentSupplier'
	);


	/*** COMPONENT SOURCE ***/
	card_pkg.RegisterCard(
		'Asks where a component comes from', 
		'Credit360.Chain.Cards.ComponentSource',
		'/csr/site/chain/cards/componentSource.js', 
		'Chain.Cards.ComponentSource',
		---------------------------------------------------------------------------------------------
		-- the progression actions will get automatically filled in via calls to 
		-- component_pkg.AddComponentSource as this card is dynamically populated from that data.
		-- we do however need to ensure that we don't delete existing actions when re-running
		-- this script, so we'll passback any existing actions during the registration
		---------------------------------------------------------------------------------------------
		card_pkg.GetProgressionActions('Chain.Cards.ComponentSource')
	);

	/*** NOT SURE ***/
	card_pkg.RegisterCard(
		'Not sure - maybe we can help', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/notSure.js', 
		'Chain.Cards.NotSure'
	);

	/*** NOT SURE END POINT ***/
	card_pkg.RegisterCard(
		'A friendly message thanking you for editting a not sure component', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/notSureEndPoint.js', 
		'Chain.Cards.NotSureEndPoint'
	);

	/*** COMPONENT BUILDER - COMPONENT SOURCE ***/
	card_pkg.RegisterCard(
		'Asks where a component comes from, as a component builder extension', 
		'Credit360.Chain.Cards.ComponentSource',
		'/csr/site/chain/cards/componentBuilder/componentSource.js', 
		'Chain.Cards.ComponentBuilder.ComponentSource',
		---------------------------------------------------------------------------------------------
		-- the progression actions will get automatically filled in via calls to 
		-- component_pkg.AddComponentSource as this card is dynamically populated from that data.
		-- we do however need to ensure that we don't delete existing actions when re-running
		-- this script, so we'll passback any existing actions during the registration
		---------------------------------------------------------------------------------------------
		card_pkg.GetProgressionActions('Chain.Cards.ComponentBuilder.ComponentSource')
	);
	
	/*** COMPONENT BUILDER - ADD SUPPLER ***/
	card_pkg.RegisterCard(
		'Chain.Cards.AddComponentSupplier extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addSupplier.js', 
		'Chain.Cards.ComponentBuilder.AddSupplier'
	);	

	/*** COMPONENT BUILDER - ADD MORE CHILDREN ***/
	card_pkg.RegisterCard(
		'Lists the child components of the current component and gives the option to add more', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addMoreChildren.js', 
		'Chain.Cards.ComponentBuilder.AddMoreChildren',
		T_STRING_LIST('yes', 'no', 'finished')
	);

	/*** COMPONENT BUILDER - NOT SURE ***/
	card_pkg.RegisterCard(
		'Chain.Cards.NotSure extension with logic for comoponent builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/notSure.js', 
		'Chain.Cards.ComponentBuilder.NotSure'
	);
END;
/

@update_tail
