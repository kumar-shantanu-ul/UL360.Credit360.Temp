-- Please update version.sql too -- this keeps clean builds in sync
define version=606
@update_header

create global temporary table csr.temp_stored_calc_path
(
	calc_ind_sid					number(10) not null,
	calc_ind_path					varchar2(4000) not null
) on commit delete rows;

@../stored_calc_datasource_body

@update_tail

