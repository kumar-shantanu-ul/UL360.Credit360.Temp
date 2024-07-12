-- Please update version.sql too -- this keeps clean builds in sync
define version=1644
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='TRASH' and column_name='DESCRIPTION' and data_length != 4000) loop
		execute immediate 'alter table csr.trash modify description varchar2(4000)';
	end loop;
end;
/
@update_tail
