-- Please update version.sql too -- this keeps clean builds in sync
define version=2696
@update_header

declare	
	procedure addColumn(in_schema in varchar2, in_table varchar2, in_column varchar2, in_type varchar2) 
	as
		v_exists number;
	begin
		select count(*) into v_exists from all_tab_columns
		where owner=upper(in_schema) and table_name=upper(in_table) and column_name=upper(in_column);
		if v_exists = 0 then
			dbms_output.put_line('alter table '||in_schema||'.'||in_table||' add '||in_column||' '||in_type);
			execute immediate 'alter table '||in_schema||'.'||in_table||' add '||in_column||' '||in_type;
		end if;
	end;	
begin
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'OWNER_PERMISSION', 'NUMBER(1) NOT NULL');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'ENUMERATED_COLPOS_FIELD', 'VARCHAR2(30)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'COVERABLE', 'NUMBER(1) NOT NULL');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'DEFAULT_LENGTH', 'NUMBER(10)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'DATA_DEFAULT', 'VARCHAR2(255)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'MEASURE_SID', 'NUMBER(10)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'MEASURE_CONV_COLUMN_SID', 'NUMBER(10)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'MEASURE_CONV_DATE_COLUMN_SID', 'NUMBER(10)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'AUTO_SEQUENCE', 'VARCHAR2(65)');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'SHOW_IN_FILTER', 'NUMBER(1) NOT NULL');
	addColumn('CSRIMP', 'CMS_TAB_COLUMN', 'INCLUDE_IN_SEARCH', 'NUMBER(1) NOT NULL');
end;
/

grant select, insert, update on cms.tab_column to csrimp;

@..\..\..\aspen2\cms\db\tab_body
@..\csrimp\imp_body
@..\stored_calc_datasource_body
@..\batch_job_body

@update_tail
