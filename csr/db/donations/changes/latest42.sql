-- Please update version.sql too -- this keeps clean builds in sync
define version=42
@update_header

-- TABLE: CUSTOMER_RECALC
--

CREATE TABLE CUSTOMER_RECALC(
    APP_SID       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROCESSING    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK107 PRIMARY KEY (APP_SID, PROCESSING)
)
;


ALTER TABLE CUSTOMER_RECALC ADD CONSTRAINT RefCUSTOMER165
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;


@../sys_pkg
@../sys_body
@../fields_body

@update_tail
