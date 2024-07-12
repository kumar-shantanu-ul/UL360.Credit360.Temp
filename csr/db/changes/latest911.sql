-- Please update version.sql too -- this keeps clean builds in sync
define version=911
@update_header

CREATE GLOBAL TEMPORARY TABLE csr.temp_first_sheet_action_dtm (
	app_sid 				NUMBER(10) NOT NULL,
	sheet_id 				NUMBER(10) NOT NULL,
	first_action_dtm 		DATE NOT NULL
) ON COMMIT DELETE ROWS;

@../delegation_pkg
@../delegation_body

@update_tail
