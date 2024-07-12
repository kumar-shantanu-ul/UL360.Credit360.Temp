-- Please update version.sql too -- this keeps clean builds in sync
define version=3414
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CHAIN.T_CUSTOMER_OPTIONS_PARAM_ROW AS
	OBJECT (
		id        NUMBER(10),     
		name      VARCHAR2(100), 
		value     VARCHAR2(4000),
		data_type VARCHAR2(100), 
		nullable  NUMBER(1)  
	);
/

CREATE OR REPLACE TYPE CHAIN.T_CUSTOMER_OPTIONS_PARAM_TABLE AS
	TABLE OF CHAIN.T_CUSTOMER_OPTIONS_PARAM_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_MESSAGE_SEARCH_ROW AS
	OBJECT (
		message_id 							NUMBER(10),
		message_definition_id 				NUMBER(10),
		to_company_sid 						NUMBER(10),
		to_user_sid 						NUMBER(10),
		re_company_sid 						NUMBER(10),
		re_user_sid 						NUMBER(10),
		re_questionnaire_type_id 			NUMBER(10),
		re_component_id 					NUMBER(10),
		order_by_dtm 						TIMESTAMP(6),
		last_refreshed_by_user_sid 			NUMBER(10),
		completed_by_user_sid				NUMBER(10),
		viewed_dtm 							TIMESTAMP(6),
		re_secondary_company_sid 			NUMBER(10),
		re_invitation_id 					NUMBER(10),
		re_audit_request_id 				NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_MESSAGE_SEARCH_TABLE AS
	TABLE OF CHAIN.T_MESSAGE_SEARCH_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_VALUE_MAP_ROW AS
	OBJECT (
		OLD_FILTER_VALUE_ID       NUMBER(10),
		NEW_FILTER_VALUE_ID       NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_VALUE_MAP_TABLE AS
	TABLE OF CHAIN.T_FILTER_VALUE_MAP_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_REFERENCE_LABEL_ROW AS
	OBJECT (
		COMPANY_SID	NUMBER(10,0),
		NAME		VARCHAR2(255 BYTE),
		LOOKUP_KEY	VARCHAR2(255 BYTE)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_REFERENCE_LABEL_TABLE AS
	TABLE OF CHAIN.T_REFERENCE_LABEL_ROW;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/admin_helper_body
@../chain/company_body
@../chain/message_body
@../chain/filter_body

@update_tail
