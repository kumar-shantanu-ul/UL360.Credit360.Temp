-- Please update version.sql too -- this keeps clean builds in sync
define version=729
@update_header

CREATE GLOBAL TEMPORARY TABLE csr.METER_IND_CHANGE 
(
  REGION_SID	NUMBER(10)	NOT NULL,
  NEW_IND_SID	NUMBER(10)	NOT NULL,
  FROM_DTM   	DATE,
  TO_DTM   		DATE,
  NOTE			VARCHAR2(1024)
)
ON COMMIT DELETE ROWS;

@../meter_pkg
@../meter_body
	 
@update_tail