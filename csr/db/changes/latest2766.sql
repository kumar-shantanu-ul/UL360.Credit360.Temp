-- Please update version.sql too -- this keeps clean builds in sync
define version=2766
define minor_version=0
define is_combined=1
@update_header

BEGIN
	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = 8 /*ALERT_GROUP_SUPPLYCHAIN */
	 WHERE std_alert_type_id IN (5027, 5028);
END;
/

@update_tail
