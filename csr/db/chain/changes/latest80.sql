define version=80
@update_header

CREATE OR REPLACE VIEW chain.v$card_manager AS
	SELECT cgc.app_sid, cg.card_group_id, cg.name card_group_name, c.js_class_type, c.class_type, cgc.position
	  FROM chain.card_group cg, chain.card_group_card cgc, chain.card c
	 WHERE cgc.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), cgc.app_sid)
	   AND cgc.card_group_id = cg.card_group_id
	   AND cgc.card_id = c.card_id
	 ORDER BY cgc.card_group_id, cgc.app_sid, cgc.position
;


BEGIN

	user_pkg.logonadmin;
	
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
END;
/

@update_tail