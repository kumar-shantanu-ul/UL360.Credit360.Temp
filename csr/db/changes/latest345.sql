-- Please update version.sql too -- this keeps clean builds in sync
define version=345
@update_header

-- 
-- TABLE: TPL_REGION_TYPE 
--

CREATE TABLE TPL_REGION_TYPE(
    TPL_REGION_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                 VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK625 PRIMARY KEY (TPL_REGION_TYPE_ID)
)
;



-- 
-- TABLE: TPL_REPORT_TAG_DV_REGION 
--

CREATE TABLE TPL_REPORT_TAG_DV_REGION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_REPORT_SID        NUMBER(10, 0)    NOT NULL,
    TAG                   VARCHAR2(255)    NOT NULL,
    DATAVIEW_SID          NUMBER(10, 0)    NOT NULL,
    REGION_SID            NUMBER(10, 0)    NOT NULL,
    TPL_REGION_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK624 PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG, DATAVIEW_SID, REGION_SID)
)
;



COMMENT ON COLUMN TPL_REPORT_TAG_DV_REGION.DATAVIEW_SID IS 'RANGE_SID is normally the SID of a FORM or a DATAVIEW'
;
-- 
-- TABLE: TPL_REPORT_TAG_EVAL 
--


CREATE TABLE TPL_REPORT_TAG_EVAL(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_REPORT_SID    NUMBER(10, 0)     NOT NULL,
    TAG               VARCHAR2(255)     NOT NULL,
    COND              VARCHAR2(2000)    NOT NULL,
    IF_TRUE           VARCHAR2(2000),
    IF_FALSE          VARCHAR2(2000),
    CONSTRAINT PK626 PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG)
)
;



-- 
-- TABLE: TPL_REPORT_TAG_EVAL_IND 
--

CREATE TABLE TPL_REPORT_TAG_EVAL_IND(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_REPORT_SID    NUMBER(10, 0)    NOT NULL,
    TAG               VARCHAR2(255)    NOT NULL,
    IND_SID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK628 PRIMARY KEY (APP_SID, TPL_REPORT_SID, TAG, IND_SID)
)
;


-- 
-- TABLE: TPL_REPORT_TAG_DV_REGION 
--

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefTPL_REGION_TYPE1247 
    FOREIGN KEY (TPL_REGION_TYPE_ID)
    REFERENCES TPL_REGION_TYPE(TPL_REGION_TYPE_ID)
;

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefTPL_REPORT_TAG_DATAVIEW1248 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG, DATAVIEW_SID)
    REFERENCES TPL_REPORT_TAG_DATAVIEW(APP_SID, TPL_REPORT_SID, TAG, DATAVIEW_SID)
;

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefRANGE_REGION_MEMBER1249 
    FOREIGN KEY (APP_SID, DATAVIEW_SID, REGION_SID)
    REFERENCES CSR.RANGE_REGION_MEMBER(APP_SID, RANGE_SID, REGION_SID)
;


-- 
-- TABLE: TPL_REPORT_TAG_EVAL 
--

ALTER TABLE TPL_REPORT_TAG_EVAL ADD CONSTRAINT RefTPL_REPORT_TAG1250 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG(APP_SID, TPL_REPORT_SID, TAG)
;


-- 
-- TABLE: TPL_REPORT_TAG_EVAL_IND 
--

ALTER TABLE TPL_REPORT_TAG_EVAL_IND ADD CONSTRAINT RefIND1251 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE TPL_REPORT_TAG_EVAL_IND ADD CONSTRAINT RefTPL_REPORT_TAG_EVAL1252 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG)
    REFERENCES TPL_REPORT_TAG_EVAL(APP_SID, TPL_REPORT_SID, TAG)
;

@..\rls

@update_tail
