-- Please update version.sql too -- this keeps clean builds in sync
define version=635
@update_header

drop table csr.temp_alert_batch_run;
CREATE GLOBAL TEMPORARY TABLE csr.temp_alert_batch_run
(
	alert_type_id					NUMBER(10) NOT NULL,
	app_sid							NUMBER(10) NOT NULL,
	csr_user_sid					NUMBER(10) NOT NULL,
	prev_fire_time_gmt				TIMESTAMP(6) NOT NULL,
	this_fire_time					TIMESTAMP(6) NOT NULL,
	this_fire_time_gmt				TIMESTAMP(6) NOT NULL
) ON COMMIT PRESERVE ROWS;
grant select,insert,update,delete on csr.temp_alert_batch_run to actions;

@../alert_body
@../sheet_body
@../pending_body
@../issue_body

@update_tail
