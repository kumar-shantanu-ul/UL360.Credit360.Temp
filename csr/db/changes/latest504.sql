-- Please update version.sql too -- this keeps clean builds in sync
define version=504
@update_header

UPDATE csr_user
   SET send_alerts = 0
 WHERE csr_user_sid IN (
	SELECT trash_sid FROM trash
 );
 
 
@update_tail
