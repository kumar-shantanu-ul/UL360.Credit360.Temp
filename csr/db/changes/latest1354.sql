-- Please update version.sql too -- this keeps clean builds in sync
define version=1354
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.TEMP_SHEET_VALUE (
	RID								ROWID NOT NULL,
	NEW_SHEET_VALUE_ID				NUMBER(10) NOT NULL,
	NEW_SHEET_VALUE_CHANGE_ID		NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;

@../csrimp/imp_body

@update_tail
