-- Please update version.sql too -- this keeps clean builds in sync
define version=583
@update_header


CREATE OR REPLACE TYPE T_NORMALISED_VAL_ROW AS 
  OBJECT ( 
	REGION_SID		NUMBER(10),
	START_DTM		DATE,
	END_DTM			DATE,
	VAL_NUMBER		NUMBER(24, 10)
  );
/
CREATE OR REPLACE TYPE T_NORMALISED_VAL_TABLE AS 
  TABLE OF T_NORMALISED_VAL_ROW;
/


@..\measure_pkg
@..\val_pkg

@..\measure_body
@..\val_body
@..\sheet_body

@update_tail
