-- Please update version.sql too -- this keeps clean builds in sync
define version=1943
@update_header

-- Remove old non-compliance files
BEGIN
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner='CSR'
		   AND table_name='NON_COMPLIANCE_FILE_UPLOAD'
		   AND r_constraint_name='PK_FILE_UPLOAD'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.NON_COMPLIANCE_FILE_UPLOAD DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
	FOR a IN (
		SELECT DISTINCT c.host
		  FROM csr.non_compliance_file_upload ncfu
		  JOIN csr.customer c on ncfu.app_sid = c.app_sid
	) LOOP
		security.user_pkg.LogonAdmin(a.host);
		FOR r IN (
			SELECT file_upload_sid
			  FROM csr.non_compliance_file_upload
		) LOOP
			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY','ACT'), r.file_upload_sid);
		END LOOP;
	END LOOP;
END;
/

DROP TABLE csr.non_compliance_file_upload;

ALTER TABLE csr.non_compliance_file DROP COLUMN from_file_upload_sid;


-- Add user cover to CMS forms
ALTER TABLE CMS.TAB_COLUMN ADD COVERABLE NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE CMS.TAB_COLUMN ADD CONSTRAINT CHK_COVERABLE_0_OR_1 
    CHECK (COVERABLE IN (0,1));
	
CREATE TABLE CSR.ISSUE_USER_COVER (
	APP_SID					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	USER_COVER_ID			NUMBER(10) NOT NULL,
	USER_GIVING_COVER_SID	NUMBER(10) NOT NULL,
	USER_BEING_COVERED_SID	NUMBER(10) NOT NULL,
	ISSUE_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_USER_COVER PRIMARY KEY (APP_SID, ISSUE_ID, USER_COVER_ID),
	CONSTRAINT FK_ISSUE_USR_CVR_ISSUE FOREIGN KEY (APP_SID, ISSUE_ID) REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID),
	CONSTRAINT FK_ISSUE_USR_CVR_USRG FOREIGN KEY (APP_SID, USER_GIVING_COVER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_ISSUE_USR_CVR_USRR FOREIGN KEY (APP_SID, USER_BEING_COVERED_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
);

-- Change logic of user cover to send alerts for CMS form cover
ALTER TABLE csr.user_cover ADD alert_sent_dtm DATE;

-- mark existing user covers as sent
UPDATE csr.user_cover SET alert_sent_dtm = start_dtm
 WHERE start_dtm < SYSDATE;

COMMIT;

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'ISSUE_USER_COVER'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'appSidCheck',
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

grant insert, select on csr.flow_item_generated_alert to cms;
grant select on csr.v$open_flow_item_alert to cms;
grant select on csr.flow_transition_alert_user to cms;
grant select on csr.flow_item_alert to cms;
grant select on csr.flow_state_log to cms;
grant select on csr.flow_transition_alert_cms_col to cms;
grant select on csr.flow_item_gen_alert_id_seq to cms;

-- CSREXP / IMP Changes
CREATE TABLE CSRIMP.ISSUE_USER_COVER (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_COVER_ID			NUMBER(10) NOT NULL,
	USER_GIVING_COVER_SID	NUMBER(10) NOT NULL,
	USER_BEING_COVERED_SID	NUMBER(10) NOT NULL,
	ISSUE_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISSUE_USER_COVER PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_ID, USER_COVER_ID),
	CONSTRAINT FK_ISSUE_USER_COVER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE CSRIMP.CMS_TAB_COLUMN ADD (
	COVERABLE NUMBER(1)
);

UPDATE CSRIMP.CMS_TAB_COLUMN SET COVERABLE=0;

ALTER TABLE CSRIMP.CMS_TAB_COLUMN MODIFY COVERABLE NUMBER(1) NOT NULL;

ALTER TABLE CSRIMP.CMS_TAB_COLUMN ADD 
	CONSTRAINT CK_TAB_COL_COVERABLE CHECK (COVERABLE IN (1, 0));

CREATE TABLE CSRIMP.GROUP_USER_COVER (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_COVER_ID			NUMBER(10) NOT NULL,
	USER_GIVING_COVER_SID	NUMBER(10, 0)    NOT NULL,
    USER_BEING_COVERED_SID	NUMBER(10, 0)    NOT NULL,
	GROUP_SID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_GROUP_USER_COVER PRIMARY KEY (CSRIMP_SESSION_ID, USER_COVER_ID, USER_GIVING_COVER_SID, USER_BEING_COVERED_SID, GROUP_SID),
	CONSTRAINT FK_GROUP_USER_COVER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.ROLE_USER_COVER (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_COVER_ID			NUMBER(10) NOT NULL,
	USER_GIVING_COVER_SID	NUMBER(10, 0)    NOT NULL,
    USER_BEING_COVERED_SID	NUMBER(10, 0)    NOT NULL,
	ROLE_SID				NUMBER(10) NOT NULL,
	REGION_SID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_ROLE_USER_COVER PRIMARY KEY (CSRIMP_SESSION_ID, USER_COVER_ID, USER_GIVING_COVER_SID, USER_BEING_COVERED_SID, ROLE_SID, REGION_SID),
	CONSTRAINT FK_ROLE_USER_COVER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE csrimp.user_cover ADD alert_sent_dtm DATE;

-- mark existing user covers as sent
UPDATE csrimp.user_cover SET alert_sent_dtm = start_dtm
 WHERE start_dtm < SYSDATE;

COMMIT;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT t.owner, t.table_name, (SUBSTR(t.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		 WHERE t.owner = 'CSRIMP'
		   AND t.table_name IN (
			'ISSUE_USER_COVER',
			'GROUP_USER_COVER',
			'ROLE_USER_COVER'
		)
 	)
 	LOOP
		BEGIN
			dbms_output.put_line('Writing policy '||r.policy_name);
			dbms_rls.add_policy(
				object_schema   => r.owner,
				object_name     => r.table_name,
				policy_name     => r.policy_name, 
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||r.table_name);
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

grant select,insert,update,delete on csrimp.issue_user_cover to web_user;
grant select,insert,update,delete on csrimp.role_user_cover to web_user;
grant select,insert,update,delete on csrimp.group_user_cover to web_user;

grant insert on csr.issue_user_cover to csrimp;
grant insert on csr.role_user_cover to csrimp;
grant insert on csr.group_user_cover to csrimp;

-- Workflow / Auto-Transition Stuff
ALTER TABLE CSR.FLOW_STATE_TRANSITION
		ADD HOURS_BEFORE_AUTO_TRAN NUMBER(10,0);

ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION
		ADD HOURS_BEFORE_AUTO_TRAN NUMBER(10,0);
		
DROP TYPE CSR.T_FLOW_STATE_TRANS_ROW FORCE;
		
create or replace 
TYPE     CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		HOURS_BEFORE_AUTO_TRAN		NUMBER(10),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		COLUMN_SIDS					VARCHAR2(2000),
		ATTRIBUTES_XML				XMLType
);
/

@..\audit_pkg
@..\issue_pkg
@..\flow_pkg
@..\schema_pkg
@..\user_cover_pkg

@..\audit_body
@..\issue_body
@..\region_body
@..\flow_body
@..\user_cover_body
@..\csr_user_body
@..\schema_body
@..\csr_data_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
