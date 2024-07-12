define version=76
@update_header

BEGIN
	
	-- Chain invitation header
	BEGIN
		INSERT INTO csr.alert_type (alert_type_id, description, send_trigger, sent_from) VALUES (5004,
		'Chain invitation header',
		'A chain invitation is created.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.alert_type SET
				description = 'Chain invitation header',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE alert_type_id = 5004;
	END;
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5004, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5004, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5004, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5004, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	
	-- Chain invitation body
	BEGIN
		INSERT INTO csr.alert_type (alert_type_id, description, send_trigger, sent_from) VALUES (5005,
		'Chain invitation body',
		'A chain invitation is created.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.alert_type SET
				description = 'Chain invitation body',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE alert_type_id = 5005;
	END;
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'QUESTIONNAIRE_DESCRIPTION', 'Questionnaire description', 'The questionnaire description', 12);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5005, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);
	
	-- Chain invitation footer
	BEGIN
		INSERT INTO csr.alert_type (alert_type_id, description, send_trigger, sent_from) VALUES (5006,
		'Chain invitation footer',
		'A chain invitation is created.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.alert_type SET
				description = 'Chain invitation footer',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE alert_type_id = 5006;
	END;
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 4);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 5);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5006, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 9);
	
END;
/


@update_tail