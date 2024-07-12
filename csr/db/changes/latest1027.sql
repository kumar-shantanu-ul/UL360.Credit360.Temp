-- Please update version.sql too -- this keeps clean builds in sync
define version=1027
@update_header

drop table csr.temp_stored_calc_path;

update cms.col_type set description='Calculation' where col_type=25;

@../stored_calc_datasource_body

@update_tail
