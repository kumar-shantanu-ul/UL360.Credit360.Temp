define rap5_version=9
@update_header

BEGIN
	user_pkg.LogonAdmin;
		
	card_pkg.RegisterCard(
		'Generic summary page', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/wizardSummary.js', 
		'Chain.Cards.WizardSummary'
	);
	
	card_pkg.RegisterCard(
		'Chain.Cards.SearchCompany extension for picking component suppliers', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponentSupplier.js', 
		'Chain.Cards.SearchComponentSupplier',
		T_STRING_LIST('default', 'createnew')
	);
END;
/


commit;

@update_tail