-- Please update version.sql too -- this keeps clean builds in sync
define version=1239
@update_header

begin
	for r in (
		select r.constraint_name
		  from all_constraints r, all_constraints c
		 where r.owner='CSR' and r.table_name='TPL_REPORT_TAG_DV_REGION' and r.constraint_type='R'
		   and r.r_owner = 'CSR' and r.r_owner = c.owner and r.r_constraint_name = c.constraint_name
		   and c.table_name = 'RANGE_REGION_MEMBER') loop
		execute immediate 'alter table csr.TPL_REPORT_TAG_DV_REGION drop constraint '||r.constraint_name;
	end loop;
end;
/

@update_tail
