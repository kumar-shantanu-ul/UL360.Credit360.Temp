-- Please update version.sql too -- this keeps clean builds in sync
define version=364
@update_header

CREATE SEQUENCE UTILITY_INVOICE_COMMENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE UTILITY_INVOICE ADD (
	VERIFIED_BY_SID        NUMBER(10, 0),
    VERIFIED_DTM           DATE
)
;


CREATE TABLE UTILITY_INVOICE_COMMENT(
    APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    UTILITY_INVOICE_COMMENT_ID    NUMBER(10, 0)    NOT NULL,
    UTILITY_INVOICE_ID            NUMBER(10, 0)    NOT NULL,
    ENTERED_BY_SID                NUMBER(10, 0)    NOT NULL,
    ENTERED_DTM                   NUMBER(10, 0)    NOT NULL,
    INVOICE_COMMENT               CLOB,
    CONSTRAINT PK636 PRIMARY KEY (APP_SID, UTILITY_INVOICE_COMMENT_ID)
)
;

ALTER TABLE UTILITY_INVOICE_COMMENT ADD CONSTRAINT RefUTILITY_INVOICE1267 
    FOREIGN KEY (APP_SID, UTILITY_INVOICE_ID)
    REFERENCES UTILITY_INVOICE(APP_SID, UTILITY_INVOICE_ID) ON DELETE CASCADE
;

ALTER TABLE UTILITY_INVOICE_COMMENT ADD CONSTRAINT RefCUSTOMER1270 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

@..\rls

@update_tail
