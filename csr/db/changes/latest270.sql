-- Please update version.sql too -- this keeps clean builds in sync
define version=270
@update_header

-- This file updates the CSR Schema to support the Excel-based Modelling module (first cut)

-- 
-- TABLE: MODEL 
--

CREATE TABLE MODEL(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MODEL_SID            NUMBER(10, 0)     NOT NULL,
    NAME                 VARCHAR2(255)     NOT NULL,
    DESCRIPTION          VARCHAR2(4000),
    EXCEL_DOC            BLOB              NOT NULL,
    FILENAME             VARCHAR2(255)     NOT NULL,
    THUMB_IMG            BLOB,
    CREATED_DTM          DATE              DEFAULT sysdate NOT NULL,
    TEMP_ONLY_BOO        NUMBER(1, 0)      DEFAULT 1,
    ACTIVE_SHEET_NAME    VARCHAR2(255),
    CONSTRAINT PK_MODEL PRIMARY KEY (APP_SID, MODEL_SID)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL_INSTANCE 
--

CREATE TABLE MODEL_INSTANCE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MODEL_INSTANCE_SID    NUMBER(10, 0)    NOT NULL,
    BASE_MODEL_SID        NUMBER(10, 0)    NOT NULL,
    REGION_SID            NUMBER(10, 0)    NOT NULL,
    START_DTM             DATE             NOT NULL,
    END_DTM               DATE             NOT NULL,
    OWNER_SID             NUMBER(10, 0)    NOT NULL,
    CREATED_DTM           DATE             NOT NULL,
    CONSTRAINT PK_MODEL_INSTANCE PRIMARY KEY (APP_SID, MODEL_INSTANCE_SID)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL_INSTANCE_FIELD 
--

CREATE TABLE MODEL_INSTANCE_FIELD(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BASE_MODEL_SID        NUMBER(10, 0)     NOT NULL,
    MODEL_INSTANCE_SID    NUMBER(10, 0)     NOT NULL,
    SHEET_NAME            VARCHAR2(255)     NOT NULL,
    CELL_NAME             VARCHAR2(20)      NOT NULL,
    CELL_VALUE            VARCHAR2(4000),
    CONSTRAINT PK_MODEL_INSTANCE_FIELD PRIMARY KEY (APP_SID, BASE_MODEL_SID, MODEL_INSTANCE_SID, SHEET_NAME, CELL_NAME)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL_MAP 
--

CREATE TABLE MODEL_MAP(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MODEL_SID               NUMBER(10, 0)    NOT NULL,
    SHEET_NAME              VARCHAR2(255)    NOT NULL,
    CELL_NAME               VARCHAR2(20)     NOT NULL,
    MODEL_MAP_TYPE_ID       NUMBER(10, 0)    NOT NULL,
    MAP_TO_INDICATOR_SID    NUMBER(10, 0),
    CELL_COMMENT            CLOB,
    EXCEL_NAME              VARCHAR2(255),
    CONSTRAINT PK_MODEL_MAP PRIMARY KEY (APP_SID, MODEL_SID, SHEET_NAME, CELL_NAME)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL_MAP_TYPE 
--

CREATE TABLE MODEL_MAP_TYPE(
    MODEL_MAP_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    MAP_TYPE             VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_MODEL_MAP_TYPE PRIMARY KEY (MODEL_MAP_TYPE_ID)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL_SHEET 
--

CREATE TABLE MODEL_SHEET(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MODEL_SID            NUMBER(10, 0)    NOT NULL,
    SHEET_NAME           VARCHAR2(255)    NOT NULL,
    USER_EDITABLE_BOO    NUMBER(1, 0),
    RUN_HTML             CLOB,
    EDIT_HTML            CLOB,
    SHEET_INDEX          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_MODEL_SHEET PRIMARY KEY (APP_SID, MODEL_SID, SHEET_NAME)
    USING INDEX
TABLESPACE INDX
)
;



-- 
-- TABLE: MODEL 
--

ALTER TABLE MODEL ADD CONSTRAINT RefCUSTOMER1075 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


-- 
-- TABLE: MODEL_INSTANCE 
--

ALTER TABLE MODEL_INSTANCE ADD CONSTRAINT RefREGION1076 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE MODEL_INSTANCE ADD CONSTRAINT RefCUSTOMER1077 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE MODEL_INSTANCE ADD CONSTRAINT RefMODEL1078 
    FOREIGN KEY (APP_SID, BASE_MODEL_SID)
    REFERENCES MODEL(APP_SID, MODEL_SID)
;

ALTER TABLE MODEL_INSTANCE ADD CONSTRAINT RefCSR_USER1079 
    FOREIGN KEY (APP_SID, OWNER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;


-- 
-- TABLE: MODEL_INSTANCE_FIELD 
--

ALTER TABLE MODEL_INSTANCE_FIELD ADD CONSTRAINT RefMODEL_INSTANCE1081 
    FOREIGN KEY (APP_SID, MODEL_INSTANCE_SID)
    REFERENCES MODEL_INSTANCE(APP_SID, MODEL_INSTANCE_SID)
;

ALTER TABLE MODEL_INSTANCE_FIELD ADD CONSTRAINT RefMODEL_MAP1087 
    FOREIGN KEY (APP_SID, BASE_MODEL_SID, SHEET_NAME, CELL_NAME)
    REFERENCES MODEL_MAP(APP_SID, MODEL_SID, SHEET_NAME, CELL_NAME)
;


-- 
-- TABLE: MODEL_MAP 
--

ALTER TABLE MODEL_MAP ADD CONSTRAINT RefMODEL_MAP_TYPE1082 
    FOREIGN KEY (MODEL_MAP_TYPE_ID)
    REFERENCES MODEL_MAP_TYPE(MODEL_MAP_TYPE_ID)
;

ALTER TABLE MODEL_MAP ADD CONSTRAINT RefIND1083 
    FOREIGN KEY (APP_SID, MAP_TO_INDICATOR_SID)
    REFERENCES IND(APP_SID, IND_SID)
;

ALTER TABLE MODEL_MAP ADD CONSTRAINT RefMODEL_SHEET1084 
    FOREIGN KEY (APP_SID, MODEL_SID, SHEET_NAME)
    REFERENCES MODEL_SHEET(APP_SID, MODEL_SID, SHEET_NAME)
;


-- 
-- TABLE: MODEL_SHEET 
--

ALTER TABLE MODEL_SHEET ADD CONSTRAINT RefMODEL1085 
    FOREIGN KEY (APP_SID, MODEL_SID)
    REFERENCES MODEL(APP_SID, MODEL_SID)
;




Begin
Insert into MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 Values
   (0, 'Unknown');
Insert into MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 Values
   (1, 'User Editable Field');
Insert into MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 Values
   (2, 'Mapped Field');
Insert into MODEL_MAP_TYPE
   (MODEL_MAP_TYPE_ID, MAP_TYPE)
 Values
   (3, 'Formula Field');
End;
/

@../model_pkg
@../model_body


begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MODEL',
        policy_name     => 'MODEL_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MODEL_INSTANCE',
        policy_name     => 'MODEL_INSTANCE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MODEL_INSTANCE_FIELD',
        policy_name     => 'MODEL_INSTANCE_FIELD_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MODEL_MAP',
        policy_name     => 'MODEL_MAP_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'MODEL_SHEET',
        policy_name     => 'MODEL_SHEET_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/


-- create sec obj class for CSRModel
DECLARE
    v_act_id            security_pkg.T_ACT_ID;
    v_class_id        security_pkg.T_SID_ID;
BEGIN    
    -- log on
    user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act_id);
    -- status sec obj
    BEGIN
        class_pkg.CreateClass(v_act_id, NULL, 'CSRModel', 'csr.model_pkg', NULL, v_class_id);
    EXCEPTION
        WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            null;
    END;
END;
/

-- create sec obj class for CSRModel
DECLARE
    v_act_id            security_pkg.T_ACT_ID;
    v_class_id        security_pkg.T_SID_ID;
BEGIN    
    -- log on
    user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act_id);
    -- status sec obj
    BEGIN
        class_pkg.CreateClass(v_act_id, NULL, 'CSRModelInstance', 'csr.model_pkg', NULL, v_class_id);
    EXCEPTION
        WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            null;
    END;
END;
/


grant execute on model_pkg to security;
grant execute on model_pkg to web_user;

@update_tail