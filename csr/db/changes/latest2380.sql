-- Please update version.sql too -- this keeps clean builds in sync
define version=2380
@update_header

UPDATE csr.std_alert_type
   SET send_trigger = 'There are comments made on issues you are involved in, but which you have not read. This is sent daily.'
 WHERE std_alert_type_id = 18;

@update_tail
