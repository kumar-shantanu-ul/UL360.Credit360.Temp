-- Please update version.sql too -- this keeps clean builds in sync
define version=587
@update_header

-- this is resolving differences between the model and live
begin
	for r in (select 1 from user_tab_columns where table_name='IND' and column_name='PCT_LOWER_TOLERANCE' and nullable='Y') loop
		update ind set pct_lower_tolerance=1 where pct_lower_tolerance is null;
		execute immediate 'alter table ind modify pct_lower_tolerance default 1 not null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='IND' and column_name='PCT_UPPER_TOLERANCE' and nullable='Y') loop
		update ind set pct_upper_tolerance=1 where pct_upper_tolerance is null;
		execute immediate 'alter table ind modify pct_upper_tolerance default 1 not null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='PENDING_IND' and column_name='SCORE') loop
		execute immediate 'alter table pending_ind drop column score';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='PENDING_IND' and column_name='AGGREGATE' and nullable='Y') loop
		execute immediate 'alter table pending_ind modify aggregate default ''SUM'' not null';
	end loop;
	for r in (select 1 from user_constraints where table_name='REGION' and constraint_name='DISPOSAL_DTM_ACTIVE' and constraint_type='C') loop
		execute immediate 'alter table region drop constraint disposal_dtm_active';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION' and column_name='A' and nullable='N') loop
		execute immediate 'alter table measure_conversion modify a null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION' and column_name='B' and nullable='N') loop
		execute immediate 'alter table measure_conversion modify b null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION' and column_name='C' and nullable='N') loop
		execute immediate 'alter table measure_conversion modify c null';
	end loop;
	update measure_conversion_period set c = 0 where c is null;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION_PERIOD' and column_name='A' and nullable='Y') loop
		execute immediate 'alter table measure_conversion_period modify a not null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION_PERIOD' and column_name='B' and nullable='Y') loop
		execute immediate 'alter table measure_conversion_period modify b not null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='MEASURE_CONVERSION_PERIOD' and column_name='C' and nullable='Y') loop
		execute immediate 'alter table measure_conversion_period modify c not null';
	end loop;
	for r in (select 1 from user_tab_columns where table_name='DATAVIEW' and column_name='POS' and nullable='Y') loop
		update dataview set pos=0 where pos is null;
		execute immediate 'alter table dataview modify pos not null';
	end loop;
end;
/

@../schema_pkg
@../schema_body
@../text/io_body

@update_tail
