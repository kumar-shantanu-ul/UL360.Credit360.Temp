-- Please update version.sql too -- this keeps clean builds in sync
define version=1767
@update_header

@../meter_monitor_body
	
@update_tail