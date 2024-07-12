-- Please update version.sql too -- this keeps clean builds in sync
define version=1061
@update_header

alter table csr.customer modify calc_job_priority default 1;
update csr.customer set calc_job_priority = 1 where calc_job_priority = 0;

@../stored_calc_datasource_body

@update_tail
