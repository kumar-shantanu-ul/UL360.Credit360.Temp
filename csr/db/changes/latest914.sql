-- Please update version.sql too -- this keeps clean builds in sync
define version=914
@update_header

create index csr.ix_temp_stored_calc_path on csr.temp_stored_calc_path ( substr(calc_ind_path, -length('-2')), calc_ind_sid );

@update_tail
