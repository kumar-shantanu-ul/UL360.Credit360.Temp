define host = '&&1'

begin
	security.user_pkg.logonadmin('&&host');

	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT security_pkg.getapp, csr.customer_alert_type_id_seq.nextval, std_alert_type_id 
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id = 5007;

	UPDATE chain.customer_options SET ALLOW_COMPANY_SELF_REG = 1 WHERE app_sid = security.security_pkg.getApp;
			
	chain.card_pkg.SetGroupCards('Questionnaire Self Registration Invitation Landing', chain.T_STRING_LIST(
		'Chain.Cards.QuestionnaireSelfRegConfirmation', 
		'Chain.Cards.Login',
		'Chain.Cards.RejectInvitation',
		'Chain.Cards.SelfRegistration'
	));
	
	chain.card_pkg.MarkTerminate('Questionnaire Self Registration Invitation Landing', 'Chain.Cards.Login');
	chain.card_pkg.MarkTerminate('Questionnaire Self Registration Invitation Landing', 'Chain.Cards.SelfRegistration');
	chain.card_pkg.MarkTerminate('Questionnaire Self Registration Invitation Landing', 'Chain.Cards.RejectInvitation');
	
	chain.card_pkg.RegisterProgression('Questionnaire Self Registration Invitation Landing', 'Chain.Cards.QuestionnaireSelfRegConfirmation', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		chain.T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		chain.T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));		

	dbms_output.put_line('Link is:   https://&&host/csr/site/chain/public/companyselfreg.acds');
end;
/

