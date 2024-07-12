-- Please update version.sql too -- this keeps clean builds in sync
define version=580
@update_header

DECLARE
	v_version	version.db_version%TYPE;
	v_required	version.db_version%TYPE := 55;
BEGIN
	-- ummm-- I guess it might not yet have added 'part' to the table
	-- run with MAX on the basis that if another part other than trunk > 55 then it'll 
	-- be way beyond trunk = 55
	SELECT MAX(db_version) INTO v_version FROM chain.version;
	IF v_version < v_required THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO AN ***CHAIN*** DATABASE OF VERSION '||v_version||' - VERSION '||v_required||' REQUIRED (cvs\csr\actions\changes) =======');
	END IF;
END;
/

ALTER TABLE CUSTOMER ADD (
	CHAIN_INVITE_LANDING_PREABLE     VARCHAR2(4000),
    CHAIN_INVITE_LANDING_QSTN        VARCHAR2(4000)
);


connect chain/chain@&_CONNECT_IDENTIFIER

BEGIN
	user_pkg.logonadmin;
	
	card_pkg.RegisterCard(
		'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
		'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation',
		'/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js', 
		'Chain.Cards.CSRQuestionnaireInvitationConfirmation'
	);
	
	FOR r IN (
		SELECT host FROM v$chain_host WHERE chain_implementation LIKE 'CSR.%'
	) LOOP
		user_pkg.logonadmin(r.host);
		
		card_pkg.SetGroupCards('Questionnaire Invitation Landing', T_STRING_LIST(
			'Chain.Cards.CSRQuestionnaireInvitationConfirmation', 
			'Chain.Cards.RejectRegisterLogin'
		));
	END LOOP;
	
	user_pkg.logonadmin;
	BEGIN
		card_pkg.DestroyCard('SCAA.Cards.QuestionnaireInvitationConfirmation');
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;
/
	
connect csr/csr@&_CONNECT_IDENTIFIER

DECLARE
	v_host		customer.host%TYPE;
BEGIN
	BEGIN
		SELECT host
		  INTO v_host
		  FROM customer 
		 WHERE host = 'www.whistler2020.ca';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_host := NULL;
	END;
	
	IF v_host IS NOT NULL THEN

		user_pkg.logonadmin(v_host);
		
		UPDATE customer
		   SET chain_invite_landing_preable = '{fromUserName} from {fromCompanyName} has identified you as a Whistler iShift Partner. They have requested that you fill in some information relating to the program.',
		       chain_invite_landing_qstn = 'Can you confirm that you work with {fromCompanyName} as a Whistler iShift Partner?'
		 WHERE app_sid = security_pkg.GetApp;
	
	END IF;
END;
/

@..\supplier_pkg
@..\supplier_body


@update_tail
