define version=102
@update_header

DECLARE
	v_card_id NUMBER;
BEGIN

	/*** SELF REG INVITATION CONFIRMATION 
	card_pkg.RegisterCard(
		'Confirms self registration invitation details with a potential new user', 
		'Credit360.Chain.Cards.QuestionnaireSelfRegInvitationConfirmation',
		'/csr/site/chain/cards/QuestionnaireSelfRegConfirmation.js', 
		'Chain.Cards.QuestionnaireSelfRegConfirmation',
		T_STRING_LIST('login', 'register', 'reject')
	);
	***/

	INSERT INTO chain.card
	(card_id, description, class_type, js_include, js_class_type, css_include)
	VALUES
	(chain.card_id_seq.NEXTVAL, 'Confirms self registration invitation details with a potential new user', 
		'Credit360.Chain.Cards.QuestionnaireSelfRegInvitationConfirmation', 
		'/csr/site/chain/cards/QuestionnaireSelfRegConfirmation.js', 'Chain.Cards.QuestionnaireSelfRegConfirmation', null)
	RETURNING card_id INTO v_card_id;

		
	INSERT INTO chain.card_progression_action
	(card_id, action)
	VALUES
	(v_card_id, LOWER(TRIM('login')));
	
	INSERT INTO chain.card_progression_action
	(card_id, action)
	VALUES
	(v_card_id, LOWER(TRIM('register')));

	
	INSERT INTO chain.card_progression_action
	(card_id, action)
	VALUES
	(v_card_id, LOWER(TRIM('reject')));


END;
	/
@update_tail