-- Please update version.sql too -- this keeps clean builds in sync
define version=220
@update_header

begin
	for r in (select 1 from user_tab_columns where column_name='LOCKED_BY_SID' and table_name='DOC_CURRENT' and nullable='N') loop
		execute immediate 'alter table doc_current modify locked_by_sid null';
	end loop;
end;
/

@update_tail