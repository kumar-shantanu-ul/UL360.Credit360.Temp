-- Please update version.sql too -- this keeps clean builds in sync
define version=2514
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='METER_RAW_DATA' and column_name='START_DTM' and nullable='N') loop
		execute immediate 'ALTER TABLE csr.meter_raw_data modify start_dtm null';
	end loop;
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='METER_RAW_DATA' and column_name='END_DTM' and nullable='N') loop
		execute immediate 'ALTER TABLE csr.meter_raw_data modify end_dtm null';
	end loop;
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='METER_RAW_DATA' and column_name='START_DTM' and nullable='N') loop
		execute immediate 'ALTER TABLE csrimp.meter_raw_data modify start_dtm null';
	end loop;
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='METER_RAW_DATA' and column_name='END_DTM' and nullable='N') loop
		execute immediate 'ALTER TABLE csrimp.meter_raw_data modify end_dtm null';
	end loop;
end;
/

@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
