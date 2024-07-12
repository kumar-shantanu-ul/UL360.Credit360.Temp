-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2411
@update_header

alter table csr.customer add max_concurrent_calc_jobs number(10);

@../stored_calc_datasource_body

@update_tail
