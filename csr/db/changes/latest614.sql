-- Please update version.sql too -- this keeps clean builds in sync
define version=614
@update_header

connect chain/chain@&_CONNECT_IDENTIFIER

DECLARE
	v_count			NUMBER(10);
	v_js_class		chain.card.js_class_type%TYPE;
BEGIN
	
	FOR r IN (
		SELECT * FROM chain.v$chain_host WHERE chain_implementation LIKE 'CSR.%'
	) LOOP
	
		user_pkg.logonadmin(r.host);
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM chain.card_group cg, chain.card_group_card cgc
		 WHERE cgc.card_group_id = cg.card_group_id
		   AND cg.name = 'Questionnaire Invitation Landing'
		   AND cgc.app_sid = r.app_sid;
	
		IF v_count <> 2 THEN
			RAISE_APPLICATION_ERROR(-20001, 'VALIDATION CHECK: Expected exactly two cards in "Questionnaire Invitation Landing" on '||r.host);
		END IF;
	
		FOR c IN (
			SELECT c.js_class_type, cgc.position
			  FROM chain.card c, chain.card_group cg, chain.card_group_card cgc
			 WHERE c.card_id = cgc.card_id
			   AND cgc.card_group_id = cg.card_group_id
			   AND cg.name = 'Questionnaire Invitation Landing'
			   AND cgc.app_sid = r.app_sid
		) LOOP			
			IF c.position = 0 THEN
				v_js_class := c.js_class_type;
			ELSIF c.position = 1 AND c.js_class_type <> 'Chain.Cards.RejectRegisterLogin' THEN
				RAISE_APPLICATION_ERROR(-20001, 'VALIDATION CHECK: '||r.host||' does not use "Chain.Cards.RejectRegisterLogin" as it''s second card');
			END IF;			
		END LOOP;
		
		chain.card_pkg.AddProgressionAction(v_js_class, 'reject');
		chain.card_pkg.AddProgressionAction(v_js_class, 'register');
		chain.card_pkg.AddProgressionAction(v_js_class, 'login');
		
		-- register your card in the card manager
		chain.card_pkg.SetGroupCards('Questionnaire Invitation Landing', chain.T_STRING_LIST(
			v_js_class,
			'Chain.Cards.Login',
			'Chain.Cards.RejectInvitation',
			'Chain.Cards.SelfRegistration'
		));
		
		-- set progression actions
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Landing', v_js_class, chain.T_CARD_ACTION_LIST(
			chain.T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
			chain.T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
			chain.T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
		));
		
	END LOOP;
END;
/

connect csr/csr@&_CONNECT_IDENTIFIER

@update_tail
