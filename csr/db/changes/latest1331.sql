-- Please update version.sql too -- this keeps clean builds in sync
define version=1331
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='MODEL_MAP' and column_name='EXCEL_NAME') loop
		execute immediate 'alter table csr.model_map drop column excel_name';
	end loop;
end;
/

alter table csrimp.model_map drop column excel_name;

@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
