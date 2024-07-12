-- Please update version.sql too -- this keeps clean builds in sync
define version=2316
@update_header

declare
	v_exists number;
begin
	select count(*) 
  	  into v_exists
   	  from all_tables 
 	 where owner='CSR' and table_name='TEMP_SHEETS_IND_REGION_TO_USE2';
	if v_exists = 0 then
		execute immediate 
'CREATE GLOBAL TEMPORARY TABLE CSR.temp_sheets_ind_region_to_use2 (
	app_sid 						number(10),
	delegation_sid					number(10),
	lvl 							number(10),
	sheet_id 						number(10),
	ind_sid							number(10),
	region_sid						number(10),
	start_dtm 						date,
	end_dtm 						date,
	last_action_colour 				varchar(1)
) ON COMMIT DELETE ROWS';
	end if;
end;
/

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail