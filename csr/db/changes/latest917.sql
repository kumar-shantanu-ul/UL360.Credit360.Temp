-- Please update version.sql too -- this keeps clean builds in sync
define version=917
@update_header

begin
	for r in (select table_name from all_tab_columns where owner='CSR' and table_name IN ('ALERT_TEMPLATE_BODY', 'ALERT_TEMPLATE', 'ALERT_BATCH_RUN') and column_name = 'ALERT_TYPE_ID') loop
		execute immediate 'alter table csr.'||r.table_name||' drop column alert_type_id';
	end loop;
end;
/

@update_tail
