-- Please update version.sql too -- this keeps clean builds in sync
define version=433
@update_header

drop table target;
@../indicator_pkg
@../indicator_body
@../range_pkg
@../range_body
@../region_body
@../csr_data_body

@update_tail
