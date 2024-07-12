define version=73
@update_header

BEGIN
	
	FOR r IN (
		SELECT * FROM chain.v$chain_host WHERE chain_implementation = 'OTTO'
	) LOOP
	
		user_pkg.logonadmin(r.host);
	
		chain.card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.EditCompany', 'Chain.Cards.ViewCompany', 'Chain.Cards.EditProductCodeTypes', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.EditProductCodeTypes', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SETUP_STUB_REGISTRATION);
		
		chain.card_pkg.SetGroupCards('Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.SupplierInvitationSummary'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		
		
	END LOOP;
END;
/

@../purchased_component_body

@update_tail