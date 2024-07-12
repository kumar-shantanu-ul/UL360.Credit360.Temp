-- Please update version.sql too -- this keeps clean builds in sync
define version=1344
@update_header

-- wrong in the model
begin
	for r in (select 1
	  			from all_tab_columns
	  		   where data_precision is null
	  		   	 and data_scale is null
				 and owner = 'CMS'
				 and table_name = 'FLOW_TAB_COLUMN_CONS'
				 and column_name = 'FLOW_STATE_ID') loop
		execute immediate 'create table cms.ftc_backup as select * from cms.flow_tab_column_cons';
		execute immediate 'truncate table cms.flow_tab_column_cons';
		execute immediate 'alter table cms.flow_tab_column_cons modify flow_state_id number(10)';
		execute immediate 'insert into cms.flow_tab_column_cons select * from cms.ftc_backup';
		execute immediate 'drop table cms.ftc_backup';
	end loop;
end;
/

@update_tail
