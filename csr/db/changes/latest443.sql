-- Please update version.sql too -- this keeps clean builds in sync
define version=443
@update_header

ALTER TABLE property_division ADD(app_sid NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL);

ALTER TABLE PROPERTY_DIVISION ADD CONSTRAINT RefCUSTOMER1627 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

@update_tail
