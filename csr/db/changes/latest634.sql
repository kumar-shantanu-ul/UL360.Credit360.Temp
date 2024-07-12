-- Please update version.sql too -- this keeps clean builds in sync
define version=634
@update_header

CREATE SEQUENCE csr.DELEG_TPL_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.DELEG_TPL(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_TPL_ID       NUMBER(10, 0)    NOT NULL,
    NAME               VARCHAR2(10)     NOT NULL,
    START_DTM          DATE             NOT NULL,
    END_DTM            DATE             NOT NULL,
    INTERVAL           VARCHAR2(10)     NOT NULL,
    REMINDER_OFFSET    NUMBER(10, 0)    DEFAULT 5 NOT NULL,
    CONSTRAINT PK890 PRIMARY KEY (APP_SID, DELEG_TPL_ID)
)
;

CREATE TABLE csr.DELEG_TPL_DELEG(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_TPL_ID        NUMBER(10, 0)    NOT NULL,
    DELEGATION_SID      NUMBER(10, 0)    NOT NULL,
    MAP_TO_DELEG_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK892 PRIMARY KEY (APP_SID, DELEG_TPL_ID, DELEGATION_SID)
)
;

CREATE TABLE csr.DELEG_TPL_DELEG_REGION(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_TPL_ID        NUMBER(10, 0)    NOT NULL,
    DELEGATION_SID      NUMBER(10, 0)    NOT NULL,
    MAP_TO_DELEG_SID    NUMBER(10, 0)    NOT NULL,
    REGION_SID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK893 PRIMARY KEY (APP_SID, DELEG_TPL_ID, DELEGATION_SID)
)
;

CREATE TABLE csr.DELEG_TPL_REGION(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_TPL_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK894 PRIMARY KEY (APP_SID, DELEG_TPL_ID, REGION_SID)
)
;

CREATE TABLE csr.DELEG_TPL_ROLE(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_TPL_ID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID        NUMBER(10, 0)    NOT NULL,
    POS             NUMBER(10, 0)    NOT NULL
)
;

ALTER TABLE csr.DELEG_TPL ADD CONSTRAINT RefCUSTOMER1973 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.DELEG_TPL_DELEG ADD CONSTRAINT RefDELEGATION1974 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES csr.DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE csr.DELEG_TPL_DELEG ADD CONSTRAINT RefDELEG_TPL1975 
    FOREIGN KEY (APP_SID, DELEG_TPL_ID)
    REFERENCES csr.DELEG_TPL(APP_SID, DELEG_TPL_ID)
;

ALTER TABLE csr.DELEG_TPL_DELEG_REGION ADD CONSTRAINT RefDELEG_TPL_DELEG1977 
    FOREIGN KEY (APP_SID, DELEG_TPL_ID, DELEGATION_SID)
    REFERENCES csr.DELEG_TPL_DELEG(APP_SID, DELEG_TPL_ID, DELEGATION_SID)
;

ALTER TABLE csr.DELEG_TPL_DELEG_REGION ADD CONSTRAINT RefDELEGATION1993 
    FOREIGN KEY (APP_SID, MAP_TO_DELEG_SID)
    REFERENCES csr.DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE csr.DELEG_TPL_DELEG_REGION ADD CONSTRAINT RefREGION2013 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.REGION(APP_SID, REGION_SID)
;

ALTER TABLE csr.DELEG_TPL_REGION ADD CONSTRAINT RefREGION1978 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.REGION(APP_SID, REGION_SID)
;

ALTER TABLE csr.DELEG_TPL_REGION ADD CONSTRAINT RefDELEG_TPL1979 
    FOREIGN KEY (APP_SID, DELEG_TPL_ID)
    REFERENCES csr.DELEG_TPL(APP_SID, DELEG_TPL_ID)
;

ALTER TABLE csr.DELEG_TPL_ROLE ADD CONSTRAINT RefROLE1980 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.DELEG_TPL_ROLE ADD CONSTRAINT RefDELEG_TPL1982 
    FOREIGN KEY (APP_SID, DELEG_TPL_ID)
    REFERENCES csr.DELEG_TPL(APP_SID, DELEG_TPL_ID)
;

@update_tail
