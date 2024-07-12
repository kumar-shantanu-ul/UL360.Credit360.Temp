-- Please update version.sql too -- this keeps clean builds in sync
define version=1902
@update_header

@../meter_monitor_pkg
@../meter_monitor_body

@update_tail

