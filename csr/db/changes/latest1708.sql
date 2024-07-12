-- Please update version.sql too -- this keeps clean builds in sync
define version=1708
@update_header

@@latest1708_packages

BEGIN	
	
	security.user_pkg.logonadmin;
	
	chain.temp_card_pkg.RegisterCardGroup(40, 'Company Invitation Wizard', 'Wizard for creating companies, adding user to them and invite them');
	
	-- AddCompanyByCT
	chain.temp_card_pkg.RegisterCard(
		'Choose between creating new company or searching for and selecting existing company by company type',
		'Credit360.Chain.Cards.CreateCompanyByCT',
		'/csr/site/chain/cards/addCompanyByCT.js', 
		'Chain.Cards.AddCompanyByCT'
	);
	
	-- ChooseNewOrNoContacts
	chain.temp_card_pkg.RegisterCard(
		'Choose between adding new contacts or proceeding without adding any contacts',
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/chooseNewOrNoContacts.js', 
		'Chain.Cards.ChooseNewOrNoContacts'
	);
	
	-- AddContacts
	chain.temp_card_pkg.RegisterCard(
		'Add new contacts',
		'Credit360.Chain.Cards.AddContacts',
		'/csr/site/chain/cards/addContacts.js', 
		'Chain.Cards.AddContacts'
	);
	
	--PersonalizeInvitationEmail
	chain.temp_card_pkg.RegisterCard(
		'Personalize invitation e-mail',
		'Credit360.Chain.Cards.PersonalizeInvitationEmail',
		'/csr/site/chain/cards/personalizeInvitationEmail.js', 
		'Chain.Cards.PersonalizeInvitationEmail'
	);

	chain.temp_card_pkg.AddProgressionAction('Chain.Cards.AddCompanyByCT', 'createnew');
	chain.temp_card_pkg.AddProgressionAction('Chain.Cards.ChooseNewOrNoContacts', 'createnew');
	chain.temp_card_pkg.AddProgressionAction('Chain.Cards.AddContacts', 'invite');
		
END;
/

DROP PACKAGE chain.temp_card_pkg;

@update_tail