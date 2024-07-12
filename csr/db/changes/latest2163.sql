-- Please update version.sql too -- this keeps clean builds in sync
define version=2163
@update_header

--rename TT so we dnot have to kill connection using it
DROP TABLE CHAIN.TT_PRODUCT_QNR_DATA;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_PRODUCT_QNR_DATA_ORG
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
	CAN_MANAGE_PROCURER_PERMS	NUMBER(1) DEFAULT 0, 
	CAN_MANAGE_SUPPLIER_PERMS	NUMBER(1) DEFAULT 0 
) 
ON COMMIT PRESERVE ROWS; 

@../chain/questionnaire_body

@update_tail
