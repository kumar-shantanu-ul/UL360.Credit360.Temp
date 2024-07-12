-- Please update version.sql too -- this keeps clean builds in sync
define version=2135
@update_header

BEGIN

	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
		VALUES (1041, 'Supply Chain Questionnaires', 'Credit360.Portlets.Chain.Questionnaires', EMPTY_CLOB(), '/csr/site/portal/portlets/chain/Questionnaires.js');
		
	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
		VALUES (1042, 'Supply Chain Supplier Questionnaires', 'Credit360.Portlets.Chain.SupplierQuestionnaires', EMPTY_CLOB(), '/csr/site/portal/portlets/chain/SupplierQuestionnaires.js');

END;
/

@../chain/questionnaire_pkg
@../chain/questionnaire_body

@update_tail
