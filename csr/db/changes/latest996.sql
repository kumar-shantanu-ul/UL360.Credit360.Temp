-- Please update version.sql too -- this keeps clean builds in sync
define version=996
@update_header

-- TABLE: CSR.LAST_USED_MEASURE_CONVERSION 
--

CREATE TABLE CSR.LAST_USED_MEASURE_CONVERSION(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CSR_USER_SID             NUMBER(10, 0)    NOT NULL,
    MEASURE_SID              NUMBER(10, 0)    NOT NULL,
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    CONSTRAINT PK_LAST_USED_MEASURE_CONV PRIMARY KEY (APP_SID, CSR_USER_SID, MEASURE_SID)
)
;

-- TABLE: CSR.LAST_USED_MEASURE_CONVERSION 
--

ALTER TABLE CSR.LAST_USED_MEASURE_CONVERSION ADD CONSTRAINT FK_MEASURE_LAST_USED_MEASURE 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES CSR.MEASURE(APP_SID, MEASURE_SID)
;

ALTER TABLE CSR.LAST_USED_MEASURE_CONVERSION ADD CONSTRAINT FK_MSRE_CONV_LAST_USED_MSRE 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.LAST_USED_MEASURE_CONVERSION ADD CONSTRAINT FK_USER_LAST_USED_MEASURE 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

@../rls
@../measure_pkg
@../measure_body

@update_tail
