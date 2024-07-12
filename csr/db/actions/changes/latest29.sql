-- Please update version.sql too -- this keeps clean builds in sync
define version=29
@update_header

begin
	for r in (select *
	  			from user_tab_columns 
	  		   where table_name='TASK' and 
					 column_name='WEIGHTING' and 
					 data_precision=1) loop
		execute immediate 'alter table task modify weighting number(3,2)';
	end loop;
end;
/

@update_tail
