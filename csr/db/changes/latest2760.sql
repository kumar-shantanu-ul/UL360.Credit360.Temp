-- Please update version.sql too -- this keeps clean builds in sync
define version=2760
define minor_version=0
@update_header

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_ROW AS
	OBJECT (
		XML_POS					NUMBER(10),	
		POS						NUMBER(10), 
		ID						NUMBER(10), 
		LABEL					VARCHAR2(255), 
		LOOKUP_KEY				VARCHAR2(255),
		IS_FINAL				NUMBER(1),
		STATE_COLOUR			NUMBER(10),
		EDITABLE_ROLE_SIDS		VARCHAR2(2000),
		NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
		EDITABLE_COL_SIDS		VARCHAR2(2000),
		NON_EDITABLE_COL_SIDS	VARCHAR2(2000),
		INVOLVED_TYPE_IDS		VARCHAR2(2000),
		ATTRIBUTES_XML			XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		COLUMN_SIDS					VARCHAR2(2000),
		INVOLVED_TYPE_IDS			VARCHAR2(2000),
		ATTRIBUTES_XML				XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/

@..\flow_pkg
@..\flow_body

@update_tail
