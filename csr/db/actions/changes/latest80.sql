-- Please update version.sql too -- this keeps clean builds in sync
define version=80
@update_header

CREATE SEQUENCE IMPORT_MAPPING_POS_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE IMPORT_MAPPING_MRU(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CSR_USER_SID    NUMBER(10, 0)    NOT NULL,
    FROM_NAME       VARCHAR2(1024)     NOT NULL,
    TO_NAME         VARCHAR2(1024)     NOT NULL,
    POS             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK141 PRIMARY KEY (APP_SID, CSR_USER_SID, FROM_NAME, TO_NAME)
)
;

ALTER TABLE IMPORT_MAPPING_MRU ADD CONSTRAINT RefCSR_USER276 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

begin
    dbms_rls.add_policy(
        object_schema   => 'ACTIONS',
        object_name     => 'IMPORT_MAPPING_MRU',
        policy_name     => 'IMPORT_MAPPING_MRU_POLICY',
        function_schema => 'ACTIONS',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/
	
@../importer_pkg
@../importer_body
grant execute on importer_pkg to web_user;

@update_tail
