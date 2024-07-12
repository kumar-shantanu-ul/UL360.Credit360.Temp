-- Please update version.sql too -- this keeps clean builds in sync
define version=31
@update_header

CREATE SEQUENCE SCRIPT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

ALTER TABLE CUSTOMER_OPTIONS ADD(
	DEFAULT_VALUE_SCRIPT_ID    NUMBER(10, 0)	NULL
);

CREATE TABLE SCRIPT(
    SCRIPT_ID    NUMBER(10, 0)    NOT NULL,
    SCRIPT       CLOB,
    CONSTRAINT PK76 PRIMARY KEY (SCRIPT_ID)
)
;

ALTER TABLE CUSTOMER_OPTIONS ADD CONSTRAINT RefSCRIPT98 
    FOREIGN KEY (DEFAULT_VALUE_SCRIPT_ID)
    REFERENCES SCRIPT(SCRIPT_ID)
;

@update_tail
