-- Please update version too -- this keeps clean builds in sync
define version=1858
@update_header


BEGIN
	-- Chain change of email address
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5008,
		'Chain change of email address',
		'A user changes their email address or an admin changes their email address for them.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain change of email address',
				send_trigger = 'A user changes their email address or an admin changes their email address for them.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5008;
	END;

	BEGIN
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5008, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	EXCEPTION
		WHEN dup_val_on_index THEN
				NULL;
	END;
	
	BEGIN
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5008, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5008, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
		
	BEGIN	
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5008, 0, 'NEW_EMAIL', 'New e-mail', 'The new e-mail address of the user', 4);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN		
		INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5008, 0, 'OLD_EMAIL', 'Old e-mail', 'The old e-mail address of the user', 5);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

@update_tail
