-- Please update version.sql too -- this keeps clean builds in sync
define version=2168
@update_header

BEGIN

	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
		VALUES (1044, 'McDonalds Questionnaires', 'Clients.McdonaldsSC.Portlets.Questionnaires', EMPTY_CLOB(), '/mcdonalds-supplychain/chain/portlets/Questionnaires.js');
		
END;
/

@update_tail
