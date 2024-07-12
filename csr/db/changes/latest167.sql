-- Please update version.sql too -- this keeps clean builds in sync
define version=167
@update_header

-- drop some old tables on live
begin
	for r in (select table_name from user_tables where table_name in 
		('DATA_SOURCE_TYPE','DATA_SOURCE', 'IND_DATA_SOURCE_TYPE', 
		 'SHEET_VALUE_DATA_SOURCE', 'VAL_DATA_SOURCE', 
		 'JOB_TEST', 'QWE')) loop
		execute immediate 'drop table '||r.table_name;
	end loop;
end;
/

@update_tail
