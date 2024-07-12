-- Please update version.sql too -- this keeps clean builds in sync
define version=1929
@update_header
CREATE TABLE CSR.NON_COMPLIANCE_FILE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    NON_COMPLIANCE_FILE_ID  NUMBER(10, 0)    NOT NULL,
    NON_COMPLIANCE_ID      NUMBER(10, 0)    NOT NULL,
    FILENAME              VARCHAR2(255)    NOT NULL,
    MIME_TYPE             VARCHAR2(256)    NOT NULL,
    DATA                  BLOB             NOT NULL,
    SHA1                  RAW(20)          NOT NULL,
    UPLOADED_DTM          DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_NON_COMPLIANCE_FILE PRIMARY KEY (APP_SID, NON_COMPLIANCE_FILE_ID)
) 
;

CREATE SEQUENCE CSR.NON_COMPLIANCE_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- Migrate existing files
ALTER TABLE CSR.NON_COMPLIANCE_FILE ADD (
	FROM_FILE_UPLOAD_SID		NUMBER(10)
);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'NON_COMPLIANCE_FILE'
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

INSERT INTO csr.non_compliance_file (app_sid, non_compliance_file_id, non_compliance_id, filename, mime_type, data, sha1, uploaded_dtm, from_file_upload_sid)
SELECT ncfu.app_sid, csr.non_compliance_file_id_seq.NEXTVAL, ncfu.non_compliance_id, fu.filename, fu.mime_type, fu.data, fu.sha1, fu.last_modified_dtm, ncfu.file_upload_sid
  FROM csr.non_compliance_file_upload ncfu
  JOIN csr.file_upload fu ON ncfu.file_upload_sid = fu.file_upload_sid AND ncfu.app_sid = fu.app_sid
 WHERE ncfu.file_upload_sid NOT IN (
	SELECT DISTINCT from_file_upload_sid
	  FROM csr.non_compliance_file
	 WHERE from_file_upload_sid IS NOT NULL);

DROP TYPE CSR.T_FLOW_STATE_TABLE;

DROP TYPE CSR.T_FLOW_STATE_TRANS_TABLE;

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_ROW AS
	OBJECT (	
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
		ATTRIBUTES_XML			XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_ROW AS
	OBJECT (
		POS							NUMBER(10),
		ID							NUMBER(10),	
		FROM_STATE_ID				NUMBER(10),
		TO_STATE_ID					NUMBER(10),
		ASK_FOR_COMMENT				VARCHAR2(16),
		MANDATORY_FIELDS_MESSAGE	VARCHAR2(255),
		BUTTON_ICON_PATH			VARCHAR2(255),
		VERB						VARCHAR2(255),
		LOOKUP_KEY					VARCHAR2(255),
		HELPER_SP					VARCHAR2(255),
		ROLE_SIDS					VARCHAR2(2000),
		COLUMN_SIDS					VARCHAR2(2000),
		ATTRIBUTES_XML				XMLType
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/

CREATE OR REPLACE TYPE CSR.T_FLOW_STATE_TRANS_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_TRANS_ROW;
/

CREATE TABLE CSR.FLOW_STATE_CMS_COL(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    COLUMN_SID       NUMBER(10, 0)    NOT NULL,
    IS_EDITABLE      NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_FLOW_STATE_CMS_COL_EDIT CHECK (IS_EDITABLE IN (0,1)),
    CONSTRAINT PK_FLOW_STATE_CMS_COL PRIMARY KEY (APP_SID, FLOW_STATE_ID, COLUMN_SID)
)
;

CREATE TABLE CSR.FLOW_STATE_TRANSITION_CMS_COL(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_TRANSITION_ID    NUMBER(10, 0)    NOT NULL,
    FROM_STATE_ID               NUMBER(10, 0)    NOT NULL,
    COLUMN_SID                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_STATE_TRANS_COL PRIMARY KEY (APP_SID, FLOW_STATE_TRANSITION_ID, FROM_STATE_ID, COLUMN_SID)
)
;

ALTER TABLE CSR.FLOW_STATE_TRANSITION_CMS_COL ADD
CONSTRAINT FK_FLOW_STATE_TRANS_CMS_COL FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID, COLUMN_SID);

ALTER TABLE CSR.FLOW_STATE_CMS_COL ADD
CONSTRAINT FK_FLOW_STATE_CMS_COL FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID, COLUMN_SID);

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD ADD (IS_MANDATORY NUMBER(1,0) DEFAULT 0 NOT NULL);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'FLOW_STATE_CMS_COL',
        'FLOW_STATE_TRANSITION_CMS_COL'
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

