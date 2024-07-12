-- Please update version.sql too -- this keeps clean builds in sync
define version=711
@update_header

CREATE TABLE csr.LOGISTICS_ERROR_LOG(
    APP_SID    NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    MESSAGE    VARCHAR2(2048)    NOT NULL,
    ID         NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK991 PRIMARY KEY (APP_SID, MESSAGE, ID)
)
;

ALTER TABLE csr.LOGISTICS_ERROR_LOG ADD CONSTRAINT RefCUSTOMER2207 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

@update_tail
