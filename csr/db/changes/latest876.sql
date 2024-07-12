-- Please update version.sql too -- this keeps clean builds in sync
define version=876
@update_header

CREATE TABLE CSR.USER_SETTING(
    APP_SID          NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CSR_USER_SID     NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
    CATEGORY         VARCHAR2(100)     NOT NULL,
    SETTING          VARCHAR2(100)     NOT NULL,
    STRING_VALUE     VARCHAR2(4000),
    NUMBER_VALUE     NUMBER(10, 0),
    BOOLEAN_VALUE    NUMBER(1, 0),
    CONSTRAINT CHK_US_HAS_ONE_VALUE CHECK (
    	(string_value is not null and number_value is null and boolean_value is null) or
		(string_value is null and number_value is not null and boolean_value is null) or
		(string_value is null and number_value is null and boolean_value is not null)),
    CONSTRAINT CHK_US_CATEGORY_IS_UPPER CHECK (CATEGORY = UPPER(TRIM(CATEGORY))),
    CONSTRAINT CHK_US_SETTING_IS_UPPER CHECK (SETTING = TRIM(SETTING)),
    CONSTRAINT CHK_US_IS_BOOLEAN CHECK (BOOLEAN_VALUE IS NULL OR BOOLEAN_VALUE IN (0, 1))
)
;

CREATE UNIQUE INDEX CSR.IDX_US_UNIQUE_SETTING ON CSR.USER_SETTING(APP_SID, CSR_USER_SID, CATEGORY, UPPER(SETTING))
;

ALTER TABLE CSR.USER_SETTING ADD CONSTRAINT FK_USER_SETTING_USER 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'USER_SETTING',
		policy_name     => 'USER_SETTING_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@..\user_setting_pkg
@..\user_setting_body

grant execute on csr.user_setting_pkg to web_user;

@update_tail
