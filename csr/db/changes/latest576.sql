-- Please update version.sql too -- this keeps clean builds in sync
define version=576
@update_header

alter table customer modify aggregation_engine_version default 4;

@update_tail
