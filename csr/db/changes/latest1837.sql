-- Please update version too -- this keeps clean builds in sync
define version=1837
@update_header

/* adding account_enabled in v$company_user */
CREATE OR REPLACE VIEW CHAIN.v$company_user AS
  SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name, 
		vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,   
		vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		vcu.account_enabled
    FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
   WHERE cug.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cug.app_sid = vcu.app_sid
     AND cug.user_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;
/

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_ROW AS 
	 OBJECT ( 
		QUESTIONNAIRE_SHARE_ID         NUMBER(10),
		QUESTIONNAIRE_TYPE_ID		   NUMBER(10),	
		DUE_BY_DTM 			 		   DATE,	
		QNR_OWNER_COMPANY_SID		   NUMBER(10),
		EDIT_URL					   VARCHAR2(4000),
		REMINDER_OFFSET_DAYS		   NUMBER(10),
		NAME						   VARCHAR2(200)	
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_QNNAIRER_SHARE_TABLE AS 
	TABLE OF CHAIN.T_QNNAIRER_SHARE_ROW;
/

@../chain/questionnaire_body

@update_tail
