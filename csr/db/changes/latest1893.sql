-- Please update version.sql too -- this keeps clean builds in sync
define version=1893
@update_header

@../region_body
@../meter_body
@../meter_monitor_body
 
@update_tail