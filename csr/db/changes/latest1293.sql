-- Please update version.sql too -- this keeps clean builds in sync
define version=1293
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='REGION' and column_name='FLAG' and nullable='N') loop
		execute immediate 'alter table csr.region modify flag default null null';
	end loop;
end;
/
alter table csrimp.region modify flag null;
grant insert,select,update,delete on csrimp.master_deleg to web_user;

@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
