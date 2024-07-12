-- Please update version.sql too -- this keeps clean builds in sync
define version=1118
@update_header

alter table csr.role_grant modify app_sid DEFAULT SYS_CONTEXT('SECURITY','APP');
begin
	for r in (select nullable from all_tab_columns where owner='CSR' and table_name='ROLE_GRANT' and column_name='APP_SID' and nullable='Y') loop
		execute immediate 'alter table csr.role_grant modify app_sid not null';
	end loop;
end;
/

@update_tail
