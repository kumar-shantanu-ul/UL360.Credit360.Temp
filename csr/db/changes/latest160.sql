-- Please update version.sql too -- this keeps clean builds in sync
define version=160
@update_header

DROP TABLE GET_VALUE_RESULT;

CREATE GLOBAL TEMPORARY TABLE GET_VALUE_RESULT
(
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	source_id			NUMBER(10,0),
	ind_sid				NUMBER(10,0),
	region_sid			NUMBER(10,0),
	val_number			NUMBER(24,10),
	changed_dtm			DATE,
	note				CLOB,
	flags				NUMBER (10,0),
	is_leaf				NUMBER(1,0),
	is_merged			NUMBER(1,0),
	path				VARCHAR2(1024)
) ON COMMIT DELETE ROWS;

@..\indicator_body
@..\sheet_body
	  
	  
@update_tail
