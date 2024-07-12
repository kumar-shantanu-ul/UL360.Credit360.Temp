-- Please update version.sql too -- this keeps clean builds in sync
define version=1195
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='REGION' and column_name='PCT_OWNERSHIP') loop
		execute immediate 'alter table csr.region drop column pct_ownership';
	end loop;
end;
/

@update_tail
