define version=70
@update_header

@latest70_packages

-- reregister all cards
begin
	user_pkg.logonadmin;

	chain.card_pkg.RegisterCard(
		'Add company card that first prompts you to search for an existing company and then allows you to create a new one if you wish.', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/addCompany.js', 
		'Chain.Cards.AddCompany',
		chain.T_STRING_LIST('createnew')
	);

	/*** ADD COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Add company card that allows you to create a new company.', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/createCompany.js', 
		'Chain.Cards.CreateCompany'
	);

	/*** ADD USER ***/
	chain.card_pkg.RegisterCard(
		'Add user card that first prompts you to search for an existing user and then allows you to create a new one if you wish. Depends on Chain.Cards.AddCompany.', 
		'Credit360.Chain.Cards.AddUser',
		'/csr/site/chain/cards/addUser.js', 
		'Chain.Cards.AddUser',
		chain.T_STRING_LIST('createnew')
	);

	/*** CREATE USER ***/
	chain.card_pkg.RegisterCard(
		'Add user card that allows you to add a new user to a company.', 
		'Credit360.Chain.Cards.AddUser',
		'/csr/site/chain/cards/createUser.js', 
		'Chain.Cards.CreateUser'
	);
	
	/*** EDIT USER ***/
	chain.card_pkg.RegisterCard(
		'Edit user card that allows you to edit user details', 
		'Credit360.Chain.Cards.EditUser',
		'/csr/site/chain/cards/editUser.js', 
		'Chain.Cards.EditUser'
	);
	
	/*** COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Watches a readOnly config flag to determine if the requesting user can edit a company''s company details, or view a readonly version of them.', 
		'Credit360.Chain.Cards.EditCompany',
		'/csr/site/chain/cards/company.js', 
		'Chain.Cards.Company'
	);
	
	/*** EDIT COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Edit a company''s company details.', 
		'Credit360.Chain.Cards.EditCompany',
		'/csr/site/chain/cards/editCompany.js', 
		'Chain.Cards.EditCompany'
	);
	
	/*** SEARCH COMPANIES ***/
	chain.card_pkg.RegisterCard(
		'Search for companies.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchCompanies.js', 
		'Chain.Cards.SearchCompanies'
	);

	
	/*** QUESTIONNAIRE INVITATION CONFIRMATION ***/
	chain.card_pkg.RegisterCard(
		'Confirms questionnaire intvitation details with a potential new user', 
		'Credit360.Chain.Cards.QuestionnaireInvitationConfirmation',
		'/csr/site/chain/cards/QuestionnaireInvitationConfirmation.js', 
		'Chain.Cards.QuestionnaireInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
	/*** STUB INVITATION CONFIRMATION ***/
	chain.card_pkg.RegisterCard(
		'Confirms stub intvitation details with a potential new user', 
		'Credit360.Chain.Cards.StubInvitationConfirmation',
		'/csr/site/chain/cards/StubInvitationConfirmation.js', 
		'Chain.Cards.StubInvitationConfirmation'
	);

	/*** REJECT REGISTER LOGIN ***/
	chain.card_pkg.RegisterCard(
		'Allows a new user to reject an invitation, self register or login via an invitation', 
		'Credit360.Chain.Cards.RejectRegisterInvitation',
		'/csr/site/chain/cards/rejectRegisterLogin.js', 
		'Chain.Cards.RejectRegisterLogin'
	);
	
	/*** LOGIN ***/
	chain.card_pkg.RegisterCard(
		'Login card that allows an invited user to log in with existing credentials.', 
		'Credit360.Chain.Cards.RejectRegisterInvitation',
		'/csr/site/chain/cards/login.js', 
		'Chain.Cards.Login'
	);
	
	/*** REJECT ***/
	chain.card_pkg.RegisterCard(
		'Reject invitation if not an employee or not a supplier', 
		'Credit360.Chain.Cards.RejectRegisterInvitation',
		'/csr/site/chain/cards/rejectInvitation.js', 
		'Chain.Cards.RejectInvitation'
	);
	
	/*** REGISTER ***/
	chain.card_pkg.RegisterCard(
		'Register a new chain user', 
		'Credit360.Chain.Cards.RejectRegisterInvitation',
		'/csr/site/chain/cards/selfRegistration.js', 
		'Chain.Cards.SelfRegistration'
	);
	
	/*** INVITATION SUMMARY PAGE ***/
	chain.card_pkg.RegisterCard(
		'Confirmation page for inviting a new supplier', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/invitationSummary.js', 
		'Chain.Cards.InvitationSummary'
	);
	
	/*** GENERIC SUMMARY PAGE ***/
	chain.card_pkg.RegisterCard(
		'Generic summary page', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/wizardSummary.js', 
		'Chain.Cards.WizardSummary'
	);
	
	/*** COMPANY USERS ***/
	chain.card_pkg.RegisterCard(
		'Allows you to search and view/edit company user details', 
		'Credit360.Chain.Cards.CompanyUsers',
		'/csr/site/chain/cards/companyUsers.js', 
		'Chain.Cards.CompanyUsers'
	);
	
	/*** STUB SETUP ***/
	chain.card_pkg.RegisterCard(
		'Allows you to setup email stub registration', 
		'Credit360.Chain.Cards.StubSetup',
		'/csr/site/chain/cards/stubSetup.js', 
		'Chain.Cards.StubSetup'
	);
	
	/*** QUESTIONNAIRE LIST ***/
	chain.card_pkg.RegisterCard(
		'Displays a list company questionnaires', 
		'Credit360.Chain.Cards.QuestionnaireList',
		'/csr/site/chain/cards/questionnaireList.js', 
		'Chain.Cards.QuestionnaireList'
	);
	
	/*** ACTIVITY BROWSER ***/
	chain.card_pkg.RegisterCard(
		'Browse activity.', 
		'Credit360.Chain.Cards.ActivityBrowser',
		'/csr/site/chain/cards/activityBrowser.js', 
		'Chain.Cards.ActivityBrowser'
	);
	
	/*** TASK BROWSER ***/
	chain.card_pkg.RegisterCard(
		'Displays tasks for a particular supplier', 
		'Credit360.Chain.Cards.TaskBrowser',
		'/csr/site/chain/cards/taskBrowser.js', 
		'Chain.Cards.TaskBrowser'
	);	
	
	/*** CREATE COMPANY USER ***/
	chain.card_pkg.RegisterCard(
		'Allows a company to add new users to their own company', 
		'Credit360.Chain.Cards.CreateCompanyUser',
		'/csr/site/chain/cards/createCompanyUser.js', 
		'Chain.Cards.CreateCompanyUser'
	);	
	
	/*** SUPPLIER INVITATION SUMMARY ***/
	chain.card_pkg.RegisterCard(
		'A card that shows a summary of invitations sent to a supplier', 
		'Credit360.Chain.Cards.SupplierInvitationSummary',
		'/csr/site/chain/cards/supplierInvitationSummary.js', 
		'Chain.Cards.SupplierInvitationSummary'
	);	
	
	/*** VIEW COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Forces a readOnly config flag on edit company.', 
		'Credit360.Chain.Cards.EditCompany',
		'/csr/site/chain/cards/viewCompany.js', 
		'Chain.Cards.ViewCompany'
	);

	/*** EDIT PRODUCT CODE TYPES ***/
	chain.card_pkg.RegisterCard(
		'Allows product type code labels to be defined.', 
		'Credit360.Chain.Cards.EditProductCodeTypes',
		'/csr/site/chain/cards/editProductCodeTypes.js', 
		'Chain.Cards.EditProductCodeTypes'
	);

	/*** ADD COMPONENT ***/
	chain.card_pkg.RegisterCard(
		'Add component card that prompts you to search for an existing component or enter the basic details for a new one. This card does not handle the actual search.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addComponent.js', 
		'Chain.Cards.AddComponent',
		chain.T_STRING_LIST('search', 'new')
	);
	
	/*** EDIT COMPONENT ***/
	chain.card_pkg.RegisterCard(
		'Edit a component''s details.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/editComponent.js', 
		'Chain.Cards.EditComponent'
	);
	
	/*** SEARCH COMPONENT ***/
	chain.card_pkg.RegisterCard(
		'Search for an existing component.', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponents.js', 
		'Chain.Cards.SearchComponents'
	);
	
	/*** SEARCH COMPONENT SUPPLIER ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.SearchCompany extension for picking component suppliers', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponentSupplier.js', 
		'Chain.Cards.SearchComponentSupplier',
		chain.T_STRING_LIST('default', 'createnew')
	);
	
	
	/*** COMPONENT SOURCE ***/
	chain.card_pkg.RegisterCard(
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
		chain.card_pkg.GetProgressionActions('Chain.Cards.ComponentSource')
	);
	
	/*** NOT SURE ***/
	chain.card_pkg.RegisterCard(
		'Not sure - maybe we can help', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/notSure.js', 
		'Chain.Cards.NotSure'
	);
	
	/*** NOT SURE END POINT ***/
	chain.card_pkg.RegisterCard(
		'A friendly message thanking you for editting a not sure component', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/notSureEndPoint.js', 
		'Chain.Cards.NotSureEndPoint'
	);
	
	/*** COMPONENT BUILDER - COMPONENT SOURCE ***/
	chain.card_pkg.RegisterCard(
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
		chain.card_pkg.GetProgressionActions('Chain.Cards.ComponentBuilder.ComponentSource')
	);
	
	/*** COMPONENT BUILDER - IS PURCHASED ***/
	chain.card_pkg.RegisterCard(
		'Determines if the product is re-sold or manufactured', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/isPurchased.js', 
		'Chain.Cards.ComponentBuilder.IsPurchased'
	);
	
	/*** COMPONENT BUILDER - ADD COMPONENT ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.AddComponent extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addComponent.js', 
		'Chain.Cards.ComponentBuilder.AddComponent',
		chain.T_STRING_LIST('search', 'new', 'newpurchased')
	);	
	
	/*** COMPONENT BUILDER - SEARCH COMPONENT ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.SearchComponents extension for component builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/searchComponents.js', 
		'Chain.Cards.ComponentBuilder.SearchComponents'
	);

	/*** COMPONENT BUILDER - ADD SUPPLER ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.AddComponentSupplier extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addSupplier.js', 
		'Chain.Cards.ComponentBuilder.AddSupplier',
		chain.T_STRING_LIST('default', 'createnew')
	);	
	
	/*** COMPONENT BUILDER - CREATE SUPPLER ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.CreateCompany extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/createSupplier.js', 
		'Chain.Cards.ComponentBuilder.CreateSupplier'
	);	

	/*** COMPONENT BUILDER - ADD MORE CHILDREN ***/
	chain.card_pkg.RegisterCard(
		'Lists the child components of the current component and gives the option to add more', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addMoreChildren.js', 
		'Chain.Cards.ComponentBuilder.AddMoreChildren',
		chain.T_STRING_LIST('yes', 'no', 'finished')
	);

	/*** COMPONENT BUILDER - NOT SURE ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.NotSure extension with logic for comoponent builder', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/notSure.js', 
		'Chain.Cards.ComponentBuilder.NotSure'
	);

	/*** COMPONENT BUILDER - END POINT ***/
	chain.card_pkg.RegisterCard(
		'A friendly message thanking you for using the Component Builder wizard', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/endPoint.js', 
		'Chain.Cards.ComponentBuilder.EndPoint'
	);
	
	/*******************************************************************************************
		CHAIN TESTING CARDS
	*******************************************************************************************/
	
	chain.card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.TestingCardOne'
	);
	
	chain.card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.TestingCardTwo'
	);
	
	chain.card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.TestingCardThree'
	);

	chain.card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.TestingCardFour'
	);
	
	chain.card_pkg.RegisterCard(
		'A blank card used for testing', 
		'Credit360.Chain.Cards.Testing',
		'/csr/site/chain/cards/testingCards.js', 
		'Chain.Cards.ProgressionTestingCard',
		chain.T_STRING_LIST('trigger1', 'trigger2')
	);
end;
/


@update_tail