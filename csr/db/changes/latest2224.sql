-- Please update version.sql too -- this keeps clean builds in sync
define version=2224
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.ACTIVITY_TYPE ADD (
	TITLE_TEMPLATE			VARCHAR(255)
);

ALTER TABLE CHAIN.ACTIVITY_TYPE ADD (
	CAN_SHARE				NUMBER(1, 0) 
);
UPDATE CHAIN.ACTIVITY_TYPE SET CAN_SHARE = 0;
ALTER TABLE CHAIN.ACTIVITY_TYPE MODIFY CAN_SHARE DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.ACTIVITY ADD (
	SHARE_WITH_TARGET		NUMBER(1, 0)
);
UPDATE CHAIN.ACTIVITY SET SHARE_WITH_TARGET = 0;
ALTER TABLE CHAIN.ACTIVITY MODIFY SHARE_WITH_TARGET DEFAULT 0 NOT NULL;

ALTER TABLE CSRIMP.CHAIN_ACTIVITY_TYPE ADD (
	TITLE_TEMPLATE			VARCHAR(255)
);
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_TYPE ADD (
	CAN_SHARE				NUMBER(1, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE CSRIMP.CHAIN_ACTIVITY ADD (
	SHARE_WITH_TARGET		NUMBER(1, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE CHAIN.ACTIVITY_USER RENAME TO ACTIVITY_INVOLVEMENT;

ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT MODIFY (
	USER_SID				NUMBER(10, 0) NULL
);
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD (
	ROLE_SID				NUMBER(10, 0)
);

ALTER TABLE CSRIMP.CHAIN_ACTIVITY_USER RENAME TO CHAIN_ACTIVITY_INVOLVEMENT;

ALTER TABLE CSRIMP.CHAIN_ACTIVITY_INVOLVEMENT MODIFY (
	USER_SID				NUMBER(10, 0) NULL
);
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_INVOLVEMENT ADD (
	ROLE_SID				NUMBER(10, 0)
);

ALTER TABLE CHAIN.ACTIVITY DROP CONSTRAINT FK_ACTVTY_ACTVTY_USER;
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT DROP CONSTRAINT PK_ACTIVITY_USER;
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT DROP CONSTRAINT FK_ACTVTY_USER_ACTVTY;
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT DROP CONSTRAINT FK_ACTVTY_USER_CHAIN_USER;
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD CONSTRAINT UK_ACTIVITY_INVOLVEMENT UNIQUE (APP_SID, ACTIVITY_ID, USER_SID, ROLE_SID);
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD CONSTRAINT CK_ACTVTY_INVL_USER_ROLE CHECK ((USER_SID IS NULL AND ROLE_SID IS NOT NULL) OR (USER_SID IS NOT NULL AND ROLE_SID IS NULL));
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD CONSTRAINT FK_ACTVTY_INVL_ACTVTY FOREIGN KEY (APP_SID, ACTIVITY_ID) REFERENCES CHAIN.ACTIVITY (APP_SID, ACTIVITY_ID);
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD CONSTRAINT FK_ACTVTY_INVL_CHAIN_USER FOREIGN KEY (APP_SID, USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID, USER_SID);
ALTER TABLE CHAIN.ACTIVITY ADD CONSTRAINT FK_ACTVTY_ACTVTY_INVL FOREIGN KEY (APP_SID, ACTIVITY_ID, ASSIGNED_TO_USER_SID, ASSIGNED_TO_ROLE_SID) REFERENCES CHAIN.ACTIVITY_INVOLVEMENT (APP_SID, ACTIVITY_ID, USER_SID, ROLE_SID) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION ADD (
	DEFAULT_DESCRIPTION               CLOB,
    DEFAULT_ASSIGNED_TO_ROLE_SID      NUMBER(10, 0),
    DEFAULT_TARGET_ROLE_SID           NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE         NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE_UNIT    VARCHAR2(1),
	DEFAULT_SHARE_WITH_TARGET         NUMBER(1),
    DEFAULT_LOCATION                  VARCHAR2(1000),
    DEFAULT_LOCATION_TYPE	          NUMBER(10, 0)
);

ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION ADD (
	COPY_TAGS                         NUMBER(1),
	COPY_ASSIGNED_TO                  NUMBER(1),
	COPY_TARGET                       NUMBER(1)
);

UPDATE CHAIN.ACTIVITY_TYPE_ACTION SET DEFAULT_ACT_DATE_RELATIVE_UNIT = 'd';
ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION MODIFY DEFAULT_ACT_DATE_RELATIVE_UNIT DEFAULT 'd' NOT NULL;
UPDATE CHAIN.ACTIVITY_TYPE_ACTION SET DEFAULT_SHARE_WITH_TARGET = 0;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION MODIFY DEFAULT_SHARE_WITH_TARGET DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_TYPE_ACTION SET COPY_TAGS = 0;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION MODIFY COPY_TAGS DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_TYPE_ACTION SET COPY_ASSIGNED_TO = 0;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION MODIFY COPY_ASSIGNED_TO DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_TYPE_ACTION SET COPY_TARGET = 0;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION MODIFY COPY_TARGET DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_TYP_ACT_DATE_REL_UNIT CHECK (DEFAULT_ACT_DATE_RELATIVE_UNIT IN ('d','m')),
    CONSTRAINT CHK_ACT_TYP_ACT_SHARE_TARGET CHECK (DEFAULT_SHARE_WITH_TARGET IN (0,1))
);

ALTER TABLE CHAIN.ACTIVITY_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_TAGS CHECK (COPY_TAGS IN (0,1)),
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_ASS CHECK (COPY_ASSIGNED_TO IN (0,1)),
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_TARGET CHECK (COPY_TARGET IN (0,1))
);

ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION ADD (
	DEFAULT_DESCRIPTION               CLOB,
    DEFAULT_ASSIGNED_TO_ROLE_SID      NUMBER(10, 0),
    DEFAULT_TARGET_ROLE_SID           NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE         NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE_UNIT    VARCHAR2(1),
	DEFAULT_SHARE_WITH_TARGET         NUMBER(1),
    DEFAULT_LOCATION                  VARCHAR2(1000),
    DEFAULT_LOCATION_TYPE	          NUMBER(10, 0)
);

ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION ADD (
	COPY_TAGS                         NUMBER(1),
	COPY_ASSIGNED_TO                  NUMBER(1),
	COPY_TARGET                       NUMBER(1)
);

UPDATE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION SET DEFAULT_ACT_DATE_RELATIVE_UNIT = 'd';
ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION MODIFY DEFAULT_ACT_DATE_RELATIVE_UNIT DEFAULT 'd' NOT NULL;
UPDATE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION SET DEFAULT_SHARE_WITH_TARGET = 0;
ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION MODIFY DEFAULT_SHARE_WITH_TARGET DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION SET COPY_TAGS = 0;
ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION MODIFY COPY_TAGS DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION SET COPY_ASSIGNED_TO = 0;
ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION MODIFY COPY_ASSIGNED_TO DEFAULT 0 NOT NULL;
UPDATE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION SET COPY_TARGET = 0;
ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION MODIFY COPY_TARGET DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_OUT_ACT_DATE_REL_UNIT CHECK (DEFAULT_ACT_DATE_RELATIVE_UNIT IN ('d','m')),	
    CONSTRAINT CHK_ACT_OUT_ACT_SHARE_TARGET CHECK (DEFAULT_SHARE_WITH_TARGET IN (0,1))
);

ALTER TABLE CHAIN.ACTIVITY_OUTCOME_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_TAGS CHECK (COPY_TAGS IN (0,1)),
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_ASS CHECK (COPY_ASSIGNED_TO IN (0,1)),
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_TARGET CHECK (COPY_TARGET IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION ADD (
	DEFAULT_DESCRIPTION               CLOB,
    DEFAULT_ASSIGNED_TO_ROLE_SID      NUMBER(10, 0),
    DEFAULT_TARGET_ROLE_SID           NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE         NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE_UNIT    VARCHAR2(1),
	DEFAULT_SHARE_WITH_TARGET         NUMBER(1),
    DEFAULT_LOCATION                  VARCHAR2(1000),
    DEFAULT_LOCATION_TYPE	          NUMBER(10, 0)
);

ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION ADD (
	COPY_TAGS                         NUMBER(1),
	COPY_ASSIGNED_TO                  NUMBER(1),
	COPY_TARGET                       NUMBER(1)
);

UPDATE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION SET DEFAULT_ACT_DATE_RELATIVE_UNIT = 'd';
ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION MODIFY DEFAULT_ACT_DATE_RELATIVE_UNIT DEFAULT 'd' NOT NULL;
UPDATE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION SET DEFAULT_SHARE_WITH_TARGET = 0;
ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION MODIFY DEFAULT_SHARE_WITH_TARGET DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION SET COPY_TAGS = 0;
ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION MODIFY COPY_TAGS DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION SET COPY_ASSIGNED_TO = 0;
ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION MODIFY COPY_ASSIGNED_TO DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION SET COPY_TARGET = 0;
ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION MODIFY COPY_TARGET DEFAULT 0 NOT NULL;

ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_TYP_ACT_DATE_REL_UNIT CHECK (DEFAULT_ACT_DATE_RELATIVE_UNIT IN ('d','m')),	
    CONSTRAINT CHK_ACT_TYP_ACT_SHARE_TARGET CHECK (DEFAULT_SHARE_WITH_TARGET IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_ACTIVI_TYPE_ACTION ADD (
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_TAGS CHECK (COPY_TAGS IN (0,1)),
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_ASS CHECK (COPY_ASSIGNED_TO IN (0,1)),
    CONSTRAINT CHK_ACT_TYP_ACT_COPY_TARGET CHECK (COPY_TARGET IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT ADD (
	DEFAULT_DESCRIPTION               CLOB,
    DEFAULT_ASSIGNED_TO_ROLE_SID      NUMBER(10, 0),
    DEFAULT_TARGET_ROLE_SID           NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE         NUMBER(10, 0),
    DEFAULT_ACT_DATE_RELATIVE_UNIT    VARCHAR2(1),
	DEFAULT_SHARE_WITH_TARGET         NUMBER(1),
    DEFAULT_LOCATION                  VARCHAR2(1000),
    DEFAULT_LOCATION_TYPE	          NUMBER(10, 0)
);

ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT ADD (
	COPY_TAGS                         NUMBER(1),
	COPY_ASSIGNED_TO                  NUMBER(1),
	COPY_TARGET                       NUMBER(1)
);

UPDATE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT SET DEFAULT_ACT_DATE_RELATIVE_UNIT = 'd';
ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT MODIFY DEFAULT_ACT_DATE_RELATIVE_UNIT DEFAULT 'd' NOT NULL;
UPDATE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT SET DEFAULT_SHARE_WITH_TARGET = 0;
ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT MODIFY DEFAULT_SHARE_WITH_TARGET DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT SET COPY_TAGS = 0;
ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT MODIFY COPY_TAGS DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT SET COPY_ASSIGNED_TO = 0;
ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT MODIFY COPY_ASSIGNED_TO DEFAULT 0 NOT NULL;
UPDATE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT SET COPY_TARGET = 0;
ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT MODIFY COPY_TARGET DEFAULT 0 NOT NULL;

ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT ADD (
    CONSTRAINT CHK_ACT_OUT_ACT_DATE_REL_UNIT CHECK (DEFAULT_ACT_DATE_RELATIVE_UNIT IN ('d','m')),	
    CONSTRAINT CHK_ACT_OUT_ACT_SHARE_TARGET CHECK (DEFAULT_SHARE_WITH_TARGET IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_ACT_OUTC_TYPE_ACT ADD (
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_TAGS CHECK (COPY_TAGS IN (0,1)),
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_ASS CHECK (COPY_ASSIGNED_TO IN (0,1)),
    CONSTRAINT CHK_ACT_OUT_ACT_COPY_TARGET CHECK (COPY_TARGET IN (0,1))
);

CREATE SEQUENCE CHAIN.PROJECT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.PROJECT (
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PROJECT_ID			NUMBER(10, 0)	NOT NULL,
	NAME				VARCHAR(255)	NOT NULL,
	CONSTRAINT PK_PROJECT PRIMARY KEY (APP_SID, PROJECT_ID)
);

CREATE TABLE CSRIMP.CHAIN_PROJECT (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PROJECT_ID			NUMBER(10, 0)	NOT NULL,
	NAME				VARCHAR(255)	NOT NULL,
	CONSTRAINT PK_PROJECT PRIMARY KEY (CSRIMP_SESSION_ID, PROJECT_ID),
	CONSTRAINT FK_PROJECT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PROJECT (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PROJECT_ID		NUMBER(10)	NOT NULL,
	NEW_PROJECT_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_PROJECT PRIMARY KEY (OLD_PROJECT_ID) USING INDEX,
	CONSTRAINT UK_MAP_PROJECT UNIQUE (NEW_PROJECT_ID) USING INDEX,
	CONSTRAINT FK_MAP_PROJECT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE CHAIN.ACTIVITY ADD (
	PROJECT_ID			NUMBER(10, 0)
);
ALTER TABLE CHAIN.ACTIVITY ADD CONSTRAINT FK_ACTVTY_PROJECT
	FOREIGN KEY (APP_SID, PROJECT_ID)
	REFERENCES CHAIN.PROJECT (APP_SID, PROJECT_ID);

ALTER TABLE CSRIMP.CHAIN_ACTIVITY ADD (
	PROJECT_ID			NUMBER(10, 0)
);

ALTER TABLE CHAIN.ACTIVITY_TYPE_ALERT ADD (
	SEND_TO_TARGET		NUMBER(1),
	SEND_TO_ASSIGNEE	NUMBER(1)
);
UPDATE CHAIN.ACTIVITY_TYPE_ALERT SET SEND_TO_TARGET = 1 WHERE SEND_TO_TARGET IS NULL;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ALERT MODIFY SEND_TO_TARGET DEFAULT 1 NOT NULL;
UPDATE CHAIN.ACTIVITY_TYPE_ALERT SET SEND_TO_ASSIGNEE = 0 WHERE SEND_TO_ASSIGNEE IS NULL;
ALTER TABLE CHAIN.ACTIVITY_TYPE_ALERT MODIFY SEND_TO_ASSIGNEE DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CHAIN_ACTIVIT_TYPE_ALERT ADD (
	SEND_TO_TARGET		NUMBER(1),
	SEND_TO_ASSIGNEE	NUMBER(1)
);
UPDATE CSRIMP.CHAIN_ACTIVIT_TYPE_ALERT SET SEND_TO_TARGET = 1 WHERE SEND_TO_TARGET IS NULL;
ALTER TABLE CSRIMP.CHAIN_ACTIVIT_TYPE_ALERT MODIFY SEND_TO_TARGET DEFAULT 1 NOT NULL;
UPDATE CSRIMP.CHAIN_ACTIVIT_TYPE_ALERT SET SEND_TO_ASSIGNEE = 0 WHERE SEND_TO_ASSIGNEE IS NULL;
ALTER TABLE CSRIMP.CHAIN_ACTIVIT_TYPE_ALERT MODIFY SEND_TO_ASSIGNEE DEFAULT 0 NOT NULL;


-- *** Grants ***
grant select on chain.project_id_seq to csrimp;
grant select on chain.project_id_seq to csr;
grant select, insert, update on chain.project to csrimp;
grant select, insert, update on chain.project to csr;
GRANT EXECUTE ON csr.null_pkg TO chain;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.ACTIVITY_INVOLVEMENT ADD CONSTRAINT FK_ACTVTY_INVL_ROLE FOREIGN KEY (APP_SID, ROLE_SID) REFERENCES CSR.ROLE (APP_SID, ROLE_SID);

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$activity AS
SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
	   a.project_id, p.name project_name,
       a.activity_type_id, at.label activity_type_label, at.lookup_key activity_type_lookup_key,
	   a.assigned_to_user_sid, acu.full_name assigned_to_user_name,
	   a.assigned_to_role_sid, acr.name assigned_to_role_name,
	   CASE WHEN a.assigned_to_role_sid IS NOT NULL THEN acr.name ELSE acu.full_name END assigned_to_name,
	   a.target_user_sid, tcu.full_name target_user_name, 
	   a.target_role_sid, tcr.name target_role_name, 
	   CASE WHEN a.target_role_sid IS NOT NULL THEN tcr.name ELSE tcu.full_name END target_name,
	   a.activity_dtm, a.original_activity_dtm, 
	   a.created_dtm, a.created_by_activity_id, a.created_by_sid, ccu.full_name created_by_user_name,
	   a.outcome_type_id, ot.label outcome_type_label, ot.is_success, ot.is_failure, ot.is_deferred,
	   a.outcome_reason, a.location, a.location_type,
	   CASE WHEN at.can_share = 1 AND a.share_with_target = 1 THEN 1 ELSE 0 END share_with_target,
	   CASE WHEN a.activity_dtm <= SYSDATE AND a.outcome_type_id IS NULL THEN 'Overdue'
	   WHEN a.activity_dtm > SYSDATE AND a.outcome_type_id IS NULL THEN 'Up-coming'
	   ELSE 'Completed' END status, tc.name target_company_name
  FROM activity a
  JOIN activity_type at ON at.activity_type_id = a.activity_type_id
  LEFT JOIN project p ON p.project_id = a.project_id
  LEFT JOIN outcome_type ot ON ot.outcome_type_id = a.outcome_type_id
  LEFT JOIN csr.csr_user acu ON acu.csr_user_sid = a.assigned_to_user_sid
  LEFT JOIN csr.role acr ON acr.role_sid = a.assigned_to_role_sid
  LEFT JOIN csr.csr_user tcu ON tcu.csr_user_sid = a.target_user_sid
  LEFT JOIN csr.role tcr ON tcr.role_sid = a.target_role_sid
  JOIN csr.csr_user ccu ON ccu.csr_user_sid = a.created_by_sid
  JOIN company tc ON a.target_company_sid = tc.company_sid;

-- *** Data changes ***
-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'PROJECT'
	);
	for i in 1 .. v_list.count loop
		begin
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26) || '_POL', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.static);
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' already exists');
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
		end;
	end loop;
end;
/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'CHAIN_PROJECT',
        'MAP_CHAIN_PROJECT'
    );
    FOR I IN 1 .. v_list.count
	LOOP		
		-- CSRIMP RLS
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26)||'_POL',
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/


-- Data
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1046,'Supply Chain Activities','Credit360.Portlets.Chain.ActivitySummary',EMPTY_CLOB(),'/csr/site/portal/portlets/chain/ActivitySummary.js');
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.CHAIN.ACTIVITYSUMMARY', 'mode', 'STRING', 'whether to show overdue or upcoming activities');
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.CHAIN.ACTIVITYSUMMARY', 'numberOfActivities', 'NUMBER', 'The number of activities to show');

INSERT INTO CSR.customer_alert_type_param (app_sid, customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
SELECT app_sid, customer_alert_type_id, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 7
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 8
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 9
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 10
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 11
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 12
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'LOCATION', 'Location', 'The Location of the activity', 13
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'STATUS', 'Status', 'The status of the activity', 14
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'TAGS', 'Tags', 'The tags of the activity', 15
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 16
  FROM chain.activity_type_alert
UNION
SELECT app_sid, customer_alert_type_id, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 17
  FROM chain.activity_type_alert
;

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (5023,
	'Activity email received',
	'Sent when an email relating to an activity has been received.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (5024,
	'Activity email error',
	'Sent when an email has been received to the activity inbox, but cannot be matched to an activity.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'LOCATION', 'Location', 'The Location of the activity', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'STATUS', 'Status', 'The status of the activity', 14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TAGS', 'Tags', 'The tags of the activity', 15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'MESSAGE', 'Message', 'The email contents received', 18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5023, 0, 'MESSAGE_SUBJECT', 'Message subject', 'The subject of the email received', 19);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5024, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5024, 0, 'TO_NAME', 'To name', 'The name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5024, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5024, 0, 'MESSAGE', 'Message', 'The email contents received', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5024, 0, 'MESSAGE_SUBJECT', 'Message subject', 'The subject of the email received', 5);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'LOCATION', 'Location', 'The Location of the activity', 16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'STATUS', 'Status', 'The status of the activity', 17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'TAGS', 'Tags', 'The tags of the activity', 18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5022, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 20);

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	security.user_pkg.logonadmin;
	
	BEGIN
		--chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.COMPANY_TAGS, chain.chain_pkg.SPECIFIC_PERMISSION);
		-- internally the above call makes 2 calls like this:
		chain.temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, 'Company tags', 0, 0);
		chain.temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, 'Company tags', 0, 1);
	END;
