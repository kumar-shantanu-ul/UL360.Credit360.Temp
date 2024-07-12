-- Please update version.sql too -- this keeps clean builds in sync
define version=2007
@update_header

CREATE SEQUENCE CSR.INITIATIVE_EVENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE TABLE CSR.INITIATIVE_EVENT(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INITIATIVE_EVENT_ID  NUMBER(10, 0)     NOT NULL,
    INITIATIVE_SID       NUMBER(10, 0)     NOT NULL,
    DESCRIPTION          VARCHAR2(4000),
    START_DTM            DATE              NOT NULL,
    END_DTM              DATE,
    CREATED_BY_SID       NUMBER(10, 0)     NOT NULL,
    CREATED_DTM          DATE              DEFAULT SYSDATE NOT NULL,
	LOCATION 			 VARCHAR2(1000),
    CONSTRAINT CK_INITIATIVE_EVENT_DTM CHECK (END_DTM IS NULL OR END_DTM >= START_DTM),
    CONSTRAINT PK_INITIATIVE_EVENT PRIMARY KEY (APP_SID, INITIATIVE_EVENT_ID)
);

ALTER TABLE CSR.INITIATIVE_EVENT ADD CONSTRAINT FK_INIT_EVENT_INIT 
    FOREIGN KEY (APP_SID, INITIATIVE_SID)
    REFERENCES CSR.INITIATIVE(APP_SID, INITIATIVE_SID);

ALTER TABLE CSR.INITIATIVE_EVENT ADD CONSTRAINT FK_INIT_EVENT_USER 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN   
    v_list := t_tabs(  
        'INITIATIVE_EVENT'
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
	
@..\initiative_pkg
@..\teamroom_initiative_pkg.sql

@..\initiative_body
@..\teamroom_initiative_body.sql
@..\teamroom_body.sql
	   
@update_tail