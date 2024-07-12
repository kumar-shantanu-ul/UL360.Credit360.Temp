-- Please update version.sql too -- this keeps clean builds in sync
define version=615
@update_header

connect chain/chain@&_CONNECT_IDENTIFIER

DECLARE
	v_count			NUMBER(10);
	v_js_class		chain.card.js_class_type%TYPE;
BEGIN
	
	FOR r IN (
		SELECT * FROM chain.v$chain_host WHERE chain.chain_implementation LIKE 'CSR.%'
	) LOOP
	
		user_pkg.logonadmin(r.host);
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM chain.card_group cg, chain.card_group_card cgc
		 WHERE cgc.card_group_id = cg.card_group_id
		   AND cg.name = 'Questionnaire Invitation Wizard'
		   AND cgc.app_sid = r.app_sid;
	
		IF v_count <> 2 THEN
			RAISE_APPLICATION_ERROR(-20001, 'VALIDATION CHECK: Expected exactly two cards in "Questionnaire Invitation Wizard" on '||r.host);
		END IF;
	
		chain.card_pkg.SetGroupCards('Questionnaire Invitation Wizard', T_STRING_LIST(
			'Chain.Cards.AddCompany', -- createnew or default
			'Chain.Cards.CreateCompany',
			'Chain.Cards.AddUser',
			'Chain.Cards.CreateUser',
			'Chain.Cards.InvitationSummary'
		));
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', T_CARD_ACTION_LIST(
			T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'),
			T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')
		));
		
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', T_CARD_ACTION_LIST(
			T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'),
			T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')
		));

		
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.CreateCompany', 'Chain.Cards.CreateUser');
		
		chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.Login');
		chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.SelfRegistration');
		chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.RejectInvitation');
		
	END LOOP;
END;
/

connect csr/csr@&_CONNECT_IDENTIFIER

@update_tail
