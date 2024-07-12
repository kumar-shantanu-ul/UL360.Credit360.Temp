-- Please update version.sql too -- this keeps clean builds in sync
define version=1868
@update_header

BEGIN
	FOR r IN (SELECT type_name FROM all_types WHERE owner='CHAIN' AND type_name IN (
				'T_QNNAIRER_SHARE_TABLE')) LOOP
		EXECUTE IMMEDIATE 'DROP TYPE CHAIN.'||r.type_name;
	END LOOP;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_ROW AS 
	 OBJECT ( 
		QUESTIONNAIRE_SHARE_ID         NUMBER(10),
		QUESTIONNAIRE_TYPE_ID		   NUMBER(10),	
		DUE_BY_DTM 			 		   DATE,	
		QNR_OWNER_COMPANY_SID		   NUMBER(10),
		EDIT_URL					   VARCHAR2(4000),
		REMINDER_OFFSET_DAYS		   NUMBER(10),
		NAME						   VARCHAR2(200),
		ENTRY_DTM					   DATE,
		SHARE_STATUS_NAME			   VARCHAR2(200)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_TABLE AS 
	TABLE OF CHAIN.T_QNNAIRER_SHARE_ROW;
/
	
@../chain/questionnaire_body
@../chain/chain_link_body
	
@update_tail


