-- Please update version.sql too -- this keeps clean builds in sync
define version=2160
@update_header

BEGIN

	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
		VALUES (1043, 'McDonalds Supplier Questionnaires', 'Clients.McdonaldsSC.Portlets.SupplierQuestionnaires', EMPTY_CLOB(), '/mcdonalds-supplychain/chain/portlets/SupplierQuestionnaires.js');
		
END;
/

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_PRODUCT_QNR_DATA
( 
	COMPONENT_ID				NUMBER(10) NOT NULL,
	COMPONENT_DESCRIPTION		VARCHAR2(4000) NOT NULL,
	QUESTIONNAIRE_TYPE_ID		NUMBER(10) NOT NULL,
	NAME						VARCHAR2(255) NOT NULL,
	COMPANY_SID					NUMBER(10) NOT NULL,
	CREATED_BY_SID				NUMBER(10) NOT NULL,
	QUESTIONNAIRE_ID			NUMBER(10),	
	QUESTIONNAIRE_STATUS_ID		NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_NAME	VARCHAR2(255) NOT NULL,
	STATUS_UPDATE_DTM			TIMESTAMP(6) NOT NULL,
	DUE_BY_DTM					DATE,
	POSITION					NUMBER(10),
	URL							VARCHAR2(255),
	CAN_SHARE					NUMBER(1) DEFAULT 0 
) 
ON COMMIT PRESERVE ROWS; 

@../chain/chain_pkg
@../chain/component_pkg
@../chain/questionnaire_pkg

@../chain/component_body
@../chain/purchased_component_body
@../chain/questionnaire_body

@update_tail
