-- Please update version.sql too -- this keeps clean builds in sync
define version=780
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='IMP_FILE_UPLOAD' and column_name='DATA' and nullable='N') loop
		execute immediate 'alter table csrimp.imp_file_upload modify data null';
	end loop;
end;
/

@../csrimp/imp_body

@update_tail