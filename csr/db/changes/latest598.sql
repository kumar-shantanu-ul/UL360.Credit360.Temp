-- Please update version.sql too -- this keeps clean builds in sync
define version=598
@update_header

-- more differences between live and the model
begin
	for r in (select column_name from all_tab_columns where owner='CSR' and table_name='IMP_VAL' and column_name='VAL' and nullable='N') loop
		execute immediate 'alter table csr.imp_val modify val null';
	end loop;
end;
/

@update_tail
