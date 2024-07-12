-- Please update version.sql too -- this keeps clean builds in sync
define version=624
@update_header

CREATE GLOBAL TEMPORARY TABLE csr.temp_sheets_to_use (
	app_sid 						number(10), 
	delegation_sid					number(10),
	lvl 							number(10),
	sheet_id 						number(10), 
	start_dtm 						date,
	end_dtm 						date, 
	last_action_colour 				varchar(1)
) ON COMMIT DELETE ROWS;

@../val_datasource_body

@update_tail
