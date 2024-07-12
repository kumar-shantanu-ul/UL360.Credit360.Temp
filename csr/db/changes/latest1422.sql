-- Please update version.sql too -- this keeps clean builds in sync
define version=1422
@update_header

DROP TABLE CSRIMP.TEMP_SHEET_VALUE;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.TEMP_SHEET_VALUE (
	RID								ROWID NOT NULL,
	NEW_SHEET_VALUE_ID				NUMBER(10) NOT NULL,
	NEW_SHEET_VALUE_CHANGE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_TEMP_SHEET_VALUE PRIMARY KEY (RID)
) ON COMMIT DELETE ROWS;

@update_tail