END;
/

DECLARE
	v_capability_id		NUMBER(10);
BEGIN
	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Company tags'
	   AND capability_type_id = 2; --suppliers

	FOR r IN (
		SELECT ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id 
		  FROM chain.company_type ct 
		  JOIN chain.company_type_relationship ctr ON ct.company_type_id = ctr.primary_company_type_id
		 WHERE ct.is_top_company = 1
	) LOOP
		INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		     VALUES (r.app_sid, r.company_type_id, r.secondary_company_type_id, 1, v_capability_id, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE); --admins
		INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		     VALUES (r.app_sid, r.company_type_id, r.secondary_company_type_id, 2, v_capability_id, security.security_pkg.PERMISSION_READ); --users
		INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		     VALUES (r.app_sid, r.company_type_id, r.secondary_company_type_id, 4, v_capability_id, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE); --chain admins
	END LOOP;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

-- ** New package grants **
create or replace package chain.activity_pkg as end;
/

GRANT EXECUTE ON chain.activity_pkg TO csr;

-- *** Packages ***
@../schema_pkg
@../csrimp/imp_pkg
@../chain/activity_pkg
@../chain/company_pkg
@../chain/chain_pkg

@../schema_body
@../csrimp/imp_body
@../chain/activity_body
@../chain/company_body
@../../../Yam/db/reader_body

@update_tail
