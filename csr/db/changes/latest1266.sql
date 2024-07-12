-- Please update version.sql too -- this keeps clean builds in sync
define version=1266
@update_header

begin
	for r in (select constraint_name from all_constraints where owner='CSR' and table_name='ROLE' and constraint_name='UK_ROLE_LOOKUP_KEY') loop
		execute immediate 'alter table csr.role drop constraint UK_ROLE_LOOKUP_KEY';
	end loop;
	for r in (select index_name from all_indexes where owner='CSR' and table_name='ROLE' and index_name='UK_ROLE_LOOKUP_KEY') loop
		execute immediate 'drop index csr.UK_ROLE_LOOKUP_KEY';
	end loop;
	execute immediate 'CREATE UNIQUE INDEX csr.UK_ROLE_LOOKUP_KEY ON csr.ROLE(APP_SID, UPPER(NVL(LOOKUP_KEY,ROLE_SID)))';
end;
/

@update_tail
