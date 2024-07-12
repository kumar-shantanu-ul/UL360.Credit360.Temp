-- Please update version.sql too -- this keeps clean builds in sync
define version=2209
@update_header

/* Chain supplier survey: 5015 */
BEGIN
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 14);
EXCEPTION 
	WHEN dup_val_on_index THEN 
		NULL;
END;
/

@update_tail
