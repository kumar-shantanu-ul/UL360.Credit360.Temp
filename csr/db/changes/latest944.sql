-- Please update version.sql too -- this keeps clean builds in sync
define version=944
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.temp_sheets_ind_region_to_use (
	app_sid 						number(10),
	delegation_sid					number(10),
	lvl 							number(10),
	sheet_id 						number(10),
	ind_sid							number(10),
	region_sid						number(10),
	start_dtm 						date,
	end_dtm 						date,
	last_action_colour 				varchar(1)
) ON COMMIT DELETE ROWS;

@update_tail
