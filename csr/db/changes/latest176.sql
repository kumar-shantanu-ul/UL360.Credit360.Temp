-- Please update version.sql too -- this keeps clean builds in sync
define version=176
@update_header


-- 
-- TABLE: SNAPSHOT 
--

CREATE TABLE SNAPSHOT(
    APP_SID         NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    NAME            VARCHAR2(255)    NOT NULL,
    SNAPSHOT_DTM	DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK439 PRIMARY KEY (NAME)
)
;



-- 
-- TABLE: SNAPSHOT_IND 
--

CREATE TABLE SNAPSHOT_IND(
    NAME       VARCHAR2(255)    NOT NULL,
    IND_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK440 PRIMARY KEY (NAME, IND_SID)
)
;




-- 
-- TABLE: SNAPSHOT 
--

ALTER TABLE SNAPSHOT ADD CONSTRAINT RefTAG_GROUP864 
    FOREIGN KEY (TAG_GROUP_ID)
    REFERENCES TAG_GROUP(TAG_GROUP_ID)
;

ALTER TABLE SNAPSHOT ADD CONSTRAINT RefCUSTOMER865 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


-- 
-- TABLE: SNAPSHOT_IND 
--

ALTER TABLE SNAPSHOT_IND ADD CONSTRAINT RefIND866 
    FOREIGN KEY (IND_SID)
    REFERENCES IND(IND_SID)
;

ALTER TABLE SNAPSHOT_IND ADD CONSTRAINT RefSNAPSHOT867 
    FOREIGN KEY (NAME)
    REFERENCES SNAPSHOT(NAME)
;


begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SNAPSHOT',
        policy_name     => 'SNAPSHOT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.static );
end;
/

@update_tail
