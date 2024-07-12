-- Please update version.sql too -- this keeps clean builds in sync
define version=958
@update_header

--add override capability on std alert types to ignore user specific 'dont send' setting
alter table csr.std_alert_type add override_user_send_setting number (1, 0) default 0 not null;

--set all to zero by default just in case (although col has zero default)
update csr.std_alert_type set override_user_send_setting = 0;

--set password resets to 1 so we always send them.
update csr.std_alert_type set override_user_send_setting = 1 where description = 'Password reset';

--recompile alert package which has a new procedure
@../alert_pkg
@../alert_body

@update_tail