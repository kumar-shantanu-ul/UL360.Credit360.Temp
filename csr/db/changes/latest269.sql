-- Please update version.sql too -- this keeps clean builds in sync
define version=269
@update_header

-- 
-- TABLE: EVENT 
--

CREATE TABLE EVENT(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EVENT_ID                 NUMBER(10, 0)     NOT NULL,
    LABEL                    VARCHAR2(4000)    NOT NULL,
    RAISED_BY_USER_SID       NUMBER(10, 0)     NOT NULL,
    RAISED_DTM               DATE              DEFAULT SYSDATE NOT NULL,
    EVENT_TEXT               CLOB              NOT NULL,
    RAISED_FOR_REGION_SID    NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK1 PRIMARY KEY (APP_SID, EVENT_ID)
)
;



-- 
-- TABLE: REGION_EVENT 
--

CREATE TABLE REGION_EVENT(
    APP_SID       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID    NUMBER(10, 0)    NOT NULL,
    EVENT_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK3 PRIMARY KEY (APP_SID, REGION_SID, EVENT_ID)
)
;
 
-- 
-- TABLE: EVENT 
--

ALTER TABLE EVENT ADD CONSTRAINT RefCSR_USER1057 
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE EVENT ADD CONSTRAINT RefREGION1058 
    FOREIGN KEY (APP_SID, RAISED_FOR_REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE EVENT ADD CONSTRAINT RefCUSTOMER1059 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

-- 
-- TABLE: REGION_EVENT 
--

ALTER TABLE REGION_EVENT ADD CONSTRAINT RefREGION1060 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE REGION_EVENT ADD CONSTRAINT RefEVENT1061 
    FOREIGN KEY (APP_SID, EVENT_ID)
    REFERENCES EVENT(APP_SID, EVENT_ID)
;

-- 
-- SEQUENCE: EVENT_ID_SEQ 
--

CREATE SEQUENCE EVENT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;


begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'EVENT',
        policy_name     => 'EVENT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'REGION_EVENT',
        policy_name     => 'REGION_EVENT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

@update_tail

