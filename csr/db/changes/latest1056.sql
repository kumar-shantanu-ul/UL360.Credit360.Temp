-- Please update version.sql too -- this keeps clean builds in sync
define version=1056
@update_header

alter table csr.customer add calc_priority number(10) default 0 not null;
@../stored_calc_datasource_body

@update_tail
