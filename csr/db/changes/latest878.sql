-- Please update version.sql too -- this keeps clean builds in sync
define version=878
@update_header

DROP TABLE CSR.USER_SETTING;

CREATE TABLE CSR.USER_SETTING(
    CATEGORY       VARCHAR2(100)     NOT NULL,
    SETTING        VARCHAR2(100)     NOT NULL,
    DESCRIPTION    VARCHAR2(1000)    NOT NULL,
    DATA_TYPE      VARCHAR2(10)      NOT NULL,
    CONSTRAINT CHK_US_CATEGORY_IS_VALID CHECK (CATEGORY = UPPER(TRIM(CATEGORY))),
    CONSTRAINT CHK_US_SETTING_IS_VALID CHECK (SETTING = TRIM(SETTING)),
    CONSTRAINT CHK_US_DATA_TYPE_IS_VALID CHECK (DATA_TYPE in ('STRING', 'NUMBER', 'BOOLEAN')),
    CONSTRAINT PK_USER_SETTING PRIMARY KEY (CATEGORY, SETTING)
)
;

CREATE TABLE CSR.USER_SETTING_ENTRY(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CSR_USER_SID      NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
    CATEGORY          VARCHAR2(100)     NOT NULL,
    SETTING           VARCHAR2(100)     NOT NULL,
    TAB_PORTLET_ID    NUMBER(10, 0),
    VALUE             VARCHAR2(4000)    NOT NULL
)
;


CREATE UNIQUE INDEX CSR.IDX_US_UNIQUE_SETTING ON CSR.USER_SETTING(CATEGORY, UPPER(SETTING));
CREATE UNIQUE INDEX CSR.UK_USER_SETTING_ENTRY ON CSR.USER_SETTING_ENTRY(APP_SID, CSR_USER_SID, CATEGORY, SETTING, TAB_PORTLET_ID)

ALTER TABLE CSR.USER_SETTING_ENTRY ADD CONSTRAINT FK_USR_SET_ENTRY_TAB_PORTLET 
    FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
    REFERENCES CSR.TAB_PORTLET(APP_SID, TAB_PORTLET_ID)
;

ALTER TABLE CSR.USER_SETTING_ENTRY ADD CONSTRAINT FK_USR_SET_ENTRY_USER 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.USER_SETTING_ENTRY ADD CONSTRAINT FK_USR_SET_ENTRY_USR_SET 
    FOREIGN KEY (CATEGORY, SETTING)
    REFERENCES CSR.USER_SETTING(CATEGORY, SETTING)
;


BEGIN
	FOR r IN (
		SELECT object_name, policy_name
		  FROM all_policies 
		 WHERE object_owner='CSR' 
		   AND object_name = 'USER_SETTING' 
		   AND policy_name = 'USER_SETTING_POLICY'
	) LOOP
		dbms_rls.drop_policy(
			object_schema   => 'CSR',
			object_name     => 'USER_SETTING',
			policy_name     => 'USER_SETTING_POLICY'
		);
    END LOOP;
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'USER_SETTING_ENTRY',
		policy_name     => 'USER_SETTING_ENTRY_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

CREATE OR REPLACE VIEW csr.V$USER_SETTING AS
	SELECT us.category, us.setting, us.data_type, use.value
	  FROM user_setting us, user_setting_entry use
	 WHERE use.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND use.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND use.category = us.category
	   AND use.setting = us.setting
	   AND use.tab_portlet_id IS NULL
	;

CREATE OR REPLACE VIEW csr.V$USER_PORTLET_SETTING AS
	SELECT us.category, us.setting, use.tab_portlet_id, us.data_type, use.value
	  FROM user_setting us, user_setting_entry use
	 WHERE use.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND use.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND use.category = us.category
	   AND use.setting = us.setting
	   AND use.tab_portlet_id IS NOT NULL
	;


@..\user_setting_pkg
@..\user_setting_body

@..\portlet_body

BEGIN
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'activeTab', 'STRING', 'stores the last active MySheets tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toApproveGroupBy', 'STRING', 'stores last group by combo selection on the toApprove tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toApproveStatus', 'NUMBER', 'stores last status radio selection on the toApprove tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toEnterGroupBy', 'STRING', 'stores last group by combo selection on the toEnter tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toEnterStatus', 'NUMBER', 'stores last status radio selection on the toEnter tab');
END;
/

@update_tail
