-- Please update version.sql too -- this keeps clean builds in sync
define version=891
@update_header

DROP TYPE CSR.T_FLOW_STATE_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_ROW AS
	OBJECT (	
		POS						NUMBER(10), 
		ID						NUMBER(10), 
		LABEL					VARCHAR2(255), 
		LOOKUP_KEY				VARCHAR2(255),
		EDITABLE_ROLE_SIDS		VARCHAR2(2000),
		NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
		ATTRIBUTES_XML			XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/

@..\flow_pkg
@..\flow_body

@update_tail
