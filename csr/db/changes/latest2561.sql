-- Please update version.sql too -- this keeps clean builds in sync
define version=2561
@update_header

begin
	for r in (
		select *
		  from all_tab_columns 
		 where owner in ('CSR', 'CSRIMP')
		   and table_name in ('MEASURE_CONVERSION_PERIOD', 'MEASURE_CONVERSION')
		   and (data_precision != 24 or data_scale != 10)
		   and column_name in ('A', 'B', 'C')) loop
		execute immediate 'alter table '||r.owner||'.'||r.table_name||' modify '||r.column_name||' number(24,10)';
	end loop;
	for r in (
		select *
		  from all_tab_columns 
		 where owner in ('CSR', 'CSRIMP')
		   and table_name in ('MEASURE')
		   and (data_precision != 24 or data_scale != 10)
		   and column_name in ('FACTOR')) loop
		execute immediate 'alter table '||r.owner||'.'||r.table_name||' modify '||r.column_name||' number(24,10)';
	end loop;
end;
/

@update_tail