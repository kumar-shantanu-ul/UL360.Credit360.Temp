-- Please update version.sql too -- this keeps clean builds in sync
define version=248
@update_header

drop table TEMP_LOGGING_VAL;

CREATE GLOBAL TEMPORARY TABLE TEMP_LOGGING_VAL
(
  APP_SID			NUMBER(10)                  NOT NULL,
  IND_SID           NUMBER(10)                  NOT NULL,
  REGION_SID        NUMBER(10)                  NOT NULL,
  PERIOD_START_DTM  DATE                        NOT NULL,
  PERIOD_END_DTM    DATE                        NOT NULL
)
ON COMMIT DELETE ROWS
;

@update_tail
