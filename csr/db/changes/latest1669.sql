-- Please update version.sql too -- this keeps clean builds in sync
define version=1669
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_IMPORT_ROWS (
	SOURCE_ROW				NUMBER(10),
	PARENT_SID				NUMBER(10),
	METER_NAME				VARCHAR(1024),
	METER_REF				VARCHAR(256),
	CONSUMPTION_SID			NUMBER(10),
	CONSUMPTION_UOM			VARCHAR2(256),
	COST_SID				NUMBER(10),
	COST_UOM				VARCHAR2(256),
	ERROR_MSG				VARCHAR2(4000)
) ON COMMIT DELETE ROWS;

@../meter_pkg
@../meter_body

@update_tail


