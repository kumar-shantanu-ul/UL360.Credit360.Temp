--Please update version.sql too -- this keeps clean builds in sync
define version=2676
@update_header

declare
	v_exists number;
begin
	select count(*) into v_exists from all_Tables where owner='CSR' and table_name='TEMP_SHEET_ID';
	if v_exists = 0 then
		execute immediate 'create global temporary table csr.temp_sheet_id (sheet_id number(10)) on commit delete rows';
	end if;
end;
/

@../val_datasource_body

@update_tail
