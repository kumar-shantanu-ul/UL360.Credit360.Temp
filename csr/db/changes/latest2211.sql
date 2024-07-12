-- Please update version.sql too -- this keeps clean builds in sync
define version=2211
@update_header

begin
	for r in (select *
				from all_tab_columns
			   where owner='CSRIMP' and (table_name, column_name) IN (
			   	('CHAIN_CUSTOMER_OPTIONS', 'DASHBOARD_TASK_SCHEME_ID'),
			   	('CHAIN_CUSTOMER_OPTIONS', 'DEFAULT_AUTO_APPROVE_USERS'),
			   	('CHAIN_COMPANY', 'AUTO_APPROVE_USERS'))
			  ) loop
		execute immediate 'alter table '||r.owner||'.'||r.table_name||' drop column '||r.column_name;
	end loop;
end;
/

@update_tail
