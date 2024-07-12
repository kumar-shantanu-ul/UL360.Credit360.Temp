-- Please update version.sql too -- this keeps clean builds in sync
define version=2105
@update_header

ALTER TABLE CHAIN.QUESTIONNAIRE_SECURITY_SCHEME MODIFY DESCRIPTION VARCHAR2(255);
/

BEGIN

	INSERT INTO CHAIN.QUESTIONNAIRE_SECURITY_SCHEME (SECURITY_SCHEME_ID, DESCRIPTION) VALUES (2, 'PROCURER: USER VIEW, USER EDIT, USER SUBMIT, USER APPROVE; SUPPLIER: USER VIEW, USER EDIT, USER SUBMIT');
	
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 1, 1); /* PROCURER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 1, 2); /* PROCURER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 1, 3); /* PROCURER: USER SUBMIT */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 1, 4); /* PROCURER: USER APPROVE*/
	
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 2, 1); /* SUPPLIER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 2, 2); /* SUPPLIER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2, 2, 3); /* SUPPLIER: USER SUBMIT */
END;
/


ALTER TABLE CHAIN.COMPONENT MODIFY COMPONENT_CODE VARCHAR2(4000);

DROP TYPE CHAIN.T_QNNAIRER_SHARE_TABLE;
DROP TYPE CHAIN.T_QNNAIRER_SHARE_ROW;

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_ROW AS 
	 OBJECT ( 
		QUESTIONNAIRE_SHARE_ID         NUMBER(10),
		QUESTIONNAIRE_TYPE_ID		   NUMBER(10),	
		DUE_BY_DTM 			 		   DATE,	
		QNR_OWNER_COMPANY_SID		   NUMBER(10),
		EDIT_URL					   VARCHAR2(4000),
		REMINDER_OFFSET_DAYS		   NUMBER(10),
		NAME						   VARCHAR2(200),
		ENTRY_DTM					   DATE,
		SHARE_STATUS_NAME			   VARCHAR2(200),
		COMPONENT_ID				   NUMBER(10),
		COMPONENT_DESCRIPTION		   VARCHAR2(4000)	
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_TABLE AS 
	TABLE OF CHAIN.T_QNNAIRER_SHARE_ROW;
/



/* chain.card_pkg.RegisterCard(
		'Questionnaire (Type) selection card for various invite wizards.',
		'Credit360.Chain.Cards.QuestionnaireTypeSelect',
		'/csr/site/chain/cards/questionnaireTypeSelect.js', 
		'Chain.Cards.QuestionnaireTypeSelect'
	); */
BEGIN
	DECLARE
		v_card_id         chain.card.card_id%TYPE;
		v_desc            chain.card.description%TYPE;
		v_class           chain.card.class_type%TYPE;
		v_js_path         chain.card.js_include%TYPE;
		v_js_class        chain.card.js_class_type%TYPE;
		v_css_path        chain.card.css_include%TYPE;
		v_actions         chain.T_STRING_LIST;
	BEGIN
		v_desc := 'Questionnaire (Type) selection card for various invite wizards.';
		v_class := 'Credit360.Chain.Cards.QuestionnaireTypeSelect';
		v_js_path := '/csr/site/chain/cards/questionnaireTypeSelect.js';
		v_js_class := 'Chain.Cards.QuestionnaireTypeSelect';
		v_css_path := '';
		
		BEGIN
			INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
				VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
			RETURNING card_id INTO v_card_id;
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE chain.card 
				   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
				 WHERE js_class_type = v_js_class
			 RETURNING card_id INTO v_card_id;
		END;
		
		DELETE FROM chain.card_progression_action 
		 WHERE card_id = v_card_id 
		   AND action NOT IN ('default');
		
		v_actions := chain.T_STRING_LIST('default');
		
		FOR i IN v_actions.FIRST .. v_actions.LAST
		LOOP
			BEGIN
				INSERT INTO chain.card_progression_action (card_id, action)
				VALUES (v_card_id, v_actions(i));
			EXCEPTION 
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
		
	END;
END;
/

		

@../quick_survey_pkg
@../quick_survey_body
@../supplier_body

@../chain/company_user_pkg
@../chain/company_pkg
@../chain/company_body
@../chain/company_type_body
@../chain/chain_link_body
@../chain/questionnaire_body
@../chain/component_body
@../chain/invitation_body
@../chain/purchased_component_body

@update_tail
