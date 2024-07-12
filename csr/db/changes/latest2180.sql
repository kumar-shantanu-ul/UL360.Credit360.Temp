-- Please update version.sql too -- this keeps clean builds in sync
 define version=2180
 @update_header

CREATE TABLE CSR.HIDE_PORTLET (
    APP_SID             NUMBER(10)          DEFAULT sys_context('security','app') NOT NULL,
    PORTLET_ID          NUMBER(10)          NOT NULL,
    CONSTRAINT PK_HIDE_PORTLET PRIMARY KEY (APP_SID, PORTLET_ID),
    CONSTRAINT FK_HIDE_PORTLET_PORTLET FOREIGN KEY (PORTLET_ID) REFERENCES CSR.PORTLET (PORTLET_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.HIDE_PORTLET (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PORTLET_ID          NUMBER(10)          NOT NULL,
    CONSTRAINT PK_HIDE_PORTLET PRIMARY KEY (CSRIMP_SESSION_ID, PORTLET_ID),
	CONSTRAINT FK_HIDE_PORTLET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

/* RLS */   
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'HIDE_PORTLET',
		policy_name     => 'HIDE_PORTLET_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

@../portlet_body

GRANT INSERT ON CSR.HIDE_PORTLET TO CSRIMP;
@../csrimp/imp_body

@../schema_pkg
@../schema_body

@update_tail