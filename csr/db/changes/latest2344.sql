-- Please update version.sql too -- this keeps clean builds in sync
define version=2344
@update_header

-- New table DELEGATION_LAYOUT
CREATE SEQUENCE csr.delegation_layout_id_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE CSR.DELEGATION_LAYOUT (
    APP_SID             NUMBER(10)          DEFAULT sys_context('security','app') NOT NULL,
    LAYOUT_ID           NUMBER(10)          NOT NULL,
    LAYOUT_XHTML        CLOB                NOT NULL,
    CONSTRAINT PK_DELEGATION_LAYOUT PRIMARY KEY (APP_SID, LAYOUT_ID) 
);

CREATE TABLE CSRIMP.DELEGATION_LAYOUT (
    CSRIMP_SESSION_ID   NUMBER(10)          DEFAULT sys_context('security','CSRIMP_SESSION_ID') NOT NULL,
    LAYOUT_ID           NUMBER(10)          NOT NULL,
    LAYOUT_XHTML        CLOB                NOT NULL,
    CONSTRAINT PK_DELEGATION_LAYOUT PRIMARY KEY (CSRIMP_SESSION_ID, LAYOUT_ID),
	CONSTRAINT FK_DELEGATION_LAYOUT_IS FOREIGN KEY (CSRIMP_SESSION_ID)
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_delegation_layout (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_delegation_layout_id	NUMBER(10) NOT NULL,
	new_delegation_layout_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_delegation_layout PRIMARY KEY (old_delegation_layout_id) USING INDEX,
	CONSTRAINT uk_map_delegation_layout UNIQUE (new_delegation_layout_id) USING INDEX,
	CONSTRAINT fk_map_delegation_layout_is 
		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- New referencing column on delegation
ALTER TABLE csr.delegation 
	ADD layout_id NUMBER(10)
	ADD CONSTRAINT FK_DELEG_DELEGATION_LAYOUT 
		FOREIGN KEY (APP_SID, LAYOUT_ID) 
		REFERENCES CSR.DELEGATION_LAYOUT (APP_SID, LAYOUT_ID);

ALTER TABLE csrimp.delegation ADD layout_id NUMBER(10);
		
-- Add to RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	DBMS_RLS.ADD_POLICY(
		object_schema   => 'CSR',
		object_name     => 'DELEGATION_LAYOUT',
		policy_name     => 'DELEGATION_LAYOUT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check    => true,
		policy_type     => dbms_rls.context_sensitive );
	DBMS_OUTPUT.PUT_LINE('Policy added to DELEGATION_LAYOUT');
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists for DELEGATION_LAYOUT');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied for DELEGATION_LAYOUT as feature not enabled');
END;
/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	DBMS_RLS.ADD_POLICY(
		object_schema   => 'CSRIMP',
		object_name     => 'DELEGATION_LAYOUT',
		policy_name     => 'DELEGATION_LAYOUT_POLICY',
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check    => true,
		policy_type     => dbms_rls.context_sensitive );
	DBMS_OUTPUT.PUT_LINE('Policy added to DELEGATION_LAYOUT');
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists for DELEGATION_LAYOUT');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied for DELEGATION_LAYOUT as feature not enabled');
END;
/


grant select,insert,update,delete on csrimp.delegation_layout to web_user;
grant select,insert,update,delete on csrimp.map_delegation_layout to web_user;
grant select on csr.delegation_layout_id_seq to csrimp;
grant insert,select,update on csr.delegation_layout to csrimp;

-- from @../create_views
CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

@../csrimp/imp_body
@../schema_pkg
@../schema_body
@../delegation_pkg 
@../delegation_body

@update_tail
