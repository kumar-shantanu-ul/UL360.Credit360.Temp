-- Please update version.sql too -- this keeps clean builds in sync
define version=2309
@update_header

BEGIN
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (5, 'Grant permissions');
	
	/* only procurer can grant permissions */
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 5); -- PROCURER, GRANT
	
	--add a new scheme
	INSERT INTO CHAIN.QUESTIONNAIRE_SECURITY_SCHEME (SECURITY_SCHEME_ID, DESCRIPTION) VALUES (3, 'PROCURER: USER VIEW, USER EDIT, USER SUBMIT, USER APPROVE, USER GRANT; SUPPLIER: USER VIEW, USER EDIT, USER SUBMIT');
	
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 1, 1); /* PROCURER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 1, 2); /* PROCURER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 1, 3); /* PROCURER: USER SUBMIT */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 1, 4); /* PROCURER: USER APPROVE*/
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 1, 5); /* PROCURER: USER GRANT*/

	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 2, 1); /* SUPPLIER: USER VIEW   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 2, 2); /* SUPPLIER: USER EDIT   */
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (3, 2, 2, 3); /* SUPPLIER: USER SUBMIT */
END;
/

CREATE OR REPLACE VIEW chain.v$qnr_action_capability
AS
	SELECT questionnaire_action_id, description,
		CASE WHEN questionnaire_action_id = 1 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 2 THEN 'Questionnaire'
			 WHEN questionnaire_action_id = 3 THEN 'Submit questionnaire'
			 WHEN questionnaire_action_id = 4 THEN 'Approve questionnaire' 
			 WHEN questionnaire_action_id = 5 THEN 'Manage questionnaire security' 
		END capability_name,
		CASE WHEN questionnaire_action_id = 1 THEN 1 --security_pkg.PERMISSION_READ -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 2 --security_pkg.PERMISSION_WRITE -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
		END permission_set,
		CASE WHEN questionnaire_action_id = 1 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 2 THEN 0 -- SPECIFIC
			 WHEN questionnaire_action_id = 3 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 4 THEN 1 -- BOOLEAN
			 WHEN questionnaire_action_id = 5 THEN 1 -- BOOLEAN
		END permission_type
		  FROM chain.questionnaire_action;
	

@../chain/chain_pkg
@../chain/questionnaire_security_pkg

@../chain/questionnaire_security_body
@../chain/questionnaire_body
	
@update_tail