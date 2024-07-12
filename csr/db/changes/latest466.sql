-- Please update version.sql too -- this keeps clean builds in sync
define version=466
@update_header

alter table customer modify aggregation_engine_version default 3;

@../csr_data_body

@update_tail
