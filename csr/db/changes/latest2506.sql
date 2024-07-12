-- Please update version.sql too -- this keeps clean builds in sync
define version=2506
@update_header

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and column_name='TABLE_NUMBER' and table_name='CSRIMP_SESSION';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.csrimp_session add table_number number(10) default 0 not null';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and column_name='TABLE_ROW' and table_name='CSRIMP_SESSION';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.csrimp_session add table_row number(10) default 0 not null';
	end if;
end;
/

@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
