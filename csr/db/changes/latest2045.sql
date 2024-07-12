-- Please update version.sql too -- this keeps clean builds in sync
define version=2045
@update_header

grant select,insert on csr.meter_reading to csrimp;
grant select,insert on csr.meter_reading_period to csrimp;

@update_tail
