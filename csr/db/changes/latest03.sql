-- Please update version.sql too -- this keeps clean builds in sync
define version=03
@update_header

alter table measure drop column conversion_factor;
alter table measure drop column parent_measure_sid;

 CREATE TABLE MEASURE_CONVERSION_PERIOD(
     MEASURE_CONVERSION_ID    NUMBER(10, 0)    NOT NULL,
     START_DTM                DATE             NOT NULL,
     END_DTM                  DATE             NULL,
     CONVERSION_FACTOR        NUMBER(20, 8),
     CONSTRAINT PK99 PRIMARY KEY (MEASURE_CONVERSION_ID, START_DTM)
 )
 ;

ALTER TABLE MEASURE_CONVERSION_PERIOD ADD CONSTRAINT RefMEASURE_CONVERSION164 
    FOREIGN KEY (MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(MEASURE_CONVERSION_ID)
;



@update_tail
