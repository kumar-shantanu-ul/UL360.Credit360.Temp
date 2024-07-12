-- Please update version.sql too -- this keeps clean builds in sync
define version=2382
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

alter table csr.customer add ( default_country VARCHAR2(2) );

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***

-- RLS

-- Data
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can view others audits', 1);


-- *** Packages ***

DROP TYPE CSR.T_FLOW_STATE_TABLE;

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

@../property_pkg 
@../region_metric_pkg 
@../flow_pkg

@../property_body
@../region_metric_body
@../flow_body
@../meter_body
@../csr_app_body
@../meter_monitor_body

@update_tail