CREATE TABLE csrimp.map_non_compliance_file (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_compliance_file_id			NUMBER(10)	NOT NULL,
	new_non_compliance_file_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_non_comp_file_alloc PRIMARY KEY (old_non_compliance_file_id) USING INDEX,
	CONSTRAINT uk_non_comp_file_alloc UNIQUE (new_non_compliance_file_id) USING INDEX,
    CONSTRAINT FK_NON_COMP_FILE_ALLOC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.NON_COMPLIANCE_FILE(
    CSRIMP_SESSION_ID	NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    NON_COMPLIANCE_FILE_ID  NUMBER(10, 0)    NOT NULL,
    NON_COMPLIANCE_ID      NUMBER(10, 0)    NOT NULL,
    FILENAME              VARCHAR2(255)    NOT NULL,
    MIME_TYPE             VARCHAR2(256)    NOT NULL,
    DATA                  BLOB             NOT NULL,
    SHA1                  RAW(20)          NOT NULL,
    UPLOADED_DTM          DATE             NOT NULL,
    CONSTRAINT PK_NON_COMPLIANCE_FILE PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMPLIANCE_FILE_ID)
) 
;

CREATE TABLE CSRIMP.FLOW_STATE_CMS_COL(
    CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_STATE_ID    NUMBER(10, 0)    NOT NULL,
    COLUMN_SID       NUMBER(10, 0)    NOT NULL,
    IS_EDITABLE      NUMBER(1, 0)     NOT NULL,
    CONSTRAINT CHK_FLOW_STATE_CMS_COL_EDIT CHECK (IS_EDITABLE IN (0,1)),
    CONSTRAINT PK_FLOW_STATE_CMS_COL PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_ID, COLUMN_SID)
)
;

CREATE TABLE CSRIMP.FLOW_STATE_TRANSITION_CMS_COL(
    CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_STATE_TRANSITION_ID    NUMBER(10, 0)    NOT NULL,
    FROM_STATE_ID               NUMBER(10, 0)    NOT NULL,
    COLUMN_SID                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_STATE_TRANS_COL PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_TRANSITION_ID, FROM_STATE_ID, COLUMN_SID)
)
;

ALTER TABLE CSRIMP.FLOW ADD OWNER_CAN_CREATE  NUMBER(1);
ALTER TABLE CSRIMP.FLOW_STATE ADD (
	IS_FINAL          NUMBER(1),
	IS_EDITABLE_BY_OWNER NUMBER(1),
	CONSTRAINT CK_IS_EDITABLE_BY_OWNER CHECK (IS_EDITABLE_BY_OWNER IN (0,1))
);
ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION ADD (
	OWNER_CAN_SET               NUMBER(1),
	CONSTRAINT CK_OWNER_CAN_SET CHECK (OWNER_CAN_SET IN (0,1))
);

update CSRIMP.FLOW set OWNER_CAN_CREATE = 0;
update CSRIMP.FLOW_STATE set IS_FINAL = 0, IS_EDITABLE_BY_OWNER = 0;
update CSRIMP.FLOW_STATE_TRANSITION set OWNER_CAN_SET = 0;

ALTER TABLE CSRIMP.FLOW MODIFY OWNER_CAN_CREATE NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.FLOW_STATE MODIFY IS_FINAL NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.FLOW_STATE MODIFY IS_EDITABLE_BY_OWNER NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION MODIFY OWNER_CAN_SET NUMBER(1) NOT NULL;

grant select,insert on csr.non_compliance_file to csrimp;
grant select on csr.non_compliance_file_id_seq to csrimp;
grant insert,select,update,delete on csrimp.non_compliance_file to web_user;
grant select,insert,update,delete on csrimp.flow_state_cms_col to web_user;
grant select,insert,update,delete on csrimp.flow_state_transition_cms_col to web_user;
grant insert on csr.flow_state_cms_col to csrimp;
grant insert on csr.flow_state_transition_cms_col to csrimp;
grant select,insert,update,delete on csrimp.cms_tab_column_link to web_user;
grant select,insert,update,delete on csrimp.cms_tab_column_link_type to web_user;

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
			'FLOW_STATE_CMS_COL',
			'FLOW_STATE_TRANSITION_CMS_COL',
			'NON_COMPLIANCE_FILE'
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

-- Incident portlet addition (Description).
ALTER TABLE CSR.INCIDENT_TYPE ADD (DESCRIPTION CLOB);

@..\audit_pkg
@..\issue_pkg
@..\flow_pkg
@..\schema_pkg
@..\portlet_pkg
@..\incident_pkg
@..\..\..\aspen2\cms\db\util_pkg
@..\..\..\aspen2\cms\db\tab_pkg

@..\audit_body
@..\issue_body
@..\flow_body
@..\incident_body
@..\..\..\aspen2\cms\db\util_body
@..\..\..\aspen2\cms\db\tab_body
@..\postit_body
@..\csrimp\imp_body
@..\section_body
@..\schema_body
@..\portlet_body

-- fix appmenu export for recent clean builds
grant select on csr.role to security;
grant select on csr.role_grant to security;

@update_tail
