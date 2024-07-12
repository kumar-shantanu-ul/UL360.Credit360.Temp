-- Please update version.sql too -- this keeps clean builds in sync
define version=2185
@update_header

/* Chain questionnaire invitation: 5010 */
BEGIN
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5010, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 16);
EXCEPTION 
	WHEN dup_val_on_index THEN 
		NULL;
END;
/

/* Chain invitation: 5000 */
BEGIN
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5000, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 15);
EXCEPTION 
	WHEN dup_val_on_index THEN 
		NULL;
END;
/

@update_tail
