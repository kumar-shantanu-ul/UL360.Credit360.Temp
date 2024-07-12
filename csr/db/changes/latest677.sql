-- Please update version.sql too -- this keeps clean builds in sync
define version=677
@update_header

drop table csr.region_recalc_job;

@../csr_data_body
@../calc_pkg
@../calc_body
@../region_pkg
@../region_body
@../indicator_body
@../system_status_body
@../system_status_pkg

@update_tail
