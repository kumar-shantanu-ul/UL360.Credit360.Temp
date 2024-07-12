-- Please update version.sql too -- this keeps clean builds in sync
define version=2510
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='REGION_SET' and column_name='OWNER_SID' and nullable='N') loop
		execute immediate 'alter table csr.region_set modify owner_sid null';
	end loop;
end;
/

@update_tail