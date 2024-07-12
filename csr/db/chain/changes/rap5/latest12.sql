define rap5_version=12
@update_header

begin
	FOR r IN (
		SELECT app_sid, site_name
		  FROM chain.customer_options
		 WHERE chain_implementation IN ('deutschebank', 'eicc.credit360.com')
	) 
	LOOP
		user_pkg.LogonAdmin;
		security_pkg.SetACT(security_pkg.GetACT, r.app_sid);

		card_pkg.RegisterCard(
			'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
			'Credit360.Chain.Cards.QuestionnaireInvitationConfirmation',
			'/csr/site/chain/cards/QuestionnaireInvitationConfirmation.js', 
			'Chain.Cards.QuestionnaireInvitationConfirmation',
			T_STRING_LIST('login', 'register', 'reject')
		);
		card_pkg.SetGroupCards(
				'Questionnaire Invitation Landing', 
				T_STRING_LIST(
					'Chain.Cards.QuestionnaireInvitationConfirmation',
					'Chain.Cards.Login',
					'Chain.Cards.RejectInvitation',
					'Chain.Cards.SelfRegistration'
				)
		);
		card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.QuestionnaireInvitationConfirmation', T_CARD_ACTION_LIST(
			T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
			T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
			T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
		));
		
		-- From /csr/db/util/EnableChain
		card_pkg.SetGroupCards('Questionnaire Invitation Wizard', T_STRING_LIST('Chain.Cards.AddCompany', 'Chain.Cards.CreateCompany', 'Chain.Cards.AddUser', 'Chain.Cards.CreateUser', 'Chain.Cards.InvitationSummary'));	
		card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', T_CARD_ACTION_LIST(T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'), T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')));	
		card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', T_CARD_ACTION_LIST(T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'), T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')));

		card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain_pkg.CT_COMPANY, chain_pkg.CREATE_USER);
		card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION);
		card_pkg.SetGroupCards('Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.TaskBrowser'));
		card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
	
	END LOOP;
end;
/

begin
	FOR r IN (
		SELECT app_sid, site_name
		  FROM chain.customer_options
		 WHERE chain_implementation IN ('CSR.HAMMERSON', 'CSR.WHISTLER')
	) 
	LOOP
		user_pkg.LogonAdmin;
		security_pkg.SetACT(security_pkg.GetACT, r.app_sid);

		card_pkg.RegisterCard(
			'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
			'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation',
			'/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js', 
			'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
			T_STRING_LIST('login', 'register', 'reject')
		);
		card_pkg.SetGroupCards(
				'Questionnaire Invitation Landing', 
				T_STRING_LIST(
					'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
					'Chain.Cards.Login',
					'Chain.Cards.RejectInvitation',
					'Chain.Cards.SelfRegistration'
				)
		);
		card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.CSRQuestionnaireInvitationConfirmation', T_CARD_ACTION_LIST(
			T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
			T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
			T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
		));
		
		-- From /csr/db/util/EnableChain
		card_pkg.SetGroupCards('Questionnaire Invitation Wizard', T_STRING_LIST('Chain.Cards.AddCompany', 'Chain.Cards.CreateCompany', 'Chain.Cards.AddUser', 'Chain.Cards.CreateUser', 'Chain.Cards.InvitationSummary'));	
		card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', T_CARD_ACTION_LIST(T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'), T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')));	
		card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', T_CARD_ACTION_LIST(T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'), T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')));

		card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain_pkg.CT_COMPANY, chain_pkg.CREATE_USER);
		card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION);
		card_pkg.SetGroupCards('Supplier Details', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.TaskBrowser'));
		card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
	
	END LOOP;
end;
/


@update_tail