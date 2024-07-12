-- Please update version.sql too -- this keeps clean builds in sync
define version=1664
@update_header

alter table csr.customer add failed_calc_job_retry_delay number(10) default 10 not null;

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
