PROMPT >> Registering Cards
BEGIN
	security.user_pkg.logonadmin;
	
	/*******************************************************************************************
		CHAIN GENERIC CARDS
	*******************************************************************************************/
	
	/*** ADD COMPANY ***/
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
	
	chain.card_pkg.RegisterCard(
		'Company card that allows you to create a new company with initial tags.', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/createCompanyWithTags.js', 
		'Chain.Cards.CreateCompanyWithTags'
	);
	
	chain.card_pkg.RegisterCard(
		'Card that allows you to set the initial tags of a new company.', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/createCompanyTags.js', 
		'Chain.Cards.CreateCompanyTags'
	);
	
	/*** ADD UNINVITED COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Add company card that allows you to create a new company.', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/createUninvitedCompany.js', 
		'Chain.Cards.CreateUninvitedCompany'
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
	
	chain.card_pkg.RegisterCard(
		'Edit a company''s company details including tags.', 
		'Credit360.Chain.Cards.EditCompany',
		'/csr/site/chain/cards/editCompanyWithTags.js', 
		'Chain.Cards.EditCompanyWithTags'
	);
	
	chain.card_pkg.RegisterCard(
		'Edit a company''s tags.', 
		'Credit360.Chain.Cards.EditCompanyTags',
		'/csr/site/chain/cards/editCompanyTags.js', 
		'Chain.Cards.EditCompanyTags'
	);
	
	/*** REFERENCE LABELS ***/
	chain.card_pkg.RegisterCard(
		'Company reference labels (with location set to display in ReferenceLabel card)', 
		'Credit360.Chain.Cards.CompanyReferenceLabel',
		'/csr/site/chain/cards/companyReferenceLabel.js', 
		'Chain.Cards.CompanyReferenceLabel'
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
		'Confirms questionnaire invitation details with a potential new user', 
		'Credit360.Chain.Cards.QuestionnaireInvitationConfirmation',
		'/csr/site/chain/cards/QuestionnaireInvitationConfirmation.js', 
		'Chain.Cards.QuestionnaireInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
	/*** STUB INVITATION CONFIRMATION ***/
	chain.card_pkg.RegisterCard(
		'Confirms stub invitation details with a potential new user', 
		'Credit360.Chain.Cards.StubInvitationConfirmation',
		'/csr/site/chain/cards/StubInvitationConfirmation.js', 
		'Chain.Cards.StubInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
	/*** SELF REG INVITATION CONFIRMATION ***/
	chain.card_pkg.RegisterCard(
		'Confirms self registration invitation details with a potential new user', 
		'Credit360.Chain.Cards.QuestionnaireSelfRegInvitationConfirmation',
		'/csr/site/chain/cards/QuestionnaireSelfRegConfirmation.js', 
		'Chain.Cards.QuestionnaireSelfRegConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
	chain.card_pkg.RegisterCard(
		'Extra details for the given supplier', 
		'Credit360.Chain.Cards.CsrSupplierExtras',
		'/csr/site/chain/cards/csrSupplierExtras.js', 
		'Chain.Cards.CsrSupplierExtras'
	);

	/*** REJECT REGISTER LOGIN ***/
	/*chain.card_pkg.RegisterCard(
		'Allows a new user to reject an invitation, self register or login via an invitation', 
		'Credit360.Chain.Cards.RejectRegisterInvitation',
		'/csr/site/chain/cards/rejectRegisterLogin.js', 
		'Chain.Cards.RejectRegisterLogin'
	);*/
	
	/*** LOGIN ***/
	chain.card_pkg.RegisterCard(
		'Login card that allows an invited user to log in with existing credentials.', 
		'Credit360.Chain.Cards.LoginInvitation',
		'/csr/site/chain/cards/login.js', 
		'Chain.Cards.Login'
	);
	
	/*** REJECT ***/
	chain.card_pkg.RegisterCard(
		'Reject invitation if not an employee or not a supplier', 
		'Credit360.Chain.Cards.RejectInvitation',
		'/csr/site/chain/cards/rejectInvitation.js', 
		'Chain.Cards.RejectInvitation'
	);
	
	/*** REGISTER ***/
	chain.card_pkg.RegisterCard(
		'Register a new chain user', 
		'Credit360.Chain.Cards.SelfRegister',
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
	
	/*** TASK BROWSER ***/
	chain.card_pkg.RegisterCard(
		'Displays tasks for a particular supplier', 
		'Credit360.Chain.Cards.IssuesBrowser',
		'/csr/site/chain/cards/issuesBrowser.js', 
		'Chain.Cards.IssuesBrowser'
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
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/searchComponentSupplier.js', 
		'Chain.Cards.SearchComponentSupplier',
		chain.T_STRING_LIST('default', 'createnew')
	);
	
	
	/*** ADD COMPONENT WANT TO INVITE COMPANY ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.ComponentSupplierWantToInvite extension for deciding wether to add component supplier user to existing company', 
		'Credit360.Chain.Cards.ComponentSupplierWantToInvite',
		'/csr/site/chain/cards/componentSupplierWantToInvite.js', 
		'Chain.Cards.ComponentSupplierWantToInvite',
		chain.T_STRING_LIST('existing-comp-invite', 'new-comp-invite', 'no-invite')
	);
	
	/*** USER SEARCH - COPE WITH UNACCEPTED USERS ***/
	chain.card_pkg.RegisterCard(
		'Chain.Cards.AddComponentSupplierUsers extension for deciding wether to add component supplier user to existing company', 
		'Credit360.Chain.Cards.AddUser',
		'/csr/site/chain/cards/addComponentSupplierUsers.js', 
		'Chain.Cards.AddComponentSupplierUsers',
		chain.T_STRING_LIST('default', 'createnew')
	);
	
	/*** PURCHASED COMPONENT SUMMARY PAGE ***/
	chain.card_pkg.RegisterCard(
		'Purchased Component summary page', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/purchasedComponentSummary.js', 
		'Chain.Cards.PurchasedComponentSummary'
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
		'Credit360.Chain.Cards.AddCompany',
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
	
	
	/*** TaskCardManagerR - Invitation Card ***/
	chain.card_pkg.RegisterCard(
		'Task Invitation Card for use with the TaskCardManager', 
		'Credit360.Chain.Cards.Tasks.Invitation',
		'/csr/site/chain/cards/task/invitation.js', 
		'Chain.Cards.Tasks.Invitation'
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Core Company Filter', 
		'Credit360.Chain.Cards.Filters.CompanyCore',
		'/csr/site/chain/cards/filters/companyCore.js', 
		'Chain.Cards.Filters.CompanyCore'
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Core Company Filter', 
		'Credit360.Chain.Cards.Filters.CompanyTagsFilter',
		'/csr/site/chain/cards/filters/companyTagsFilter.js', 
		'Chain.Cards.Filters.CompanyTagsFilter'
	);	
	
/*	chain.card_pkg.RegisterCard(
		'Chain Core Company Product Filter', 
		'Credit360.Chain.Cards.Filters.CompanyProductFilter',
		'/csr/site/chain/cards/filters/companyProductFilter.js', 
		'Chain.Cards.Filters.CompanyProductFilter'
	);*/
	
	chain.card_pkg.RegisterCard(
		'Chain Company Relationship Filter', 
		'Credit360.Chain.Cards.Filters.CompanyRelationshipFilter',
		'/csr/site/chain/cards/filters/companyRelationshipFilter.js', 
		'Chain.Cards.Filters.CompanyRelationshipFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Company Audit Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyAuditFilterAdapter',
		'/csr/site/chain/cards/filters/companyAuditFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyAuditFilterAdapter'		
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Company Business Relationship Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter',
		'/csr/site/chain/cards/filters/companyBusinessRelationshipFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter'		
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Company CMS Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyCmsFilterAdapter',
		'/csr/site/chain/cards/filters/companyCmsFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyCmsFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Chain Product CMS Adapter', 
		'Credit360.Chain.Cards.Filters.ProductCmsFilterAdapter',
		'/csr/site/chain/cards/filters/productCmsFilterAdapter.js', 
		'Chain.Cards.Filters.ProductCmsFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Survey Questionnaire Filter', 
		'Credit360.Chain.Cards.Filters.SurveyQuestionnaire',
		'/csr/site/chain/cards/filters/surveyQuestionnaire.js', 
		'Chain.Cards.Filters.SurveyQuestionnaire'
	);
	
	chain.card_pkg.RegisterCard(
		'Survey Campaign Filter', 
		'Credit360.Chain.Cards.Filters.SurveyCampaign',
		'/csr/site/chain/cards/filters/surveyCampaign.js', 
		'Chain.Cards.Filters.SurveyCampaign'
	);
	
	chain.card_pkg.RegisterCard(
		'Dummy Survey Filter', 
		'Credit360.QuickSurvey.Cards.SurveyResultsFilter',
		'/csr/site/QuickSurvey/results/surveyResultsFilter.js', 
		'QuickSurvey.Cards.SurveyResultsFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Issues Filter', 
		'Credit360.Issues.Cards.StandardIssuesFilter',
		'/csr/site/issues/IssuesFilter.jsi', 
		'Credit360.Filters.Issues.StandardIssuesFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Issue Custom Fields Filter', 
		'Credit360.Issues.Cards.IssuesCustomFieldsFilter',
		'/csr/site/issues/IssuesFilter.jsi', 
		'Credit360.Filters.Issues.IssuesCustomFieldsFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Issue Filter Adapter', 
		'Credit360.Issues.Cards.IssuesFilterAdapter',
		'/csr/site/issues/IssuesFilter.jsi', 
		'Credit360.Filters.Issues.IssuesFilterAdapter'
	);
	
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
	
	chain.card_pkg.RegisterCard(
		'Displays a list of company types that the user can send an invitation to, including on behalf of',
		'Credit360.Chain.Cards.InviteCompanyType',
		'/csr/site/chain/cards/inviteCompanyType.js', 
		'Chain.Cards.InviteCompanyType'
	);
	
	chain.card_pkg.RegisterCard(
		'Add existing suppliers',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addExistingSuppliers.js',
		'Chain.Cards.AddExistingSuppliers'
	);
	
	chain.card_pkg.RegisterCard(
		'Add existing users',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/addExistingUsers.js',
		'Chain.Cards.AddExistingUsers'
	);
	
		-- AddCompanyByCT
	chain.card_pkg.RegisterCard(
		'Choose between creating new company or searching for and selecting existing company by company type',
		'Credit360.Chain.Cards.CreateCompanyByCT',
		'/csr/site/chain/cards/addCompanyByCT.js', 
		'Chain.Cards.AddCompanyByCT',
		chain.T_STRING_LIST('createnew')
	);
	
	-- ChooseNewOrNoContacts
	chain.card_pkg.RegisterCard(
		'Choose between adding new contacts or proceeding without adding any contacts',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/chooseNewOrNoContacts.js', 
		'Chain.Cards.ChooseNewOrNoContacts',
		chain.T_STRING_LIST('createnew')
	);
	
	-- AddContacts
	chain.card_pkg.RegisterCard(
		'Add new contacts',
		'Credit360.Chain.Cards.AddContacts',
		'/csr/site/chain/cards/addContacts.js', 
		'Chain.Cards.AddContacts',
		chain.T_STRING_LIST('createnew', 'invite')
	);
	
	--PersonalizeInvitationEmail
	chain.card_pkg.RegisterCard(
		'Personalize invitation e-mail',
		'Credit360.Chain.Cards.PersonalizeInvitationEmail',
		'/csr/site/chain/cards/personalizeInvitationEmail.js', 
		'Chain.Cards.PersonalizeInvitationEmail'
	);
	
	-- Create Company card
	chain.card_pkg.RegisterCard(
		'Company basic data including company type',
		'Credit360.Chain.Cards.CreateCompanyByCT',
		'/csr/site/chain/cards/createCompanyByCT.js', 
		'Chain.Cards.CreateCompanyByCT'
	);
	
	-- Supplier relationships card
	chain.card_pkg.RegisterCard(
		'Supplier relationships',
		'Credit360.Chain.Cards.SupplierRelationship',
		'/csr/site/chain/cards/supplierRelationship.js', 
		'Chain.Cards.SupplierRelationship'
	); 
	
	--Company invitation confirmation
	chain.card_pkg.RegisterCard(
		'Confirms company invitation details with a potential new user', 
		'Credit360.Chain.Cards.CompanyInvitationConfirmation',
		'/csr/site/chain/cards/CompanyInvitationConfirmation.js', 
		'Chain.Cards.CompanyInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);

	-- Questionnaire security
	chain.card_pkg.RegisterCard(
		'Allows viewing and editing of questionnaire security', 
		'Credit360.Chain.Cards.QuestionnaireSecurity',
		'/csr/site/chain/cards/questionnaireSecurity.js', 
		'Chain.Cards.QuestionnaireSecurity',
		''
	);

	--Company extra details (blank for now)
	chain.card_pkg.RegisterCard(
		'Search for suppliers.',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/extraDetails.js',
		'Chain.Cards.ExtraDetails'
	);

	chain.card_pkg.RegisterCard(
		'Internal Audit Filter', 
		'Credit360.Audit.Cards.InternalAuditFilter',
		'/csr/site/audit/internalAuditFilter.js', 
		'Credit360.Audit.Filters.InternalAuditFilter'
	);	

	chain.card_pkg.RegisterCard(
		'Internal Audit Filter Adapter', 
		'Credit360.Audit.Cards.AuditFilterAdapter',
		'/csr/site/audit/auditFilterAdapter.js', 
		'Credit360.Audit.Filters.AuditFilterAdapter'
	);	

	chain.card_pkg.RegisterCard(
		'Internal Audit CMS Filter', 
		'Credit360.Audit.Cards.AuditCMSFilter',
		'/csr/site/audit/auditCMSFilter.js', 
		'Credit360.Audit.Filters.AuditCMSFilter'
	);	

	chain.card_pkg.RegisterCard(
		'Non-compliance Filter', 
		'Credit360.Audit.Cards.NonComplianceFilter',
		'/csr/site/audit/nonComplianceFilter.js', 
		'Credit360.Audit.Filters.NonComplianceFilter'
	);

	chain.card_pkg.RegisterCard(
		'Non-compliance Filter Adapter', 
		'Credit360.Audit.Cards.NonComplianceFilterAdapter',
		'/csr/site/audit/nonComplianceFilterAdapter.js', 
		'Credit360.Audit.Filters.NonComplianceFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Cms Filter', 
		'NPSL.Cms.Cards.CmsFilter',
		'/fp/cms/filters/CmsFilter.js', 
		'NPSL.Cms.Filters.CmsFilter'
	);

	chain.card_pkg.RegisterCard(
		'Property Filter', 
		'Credit360.Property.Cards.PropertyFilter',
		'/csr/site/property/properties/filters/PropertyFilter.js', 
		'Credit360.Property.Filters.PropertyFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Property CMS Filter', 
		'Credit360.Property.Cards.PropertyCmsFilter',
		'/csr/site/property/properties/filters/PropertyCmsFilter.js', 
		'Credit360.Property.Filters.PropertyCmsFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Property Issues Filter', 
		'Credit360.Property.Cards.PropertyIssuesFilter',
		'/csr/site/property/properties/filters/PropertyIssuesFilter.js', 
		'Credit360.Property.Filters.PropertyIssuesFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Initiative Filter', 
		'Credit360.Initiatives.Cards.InitiativeFilter',
		'/csr/site/initiatives/filters/InitiativeFilter.js', 
		'Credit360.Initiatives.Filters.InitiativeFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Meter Data Filter', 
		'Credit360.Metering.Cards.MeterDataFilter',
		'/csr/site/meter/filters/MeterDataFilter.js', 
		'Credit360.Metering.Filters.MeterDataFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Meter Filter', 
		'Credit360.Metering.Cards.MeterFilter',
		'/csr/site/meter/filters/MeterFilter.js', 
		'Credit360.Metering.Filters.MeterFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'User Data Filter', 
		'Credit360.Schema.Cards.UserDataFilter',
		'/csr/site/users/list/filters/UserDataFilter.js', 
		'Credit360.Users.Filters.UserDataFilter'
	);

	chain.card_pkg.RegisterCard(
		'User CMS Adapter', 
		'Credit360.Schema.Cards.UserCmsFilterAdapter',
		'/csr/site/users/list/filters/UserCmsFilterAdapter.js', 
		'Credit360.Users.Filters.UserCmsFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Compliance Library Filter', 
		'Credit360.Compliance.Cards.ComplianceLibraryFilter',
		'/csr/site/compliance/filters/ComplianceLibraryFilter.js', 
		'Credit360.Compliance.Filters.ComplianceLibraryFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Compliance Legal Register Filter', 
		'Credit360.Compliance.Cards.LegalRegisterFilter',
		'/csr/site/compliance/filters/LegalRegisterFilter.js', 
		'Credit360.Compliance.Filters.LegalRegisterFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Compliance Permit Filter', 
		'Credit360.Compliance.Cards.PermitFilter',
		'/csr/site/compliance/filters/PermitFilter.js', 
		'Credit360.Compliance.Filters.PermitFilter'
	);

	chain.card_pkg.RegisterCard(
		'Permit CMS Adapter', 
		'Credit360.Compliance.Cards.PermitCmsFilterAdapter',
		'/csr/site/compliance/filters/PermitCmsFilterAdapter.js', 
		'Credit360.Compliance.Filters.PermitCmsFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Survey Response Filter', 
		'Credit360.Audit.Cards.SurveyResponse',
		'/csr/site/audit/surveyResponse.js', 
		'Credit360.Audit.Filters.SurveyResponse'
	);
	
	chain.card_pkg.RegisterCard(
		'Region Filter', 
		'Credit360.Schema.Cards.RegionFilter',
		'/csr/site/schema/indregion/list/filters/regionfilter.js', 
		'Credit360.Region.Filters.RegionFilter'
	);

	chain.card_pkg.RegisterCard(
		'Activity Filter', 
		'Credit360.Chain.Cards.Filters.ActivityFilter',
		'/csr/site/chain/cards/filters/activityFilter.js', 
		'Chain.Cards.Filters.ActivityFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Activity Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ActivityFilterAdapter',
		'/csr/site/chain/cards/filters/activityFilterAdapter.js', 
		'Chain.Cards.Filters.ActivityFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Business Relationship Filter', 
		'Credit360.Chain.Cards.Filters.BusinessRelationshipFilter',
		'/csr/site/chain/cards/filters/businessRelationshipFilter.js', 
		'Chain.Cards.Filters.BusinessRelationshipFilter'
	);

	chain.card_pkg.RegisterCard(
		'Business Relationship Filter Adapter', 
		'Credit360.Chain.Cards.Filters.BusinessRelationshipFilterAdapter',
		'/csr/site/chain/cards/filters/businessRelationshipFilterAdapter.js', 
		'Chain.Cards.Filters.BusinessRelationshipFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Company Certification Filter', 
		'Credit360.Chain.Cards.Filters.CertificationFilter',
		'/csr/site/chain/cards/filters/certificationFilter.js', 
		'Chain.Cards.Filters.CertificationFilter'
	);

	chain.card_pkg.RegisterCard(
		'Company Certification Filter Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyCertificationFilterAdapter',
		'/csr/site/chain/cards/filters/companyCertificationFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyCertificationFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Certification Company Filter Adapter', 
		'Credit360.Chain.Cards.Filters.CertificationCompanyFilterAdapter',
		'/csr/site/chain/cards/filters/certificationCompanyFilterAdapter.js', 
		'Chain.Cards.Filters.CertificationCompanyFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Product Filter', 
		'Credit360.Chain.Cards.Filters.ProductFilter',
		'/csr/site/chain/cards/filters/productFilter.js', 
		'Chain.Cards.Filters.ProductFilter'
	);

	chain.card_pkg.RegisterCard(
		'Product Filter Company Adapter', 
		'Credit360.Chain.Cards.Filters.ProductCompanyFilterAdapter',
		'/csr/site/chain/cards/filters/productCompanyFilterAdapter.js', 
		'Credit360.Chain.Filters.ProductCompanyFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Product Filter Supplier Adapter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierFilterAdapter',
		'/csr/site/chain/cards/filters/productSupplierFilterAdapter.js', 
		'Credit360.Chain.Filters.ProductSupplierFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Survey Response Filter', 
		'Credit360.QuickSurvey.Cards.SurveyResponseFilter',
		'/csr/site/quickSurvey/filters/surveyResponseFilter.js', 
		'Credit360.QuickSurvey.Filters.SurveyResponseFilter'
	);

	chain.card_pkg.RegisterCard(
		'Survey Response Audit Filter Adapter', 
		'Credit360.QuickSurvey.Cards.SurveyResponseAuditFilterAdapter',
		'/csr/site/quickSurvey/filters/surveyResponseAuditFilterAdapter.js', 
		'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Dedupe Processed Record Filter', 
		'Credit360.Chain.Cards.Filters.DedupeProcessedRecordFilter',
		'/csr/site/chain/dedupe/filters/processedRecordFilter.js', 
		'Chain.dedupe.filters.ProcessedRecordFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Product Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ProductFilterAdapter',
		'/csr/site/chain/cards/filters/productFilterAdapter.js', 
		'Chain.Cards.Filters.ProductFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Company Product Filter Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyProductFilterAdapter',
		'/csr/site/chain/cards/filters/companyProductFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyProductFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Product Supplier Filter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierFilter',
		'/csr/site/chain/cards/filters/productSupplierFilter.js', 
		'Chain.Cards.Filters.ProductSupplierFilter'
	);

	chain.card_pkg.RegisterCard(
		'Company Request Filter', 
		'Credit360.Chain.Cards.Filters.CompanyRequestFilter',
		'/csr/site/chain/companyRequest/filters/CompanyRequestFilter.js', 
		'Chain.companyRequest.filters.CompanyRequestFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Product Supplier Company Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter',
		'/csr/site/chain/cards/filters/productSupplierCompanyFilterAdapter.js', 
		'Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Product Supplier Product Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierProductFilterAdapter',
		'/csr/site/chain/cards/filters/productSupplierProductFilterAdapter.js', 
		'Chain.Cards.Filters.ProductSupplierProductFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Permit Audit Filter Adapter', 
		'Credit360.Compliance.Cards.PermitAuditFilterAdapter',
		'/csr/site/compliance/filters/permitAuditFilterAdapter.js', 
		'Credit360.Compliance.Filters.PermitAuditFilterAdapter'		
	);

	chain.card_pkg.RegisterCard(
		'Product Metric Value Filter', 
		'Credit360.Chain.Cards.Filters.ProductMetricValFilter',
		'/csr/site/chain/cards/filters/productMetricValFilter.js', 
		'Chain.Cards.Filters.ProductMetricValFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Product Metric Value Product Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ProductMetricValProductFilterAdapter',
		'/csr/site/chain/cards/filters/productMetricValProductFilterAdapter.js', 
		'Chain.Cards.Filters.ProductMetricValProductFilterAdapter'
	);

	chain.card_pkg.RegisterCard(
		'Product Supplier Metric Value Filter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierMetricValFilter',
		'/csr/site/chain/cards/filters/productSupplierMetricValFilter.js', 
		'Chain.Cards.Filters.ProductSupplierMetricValFilter'
	);
	
	chain.card_pkg.RegisterCard(
		'Product Supplier Metric Value Product Supplier Filter Adapter', 
		'Credit360.Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter',
		'/csr/site/chain/cards/filters/productSupplierMetricValProductSupplierFilterAdapter.js', 
		'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter'
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
	
	chain.card_pkg.RegisterCard(
		'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
		'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation',
		'/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js', 
		'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
	chain.card_pkg.RegisterCard(
		'Questionnaire (Type) selection card for various invite wizards.',
		'Credit360.Chain.Cards.QuestionnaireTypeSelect',
		'/csr/site/chain/cards/questionnaireTypeSelect.js',
		'Chain.Cards.QuestionnaireTypeSelect'
	);	

	chain.card_pkg.RegisterCard(
		'Creates business relationships when inviting a company', 
		'Credit360.Chain.Cards.AddBusinessRelationship',
		'/csr/site/chain/cards/addBusinessRelationship.js', 
		'Chain.Cards.AddBusinessRelationship'
	);

	chain.card_pkg.RegisterCard(
		'Integration Question Answer Filter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilter',
		'/csr/site/audit/IntegrationQuestionAnswerFilter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'
	);

	chain.card_pkg.RegisterCard(
		'Integration Question Answer Filter Adapter', 
		'Credit360.Audit.Cards.IntegrationQuestionAnswerFilterAdapter',
		'/csr/site/audit/IntegrationQuestionAnswerFilterAdapter.js', 
		'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'
	);
	
	chain.card_pkg.RegisterCard(
		'Sheet Filter', 
		'Credit360.Delegation.Cards.SheetDataFilter',
		'/csr/site/delegation/sheet2/list/filters/DataFilter.js', 
		'Credit360.Delegation.Sheet.Filters.DataFilter'
	);

	-- BSCI is now obsolete.
	-- The C:\GitHub\UL360.Credit360\csr\db\chain\basedata\grid_exensions.sql file has the GRID_EXTENSION records for BSCI
	-- commented out too, as they depend on these cards.
	/*
	chain.card_pkg.RegisterCard(
		'BSCI Supplier Filter', 
		'Credit360.Chain.Cards.Filters.BsciSupplierFilter',
		'/csr/site/chain/cards/filters/bsciSupplierFilter.js', 
		'Chain.Cards.Filters.BsciSupplierFilter'
	);
 
	chain.card_pkg.RegisterCard(
		'BSCI 2009 Audit Filter', 
		'Credit360.Chain.Cards.Filters.Bsci2009AuditFilter',
		'/csr/site/chain/cards/filters/bsci2009AuditFilter.js', 
		'Chain.Cards.Filters.Bsci2009AuditFilter'
	);
 
	chain.card_pkg.RegisterCard(
		'BSCI 2014 Audit Filter', 
		'Credit360.Chain.Cards.Filters.Bsci2014AuditFilter',
		'/csr/site/chain/cards/filters/bsci2014AuditFilter.js', 
		'Chain.Cards.Filters.Bsci2014AuditFilter'
	);
 
	chain.card_pkg.RegisterCard(
		'BSCI External Audit Filter', 
		'Credit360.Chain.Cards.Filters.BsciExternalAuditFilter',
		'/csr/site/chain/cards/filters/bsciExternalAuditFilter.js', 
		'Chain.Cards.Filters.BsciExternalAuditFilter'
	);
	*/
END;
/
