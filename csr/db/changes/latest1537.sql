-- Please update version.sql too -- this keeps clean builds in sync
define version=1537
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.TEMP_SHEET_HISTORY (
	RID								ROWID NOT NULL,
	NEW_SHEET_HISTORY_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_TEMP_SHEET_HISTORY PRIMARY KEY (RID)
) ON COMMIT DELETE ROWS;

@../csrimp/imp_body

@update_tail