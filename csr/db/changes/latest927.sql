-- Please update version.sql too -- this keeps clean builds in sync
define version=927
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='DELEG_PLAN' and column_name='NAME' and data_length!=1023) loop
		execute immediate 'alter table csr.deleg_plan modify name varchar2(1023)';
	end loop;
end;
/

@update_tail
