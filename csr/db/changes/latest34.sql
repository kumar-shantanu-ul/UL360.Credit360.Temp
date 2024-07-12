-- Please update version.sql too -- this keeps clean builds in sync
define version=34
@update_header

DROP TABLE val_flag;

ALTER TABLE ind_flag DROP COLUMN ACCURACY_WEIGHTING;

-- 
-- TABLE: IND_DATA_SOURCE_TYPE
--

CREATE TABLE IND_DATA_SOURCE_TYPE(
    IND_SID                NUMBER(10, 0)    NOT NULL,
    DATA_SOURCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK165 PRIMARY KEY (IND_SID, DATA_SOURCE_TYPE_ID)
)
;

CREATE TABLE DATA_SOURCE_TYPE(
    DATA_SOURCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID           NUMBER(10, 0)    NOT NULL,
    LABEL                  VARCHAR2(255)    NOT NULL,
    Q_OR_C                 CHAR(1)           DEFAULT 'Q' NOT NULL,
    MAX_SCORE              NUMBER(10, 0)     DEFAULT 10 NOT NULL,
    CONSTRAINT PK162 PRIMARY KEY (DATA_SOURCE_TYPE_ID)
)
;


CREATE TABLE DATA_SOURCE(
    DATA_SOURCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DATA_SOURCE_ID         NUMBER(10, 0)    NOT NULL,
    LABEL                  VARCHAR2(255)    NOT NULL,
    ACCURACY_WEIGHTING     NUMBER(10, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT PK166 PRIMARY KEY (DATA_SOURCE_ID)
)
;


CREATE TABLE VAL_DATA_SOURCE(
    VAL_ID            NUMBER(10, 0)    NOT NULL,
    DATA_SOURCE_ID    NUMBER(10, 0)    NOT NULL,
    PCT               NUMBER(10, 4)     DEFAULT 1 NOT NULL,
    CONSTRAINT PK167 PRIMARY KEY (VAL_ID, DATA_SOURCE_ID)
)
;





ALTER TABLE VAL_DATA_SOURCE ADD CONSTRAINT RefDATA_SOURCE274 
    FOREIGN KEY (DATA_SOURCE_ID)
    REFERENCES DATA_SOURCE(DATA_SOURCE_ID)
;

ALTER TABLE VAL_DATA_SOURCE ADD CONSTRAINT RefVAL275 
    FOREIGN KEY (VAL_ID)
    REFERENCES VAL(VAL_ID)
;


-- TABLE: IND_DATA_SOURCE 
--

ALTER TABLE IND_DATA_SOURCE_TYPE ADD CONSTRAINT RefDATA_SOURCE_TYPE272 
    FOREIGN KEY (DATA_SOURCE_TYPE_ID)
    REFERENCES DATA_SOURCE_TYPE(DATA_SOURCE_TYPE_ID)
;

ALTER TABLE IND_DATA_SOURCE_TYPE ADD CONSTRAINT RefIND273 
    FOREIGN KEY (IND_SID)
    REFERENCES IND(IND_SID)
;



ALTER TABLE DATA_SOURCE_TYPE ADD CONSTRAINT RefCUSTOMER271 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;


ALTER TABLE DATA_SOURCE ADD CONSTRAINT RefDATA_SOURCE_TYPE270 
    FOREIGN KEY (DATA_SOURCE_TYPE_ID)
    REFERENCES DATA_SOURCE_TYPE(DATA_SOURCE_TYPE_ID)
;



CREATE SEQUENCE DATA_SOURCE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

-- 
-- SEQUENCE: DATA_SOURCE_TYPE_ID_SEQ 
--

CREATE SEQUENCE DATA_SOURCE_TYPE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

@update_tail
