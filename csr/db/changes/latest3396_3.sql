-- Please update version.sql too -- this keeps clean builds in sync
define version=3396
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
drop type CSR.T_FLOW_ALERT_TABLE;
drop type CSR.T_FLOW_ALERT_ROW;

CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_ROW AS
  OBJECT (
		APP_SID							NUMBER(10),
		FLOW_STATE_TRANSITION_ID		NUMBER(10),
		FLOW_ITEM_GENERATED_ALERT_ID	NUMBER(10),
		CUSTOMER_ALERT_TYPE_ID			NUMBER(10),
		FLOW_STATE_LOG_ID				NUMBER(10),
		FROM_STATE_LABEL				VARCHAR2(255),
		TO_STATE_LABEL					VARCHAR2(255),
		SET_BY_USER_SID					NUMBER(10),
		SET_BY_EMAIL					VARCHAR2(256),
		SET_BY_FULL_NAME				VARCHAR2(256),
		SET_BY_USER_NAME				VARCHAR2(256),
		TO_USER_SID						NUMBER(10),
		FLOW_ALERT_HELPER				VARCHAR2(256),
		TO_USER_NAME					VARCHAR2(256),
		TO_FULL_NAME					VARCHAR2(256),
		TO_EMAIL						VARCHAR2(256),
		TO_FRIENDLY_NAME				VARCHAR2(255),
		TO_INITIATOR					NUMBER(1),
		FLOW_ITEM_ID					NUMBER(10),
		FLOW_TRANSITION_ALERT_ID		NUMBER(10),
		COMMENT_TEXT					CLOB,
		SET_DTM							DATE
  );
/

CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_TABLE AS 
  TABLE OF CSR.T_FLOW_ALERT_ROW;
/

-- *** Grants ***
BEGIN
	FOR r IN (SELECT NULL FROM all_users WHERE username = 'SURVEYS')
	LOOP
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.t_flow_alert_table TO SURVEYS';
	END LOOP;
END;
/


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../campaigns/campaign_body
@../flow_body

@update_tail
