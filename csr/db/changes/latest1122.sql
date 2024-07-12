-- Please update version.sql too -- this keeps clean builds in sync
define version=1122
@update_header

alter table csr.flow_state_transition add button_icon_path varchar2(255);

drop type CSR.T_FLOW_STATE_TRANS_TABLE;
CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),	
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		ATTRIBUTES_XML				XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/

@../flow_pkg
@../../../aspen2/cms/db/tab_pkg
@../flow_body
@../../../aspen2/cms/db/tab_body

@update_tail