define version=65
@update_header

@latest65_packages

exec user_pkg.LogonAdmin;

BEGIN

chain.card_pkg.RegisterCard(
	'Add company card that allows you to create a new company.', 
	'Credit360.Chain.Cards.CreateCompany',
	'/csr/site/chain/cards/createCompany.js', 
	'Chain.Cards.CreateCompany'
);
	
chain.card_pkg.RegisterCard(
	'Add user card that allows you to add a new user to a company.', 
	'Credit360.Chain.Cards.Empty',
	'/csr/site/chain/cards/createUser.js', 
	'Chain.Cards.CreateUser'
);

		
chain.card_pkg.RegisterCard(
	'Add company card that first prompts you to search for an existing company and then allows you to create a new one if you wish.', 
	'Credit360.Chain.Cards.AddCompany',
	'/csr/site/chain/cards/addCompany.js', 
	'Chain.Cards.AddCompany',
	chain.T_STRING_LIST('createnew')
);

chain.card_pkg.RegisterCard(
	'Add user card that first prompts you to search for an existing user and then allows you to create a new one if you wish. Depends on Chain.Cards.AddCompany.', 
	'Credit360.Chain.Cards.AddUser',
	'/csr/site/chain/cards/addUser.js', 
	'Chain.Cards.AddUser',
	chain.T_STRING_LIST('createnew')
);

chain.card_pkg.RegisterCard(
	'Confirms questionnaire intvitation details with a potential new user', 
	'Credit360.Chain.Cards.QuestionnaireInvitationConfirmation',
	'/csr/site/chain/cards/QuestionnaireInvitationConfirmation.js', 
	'Chain.Cards.QuestionnaireInvitationConfirmation',
	chain.T_STRING_LIST('login', 'register', 'reject')
);

chain.card_pkg.RegisterCard(
	'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
	'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation',
	'/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js', 
	'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
	chain.T_STRING_LIST('login', 'register', 'reject')
);

chain.card_pkg.RegisterCard(
	'Login card that allows an invited user to log in with existing credentials.', 
	'Credit360.Chain.Cards.RejectRegisterInvitation',
	'/csr/site/chain/cards/login.js', 
	'Chain.Cards.Login'
);

chain.card_pkg.RegisterCard(
	'Reject invitation if not an employee or not a supplier', 
	'Credit360.Chain.Cards.RejectRegisterInvitation',
	'/csr/site/chain/cards/rejectInvitation.js', 
	'Chain.Cards.RejectInvitation'
);

chain.card_pkg.RegisterCard(
	'Register a new chain user', 
	'Credit360.Chain.Cards.RejectRegisterInvitation',
	'/csr/site/chain/cards/selfRegistration.js', 
	'Chain.Cards.SelfRegistration'
);

chain.card_pkg.RegisterCard(
	'Confirmation page for inviting a new supplier', 
	'Credit360.Chain.Cards.Empty',
	'/csr/site/chain/cards/invitationSummary.js', 
	'Chain.Cards.InvitationSummary'
);
END;
/

@update_tail