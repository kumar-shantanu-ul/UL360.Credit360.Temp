-- Please update version.sql too -- this keeps clean builds in sync
define version=637
@update_header

alter table csr.temp_alert_batch_run modify prev_fire_time_gmt null;

@update_tail
