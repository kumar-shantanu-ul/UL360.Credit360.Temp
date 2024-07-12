-- Please update version.sql too -- this keeps clean builds in sync
define version=2303
@update_header

-- 
-- TABLE: CSR.INTERNAL_AUDIT_FILE_CONNECTION 
--
CREATE TABLE CSR.INTERNAL_AUDIT_FILE_CONNECTION(
    APP_SID               		NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_SID    		NUMBER(10, 0)    NOT NULL,
    INTERNAL_AUDIT_FILE_ID  	NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_IA_FILE_CONNECTION PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, INTERNAL_AUDIT_FILE_ID),
	CONSTRAINT FK_IA_FILE_CONNECTION_AUDIT FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID) REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID),
	CONSTRAINT FK_IA_FILE_CONNECTION_FILE FOREIGN KEY (APP_SID, INTERNAL_AUDIT_FILE_ID) REFERENCES CSR.INTERNAL_AUDIT_FILE(APP_SID, INTERNAL_AUDIT_FILE_ID) ON DELETE CASCADE
)
;

create index csr.ix_internal_audi_file_con_id on csr.internal_audit_file_connection (app_sid, internal_audit_file_id)

-- 
-- TABLE: CSRIMP.INTERNAL_AUDIT_FILE_CONNECTION 
--
CREATE TABLE CSRIMP.INTERNAL_AUDIT_FILE_CONNECTION(
    CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_SID    		NUMBER(10, 0)    NOT NULL,
    INTERNAL_AUDIT_FILE_ID  	NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_IA_FILE_CONNECTION PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, INTERNAL_AUDIT_FILE_ID),
    CONSTRAINT FK_IA_FILE_CONNECTION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on csr.internal_audit_file_connection to csrimp;
grant select,insert,update,delete on csrimp.internal_audit_file_connection to web_user;


-- Copy INTERNAL_AUDIT_SID and INTERNAL_AUDIT_FILE_ID into new connection table
INSERT INTO CSR.INTERNAL_AUDIT_FILE_CONNECTION (app_sid, internal_audit_file_id, internal_audit_sid)
(	
	SELECT app_sid, internal_audit_file_id, internal_audit_sid
	FROM CSR.INTERNAL_AUDIT_FILE
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
        'INTERNAL_AUDIT_FILE_CONNECTION'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema
				=> 'CSR',
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

ALTER TABLE csr.internal_audit_file DROP CONSTRAINT FK_IA_FILE_IA;
ALTER TABLE csr.internal_audit_file RENAME COLUMN internal_audit_sid to xxx_internal_audit_sid;
ALTER TABLE csrimp.internal_audit_file RENAME COLUMN internal_audit_sid to xxx_internal_audit_sid;


@..\audit_pkg
@..\audit_body
@..\postit_pkg
@..\postit_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body
@..\csr_app_body

@update_tail