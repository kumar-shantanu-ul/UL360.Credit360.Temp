 define rap4_version=13
 @update_header

@..\..\card_pkg
@..\..\card_body

@..\..\cmpnt_cmpnt_relationship_pkg
@..\..\cmpnt_cmpnt_relationship_body


BEGIN
	user_pkg.logonadmin;
	
	card_pkg.RenameProgressionAction('Chain.Cards.ComponentBuilder.AddComponent', 'existing', 'search');
		
	/*** ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Add component card that prompts you to search for an existing component or enter the basic details for a new one. This card does not handle the actual search.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addComponent.js', 
		'Chain.Cards.AddComponent',
		T_STRING_LIST('search', 'new')
	);

	/*** EDIT COMPONENT ***/
	card_pkg.RegisterCard(
		'Edit a component''s details.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/editComponent.js', 
		'Chain.Cards.EditComponent'
	);
	
	/*** SEARCH COMPONENT ***/
	card_pkg.RegisterCard(
		'Search for an existing component.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponents.js', 
		'Chain.Cards.SearchComponents'
	);

	/*** COMPONENT BUILDER - ADD COMPONENT ***/
	card_pkg.RegisterCard(
		'Chain.Cards.AddComponent extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addComponent.js', 
		'Chain.Cards.ComponentBuilder.AddComponent',
		T_STRING_LIST('search', 'new', 'newpurchased')
	);
	
	/*** COMPONENT BUILDER - SEARCH COMPONENT ***/
	card_pkg.RegisterCard(
		'Chain.Cards.SearchComponents extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/searchComponents.js', 
		'Chain.Cards.ComponentBuilder.SearchComponents'
	);


END;
/

@update_tail