-- Please update version.sql too -- this keeps clean builds in sync
define version=1213
@update_header

CREATE GLOBAL TEMPORARY TABLE CT.TT_WORKSHEET_SEARCH
(
	WORKSHEET_ID NUMBER(10) NOT NULL,
	UPLOADED_DATE DATE
) ON COMMIT DELETE ROWS;

@..\ct\excel_pkg
@..\ct\excel_body

@update_tail