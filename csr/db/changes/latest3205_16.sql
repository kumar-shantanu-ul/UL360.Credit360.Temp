-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = 'CAMPAIGNS';

	 IF v_exists <> 0 THEN
		EXECUTE IMMEDIATE 'DROP USER CAMPAIGNS CASCADE';
	END IF;
	EXECUTE IMMEDIATE 'CREATE USER CAMPAIGNS IDENTIFIED BY campaigns DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
END;
/

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
		COMMENT_TEXT					CLOB
  );
/

CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_TABLE AS 
  TABLE OF CSR.T_FLOW_ALERT_ROW;
/

CREATE OR REPLACE TYPE CAMPAIGNS.T_CAMPAIGN_ROW AS
	OBJECT (
		APP_SID						NUMBER(10),
		QS_CAMPAIGN_SID				NUMBER(10),
		NAME						VARCHAR2(255),
		TABLE_SID					NUMBER(10),
		FILTER_SID					NUMBER(10),
		SURVEY_SID					NUMBER(10),
		FRAME_ID					NUMBER(10),
		SUBJECT						CLOB,
		BODY						CLOB,
		SEND_AFTER_DTM				DATE,
		STATUS						VARCHAR2(20),
		SENT_DTM					DATE,
		PERIOD_START_DTM			DATE,
		PERIOD_END_DTM				DATE,
		AUDIENCE_TYPE				CHAR(2),
		FLOW_SID					NUMBER(10),
		INC_REGIONS_WITH_NO_USERS	NUMBER(1),
		SKIP_OVERLAPPING_REGIONS 	NUMBER(1),
		CARRY_FORWARD_ANSWERS		NUMBER(1),
		SEND_TO_COLUMN_SID			NUMBER(10),
		REGION_COLUMN_SID			NUMBER(10),
		CREATED_BY_SID				NUMBER(10),
		FILTER_XML					CLOB,
		RESPONSE_COLUMN_SID			NUMBER(10),
		TAG_LOOKUP_KEY_COLUMN_SID	NUMBER(10),
		IS_SYSTEM_GENERATED			NUMBER(10),
		CUSTOMER_ALERT_TYPE_ID		NUMBER(10),
		CAMPAIGN_END_DTM			DATE,
		SEND_ALERT					NUMBER(1),
		DYNAMIC						NUMBER(1),
		RESEND						NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CAMPAIGNS.T_CAMPAIGN_TABLE IS TABLE OF CAMPAIGNS.T_CAMPAIGN_ROW;
/

-- Alter tables

-- *** Grants ***
grant execute on campaigns.t_campaign_row to surveys;
grant execute on campaigns.t_campaign_table to surveys;

grant select, delete on csr.flow_item to campaigns;
grant select on csr.quick_survey_response to campaigns;
grant select on csr.region to campaigns;
grant select, delete on csr.flow_state_log to campaigns;
grant select on csr.flow_transition_alert to campaigns;
grant select on csr.flow_involvement_type to campaigns;
grant delete on csr.flow_item_subscription to campaigns;
grant select on csr.trash to campaigns;
grant select, delete, insert, update on csr.flow_item_generated_alert to campaigns;


grant select on csr.qs_campaign to campaigns;
grant select on csr.deleg_plan_survey_region to campaigns;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE campaigns.campaign_pkg AS
END;
/

CREATE OR REPLACE PACKAGE BODY campaigns.campaign_pkg AS
END;
/


grant execute on csr.csr_data_pkg to campaigns;
grant execute on csr.campaign_pkg to campaigns;
grant execute on campaigns.campaign_pkg to surveys;
grant execute on campaigns.campaign_pkg to csr;
grant execute on campaigns.campaign_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\flow_pkg
@..\flow_body

@..\campaigns\campaign_pkg
@..\campaigns\campaign_body

@update_tail
