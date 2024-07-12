-- Please update version.sql too -- this keeps clean builds in sync
define version=227
@update_header

 -- 
-- TABLE: TPL_REPORT 
--

CREATE TABLE TPL_REPORT(
    TPL_REPORT_SID    NUMBER(10, 0)     NOT NULL,
    NAME              VARCHAR2(256)     NOT NULL,
    DESCRIPTION       VARCHAR2(1024),
    APP_SID           NUMBER(10, 0)     NOT NULL,
    WORD_DOC          BLOB              NOT NULL,
    FILENAME          VARCHAR2(256)     NOT NULL,
    THUMB_IMG         BLOB,
    CONSTRAINT PK1001 PRIMARY KEY (TPL_REPORT_SID)
)
;



-- 
-- TABLE: TPL_REPORT_TAG 
--

CREATE TABLE TPL_REPORT_TAG(
    TPL_REPORT_SID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    TAG_TYPE          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1004 PRIMARY KEY (TPL_REPORT_SID, TAG)
)
;



-- 
-- TABLE: TPL_REPORT_TAG_DATAVIEW 
--

CREATE TABLE TPL_REPORT_TAG_DATAVIEW(
    TPL_REPORT_SID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    DATAVIEW_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1002 PRIMARY KEY (TPL_REPORT_SID, TAG, DATAVIEW_SID)
)
;



-- 
-- TABLE: TPL_REPORT_TAG_IND 
--

CREATE TABLE TPL_REPORT_TAG_IND(
    TPL_REPORT_SID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    IND_SID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK1003 PRIMARY KEY (TPL_REPORT_SID, TAG, IND_SID)
)
;



 -- 
-- TABLE: TPL_REPORT 
--

ALTER TABLE TPL_REPORT ADD CONSTRAINT RefCUSTOMER905 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;


-- 
-- TABLE: TPL_REPORT_TAG 
--

ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT REFTPL_REPORT1 
    FOREIGN KEY (TPL_REPORT_SID)
    REFERENCES TPL_REPORT(TPL_REPORT_SID) ON DELETE CASCADE
;


-- 
-- TABLE: TPL_REPORT_TAG_DATAVIEW 
--

ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT RefDATAVIEW907 
    FOREIGN KEY (DATAVIEW_SID)
    REFERENCES DATAVIEW(DATAVIEW_SID)
;

ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT REFTPL_REPORT_TAG2 
    FOREIGN KEY (TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG(TPL_REPORT_SID, TAG) ON DELETE CASCADE
;


-- 
-- TABLE: TPL_REPORT_TAG_IND 
--

ALTER TABLE TPL_REPORT_TAG_IND ADD CONSTRAINT RefIND909 
    FOREIGN KEY (IND_SID)
    REFERENCES IND(IND_SID)
;

ALTER TABLE TPL_REPORT_TAG_IND ADD CONSTRAINT REFTPL_REPORT_TAG3 
    FOREIGN KEY (TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG(TPL_REPORT_SID, TAG) ON DELETE CASCADE
;

 


-- rls 
BEGIN
dbms_rls.add_policy(
    object_schema   => 'CSR',
    object_name     => 'TPL_REPORT',
    policy_name     => 'TPL_REPORT_POLICY',
    function_schema => 'CSR',
    policy_function => 'appSidCheck',
    statement_types => 'select, insert, update, delete',
    update_check	=> true,
    policy_type     => dbms_rls.static );
END;
/

-- create sec obj class for TemplatedReport
DECLARE
    v_act_id			security_pkg.T_ACT_ID;
    v_class_id		security_pkg.T_SID_ID;
BEGIN	
    -- log on
    user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act_id);
    -- status sec obj
    BEGIN
        class_pkg.CreateClass(v_act_id, NULL, 'CSRTemplatedReport', 'csr.templated_report_pkg', NULL, v_class_id);
    EXCEPTION
        WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            null;
    END;
END;
/

@../templated_report_pkg
@../templated_report_body
grant execute on templated_report_pkg to security;
grant execute on templated_report_pkg to web_user;
	
@update_tail
