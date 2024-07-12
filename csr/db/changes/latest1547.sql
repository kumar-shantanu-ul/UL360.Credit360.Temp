-- Please update version.sql too -- this keeps clean builds in sync
define version=1547
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='TEMP_SHEET_VALUE' and column_name='NEW_SHEET_VALUE_ID') loop
		execute immediate 'alter table csrimp.temp_sheet_value drop column new_sheet_value_id';
	end loop;
end;
/

@../csrimp/imp_body

@update_tail
