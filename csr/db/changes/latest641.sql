-- Please update version.sql too -- this keeps clean builds in sync
define version=641
@update_header

-- differences between live + local - missing change script?
begin
	for r in (select 1 from all_tab_columns where owner='CSR' and column_name='LEFT_SIDE_TYPE' and table_name='AXIS' and nullable='N') loop
		execute immediate 'alter table csr.axis modify left_side_type null';
	end loop;
	for r in (select 1 from all_tab_columns where owner='CSR' and column_name='RIGHT_SIDE_TYPE' and table_name='AXIS' and nullable='N') loop
		execute immediate 'alter table csr.axis modify right_side_type null';
	end loop;
end;
/

@update_tail
