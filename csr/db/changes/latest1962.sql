-- Please update version.sql too -- this keeps clean builds in sync
define version=1962
@update_header

alter table csr.meter_source_type add (is_calculated_sub_meter number(1) default 0 not null);

@..\meter_pkg
@..\meter_body

@update_tail