-- Please update version.sql too -- this keeps clean builds in sync
define version=855
@update_header

@../meter_monitor_pkg
@../meter_monitor_body
@../meter_body

@update_tail
