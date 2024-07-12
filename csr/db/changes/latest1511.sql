-- Please update version.sql too -- this keeps clean builds in sync
define version=1511
@update_header
			
begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='FLOW_ITEM' and column_name='SECTION_SID') loop
		execute immediate 'alter table csr.flow_item drop column section_sid cascade constraints';
	end loop;
end;
/

@../section_body

@update_tail