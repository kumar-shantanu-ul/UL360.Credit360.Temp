 define rap4_version=14
 @update_header


BEGIN
	user_pkg.logonadmin;
	
	/*** SEARCH COMPANIES ***/
	card_pkg.RegisterCard(
		'Search for companies.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchCompanies.js', 
		'Chain.Cards.SearchCompanies'
	);

END;
/

@update_tail