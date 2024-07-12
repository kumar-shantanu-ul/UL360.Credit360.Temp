-- Please update version.sql too -- this keeps clean builds in sync
define version=1611
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_READING_ROWS (
	SOURCE_ROW				NUMBER(10),
	REGION_SID				NUMBER(10),
	START_DTM				DATE,
	END_DTM					DATE,
	CONSUMPTION				NUMBER(24,10),
	COST					NUMBER(24,10),
	REFERENCE				VARCHAR(1024),
	NOTE					VARCHAR(4000),
	ERROR_MSG				VARCHAR(4000)
) ON COMMIT DELETE ROWS;

@../meter_pkg
@../meter_body

@update_tail