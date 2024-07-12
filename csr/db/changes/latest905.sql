-- Please update version.sql too -- this keeps clean builds in sync
define version=905
@update_header

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='UK_FACTOR' and table_name='FACTOR') loop
		execute immediate 'alter table csr.factor drop constraint uk_factor';
	end loop;
end;
/

@update_tail
