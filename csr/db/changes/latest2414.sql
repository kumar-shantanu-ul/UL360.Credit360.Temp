-- Please update version.sql too -- this keeps clean builds in sync
define version=2414
@update_header
	
CREATE TABLE CSR.PROPERTY_CHARACTER_LAYOUT (
	APP_SID				NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ELEMENT_NAME		VARCHAR2(255)		NOT NULL,
	POS					NUMBER(10, 0)		NOT NULL,
	COL					NUMBER(10, 0)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_PROPERTY_CHAR_LAYOUT PRIMARY KEY (APP_SID, ELEMENT_NAME),
	CONSTRAINT FK_PROPERTY_CHAR_LAYOUT_CUST FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID)
);

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'PROPERTY_CHARACTER_LAYOUT',
		policy_name     => 'PROPERTY_CHAR_LAYOUT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../property_pkg
@../property_body

@update_tail