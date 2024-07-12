-- Please update version.sql too -- this keeps clean builds in sync
define version=3253
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

DROP TYPE CSR.T_FLOW_STATE_TABLE;

CREATE OR REPLACE TYPE     CSR.T_FLOW_STATE_ROW AS
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
		ATTRIBUTES_XML			XMLType,
		FLOW_STATE_NATURE_ID	NUMBER(10),
		MOVE_FROM_FLOW_STATE_ID NUMBER(10)
	);
/

CREATE OR REPLACE TYPE     CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/

-- Alter tables
ALTER TABLE CSR.T_FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;
ALTER TABLE CSR.FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.flow_state
   SET move_from_flow_state_id = NULL
 WHERE move_from_flow_state_id IS NOT NULL
   AND is_deleted = 0;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../flow_body

@update_tail
