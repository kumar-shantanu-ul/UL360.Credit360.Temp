-- Please update version.sql too -- this keeps clean builds in sync
define version=2092
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tables
	 where owner = 'CSR' and table_name = 'TEMP_DELEGATION_TREE';
	if v_exists = 0 then
		execute immediate '
			create global temporary table csr.temp_delegation_tree (
				delegation_sid number(10),
				parent_sid number(10),
				lvl number(10)
			) on commit delete rows';
	end if;
end;
/

@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
