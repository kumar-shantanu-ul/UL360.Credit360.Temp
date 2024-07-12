-- Please update version.sql too -- this keeps clean builds in sync
define version=455
@update_header

-- dropped columns not in csr.measure, so don't need to be dropped
-- foreign key constraint 1193 not set, so don't need to be removed

ALTER TABLE csr.measure
ADD STD_MEASURE_CONVERSION_ID NUMBER(10, 0);

-- 
-- TABLE: STD_MEASURE_CONV_PERIOD 
--
CREATE TABLE STD_MEASURE_CONV_PERIOD(
    STD_MEASURE_CONVERSION_ID    NUMBER(10, 0)    NOT NULL,
    START_DTM                    DATE             NOT NULL,
    END_DTM                      DATE,
    A                            NUMBER(10, 0)    NOT NULL,
    B                            NUMBER(10, 0)    NOT NULL,
    C                            NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_MEASURE_CONVERSION_PERIOD_1 PRIMARY KEY (STD_MEASURE_CONVERSION_ID, START_DTM)
)
;

ALTER TABLE CSR.MEASURE ADD CONSTRAINT RefSTD_MEASURE_CONVERSION1645 
    FOREIGN KEY (STD_MEASURE_CONVERSION_ID)
    REFERENCES STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID)
;

@update_tail
