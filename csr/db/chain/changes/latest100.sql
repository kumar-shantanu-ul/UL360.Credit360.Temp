define version=100
@update_header

	BEGIN
		-- Self registration invitation
		BEGIN
			INSERT INTO csr.alert_type (alert_type_id, description, send_trigger, sent_from) VALUES (5007,
			'Chain self registration questionnaire invitation',
			'A user self registers and a chain invitation is created.',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE csr.alert_type SET
					description = 'Chain self registration questionnaire invitation',
					send_trigger = 'A user self registers and a chain invitation is created.',
					sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
				WHERE alert_type_id = 5007;
		END;
		INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5007, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
		INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5007, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
		INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5007, 0, 'LINK', 'Link', 'A hyperlink to the invitation acceptance page', 3);
		INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5007, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 4);
		INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5007, 0, 'SITE_NAME', 'Site name', 'The site name', 5);
	END;
	/
@update_tail