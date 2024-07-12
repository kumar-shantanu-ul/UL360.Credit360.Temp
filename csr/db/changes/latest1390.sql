-- Please update version.sql too -- this keeps clean builds in sync
define version=1390
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Copy forward delegation', 1);

CREATE OR REPLACE TYPE CSR.T_SHEET_INFO AS 
  OBJECT ( 
	SHEET_ID		NUMBER(10,0),
	DELEGATION_SID		NUMBER(10,0),
	PARENT_DELEGATION_SID	NUMBER(10,0),
	NAME			VARCHAR2(255),
	CAN_SAVE		NUMBER(10,0),
	CAN_SUBMIT		NUMBER(10,0),
	CAN_ACCEPT		NUMBER(10,0),
	CAN_RETURN		NUMBER(10,0),
	CAN_DELEGATE		NUMBER(10,0),
	CAN_VIEW		NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR		NUMBER(10,0),
	CAN_COPY_FORWARD	NUMBER(10,0),
	LAST_ACTION_ID		NUMBER(10,0),
	START_DTM		DATE,
	END_DTM			DATE,
	INTERVAL		VARCHAR2(1),
	GROUP_BY		VARCHAR2(128),
	PERIOD_FMT		VARCHAR2(255),
	NOTE			CLOB,
	USER_LEVEL		NUMBER(10,0),
	IS_TOP_LEVEL		NUMBER(10,0)
  );
/

BEGIN
	FOR r IN (
		SELECT NULL
		  FROM all_tab_columns
		 WHERE owner='CHAIN'
		   AND table_name='INVITATION_STATUS'
		   AND column_name='FILTER_DESCRIPTION'
		   AND data_length!=100
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.invitation_status MODIFY filter_description VARCHAR2(100)';
	END LOOP;
END;
/


INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (10, 'Not invited', 'Not invited');

CREATE OR REPLACE VIEW chain.v$company_invitation_status AS
SELECT i.company_sid, i.invitation_status_id, st.filter_description invitation_status_description
  FROM (
	SELECT to_company_sid company_sid, invitation_status_id FROM (
		SELECT to_company_sid,
				NVL(DECODE(invitation_status_id,
					6, 7,--chain_pkg.REJECTED_NOT_SUPPLIER, chain_pkg.REJECTED_NOT_EMPLOYEE
					4, 5),--chain_pkg.PROVISIONALLY_ACCEPTED, chain_pkg.ACCEPTED
					invitation_status_id) invitation_status_id,
				ROW_NUMBER() OVER (PARTITION BY to_company_sid ORDER BY DECODE(invitation_status_id, 
					5, 1,--chain_pkg.ACCEPTED, 1,
					4, 1,--chain_pkg.PROVISIONALLY_ACCEPTED, 1,
					1, 2,--chain_pkg.ACTIVE, 2,
					2, 3, --chain_pkg.EXPIRED, 3,
					3, 3, --chain_pkg.CANCELLED, 3,
					6, 3, --chain_pkg.REJECTED_NOT_EMPLOYEE, 3,
					7, 3 --chain_pkg.REJECTED_NOT_SUPPLIER, 3
				), sent_dtm DESC) rn
		  FROM invitation
		 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		)
	 WHERE rn = 1
	 UNION
	SELECT company_sid, 10 --chain_pkg.NOT_INVITED
	  FROM v$company
	 WHERE company_sid NOT IN (
		SELECT to_company_sid
		  FROM invitation
		 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		)
	) i
  JOIN invitation_status st on i.invitation_status_id = st.invitation_status_id;

@..\sheet_body
@..\audit_body
@..\snapshot_body
@..\quick_survey_body
@..\indicator_body
@..\chain\company_filter_body
@..\chain\dashboard_body
@..\chain\invitation_body
@..\chain\report_body


@update_tail
