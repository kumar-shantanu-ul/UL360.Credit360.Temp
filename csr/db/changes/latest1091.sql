-- Please update version.sql too -- this keeps clean builds in sync
define version=1091
@update_header 


DROP TABLE CSRIMP.MEASURE_CONVERSION_PERIOD PURGE;

-- A, B, C was NUMBER(10) before. Oops
CREATE GLOBAL TEMPORARY TABLE CSRIMP.MEASURE_CONVERSION_PERIOD(
    MEASURE_CONVERSION_ID    NUMBER(10, 0)    NOT NULL,
    START_DTM                DATE             NOT NULL,
    END_DTM                  DATE,
    A                        NUMBER(24, 10)    NOT NULL,
    B                        NUMBER(24, 10)    NOT NULL,
    C                        NUMBER(24, 10)    NOT NULL,
    CONSTRAINT CK_MCONV_PERIOD_COMPLETED CHECK ((a is null and b is null and c is null) or (a is not null and b is not null and c is not null)),
    CONSTRAINT PK_MEASURE_CONVERSION_PERIOD PRIMARY KEY (MEASURE_CONVERSION_ID, START_DTM)
) ON COMMIT DELETE ROWS;

grant insert,select,update,delete on csrimp.measure_conversion_period to web_user;


CREATE TABLE CSR.TPL_IMG(
    APP_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    KEY        VARCHAR2(255)    NOT NULL,
    PATH       VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_TPL_IMG PRIMARY KEY (APP_SID, KEY)
);

CREATE UNIQUE INDEX CSR.IDX_TPL_IMG ON CSR.TPL_IMG(APP_SID, UPPER(KEY));

ALTER TABLE CSR.TPL_IMG ADD CONSTRAINT FK_CUS_TPL_IMG 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID);

@..\templated_report_pkg
@..\templated_report_body


@update_tail
