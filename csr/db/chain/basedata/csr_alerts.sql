PROMPT >> Setting csr alerts basedata
DECLARE
	v_std_alert_type_group_id	NUMBER(10) := 8;
	v_alert_id	NUMBER := 0;
BEGIN
	-- Can't delete from 5005 as alert_partial_template_param references these
	DELETE FROM csr.std_alert_type_param WHERE std_alert_type_id IN (5000, 5002, 5003, 5004, 5006, 5007, 5008, 5009, 5010, 5011, 5014, 2012, 5022, 5023, 5024, 5025, 5026, 5027, 5028, 5029, 5030);
	DELETE FROM csr.customer_alert_type WHERE std_alert_type_id IN (5004, 5006, 5011, 5012, 5026, 5027, 5028, 5029, 5030);
	DELETE FROM csr.std_alert_type WHERE std_alert_type_id IN (5004, 5006, 5011, 5014, 5012, 5015, 5016, 5017, 5026, 5027, 5028, 5029, 5030);
	
	-- Chain invitation
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5000,
			'Chain invitation',
			'A chain invitation is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain invitation',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5000;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5000, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);

	-- Stub invitation
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5002,
			'Chain stub invitation',
			'A chain invitation is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain stub invitation',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5002;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5002, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5002, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5002, 0, 'LINK', 'Link', 'A hyperlink to the invitationi acceptance page', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5002, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5002, 0, 'SITE_NAME', 'Site name', 'The site name', 5);

	-- Scheduled alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5003,
			'Chain scheduled alerts',
			'A scheduled alert run takes place.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain scheduled alerts',
				send_trigger = 'A scheduled alert run takes place.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5003;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'SITE_NAME', 'Site name', 'The site name', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'ALERT_ENTRY_TYPE_DESCRIPTION', 'Alert Type Description', 'A description of the type of alert this is.', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'CONTENT', 'Content', 'The scheduled alert configured content.', 5);
	
	-- Chain invitation body
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5005,
			'Chain invitation body',
			'A chain invitation is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain invitation body',
				send_trigger = 'A chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5005;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'HEADER', 'Greeting', 'The default or personalised greeting', 15);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
			VALUES (5005, 0, 'FOOTER', 'Signature', 'The default or personalised signature', 16);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- Self registration invitation
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5007,
			'Chain self registration questionnaire invitation',
			'A user self registers and a chain invitation is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain self registration questionnaire invitation',
				send_trigger = 'A user self registers and a chain invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5007;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5007, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5007, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5007, 0, 'LINK', 'Link', 'A hyperlink to the invitation acceptance page', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5007, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5007, 0, 'SITE_NAME', 'Site name', 'The site name', 5);
	
	-- Chain change of email address
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5008,
			'Chain change of email address',
			'A user changes their email address or an admin changes their email address for them.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain change of email address',
				send_trigger = 'A user changes their email address or an admin changes their email address for them.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5008;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5008, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5008, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5008, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5008, 0, 'NEW_EMAIL', 'New e-mail', 'The new e-mail address of the user', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5008, 0, 'OLD_EMAIL', 'Old e-mail', 'The old e-mail address of the user', 5);
	
	
	-- Chain questionnaire invitation
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5010,
			'Chain questionnaire invitation',
			'A chain invitation to an existing user is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain questionnaire invitation',
				send_trigger = 'A chain invitation to an existing user is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5010;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5010, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 15);

	-- Chain pending user accepted
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5011,
			'Accept pending chain user',
			'A message is sent to a user who has been accepted to join a company by one of the company''s administrators.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Accept pending chain user',
				send_trigger = 'A message is sent to a user who has been accepted join a company by one of the company''s administrators.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5011;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5011, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5011, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5011, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5011, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 4);
		
	-- Chain pending user rejected
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5012,
			'Reject pending chain user',
			'A message is sent to a user who has been rejected from joining a company by one of the company''s administrators.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Reject pending chain user',
				send_trigger = 'A message is sent to a user who has been rejected from joining a company by one of the company''s administrators.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5012;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5012, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5012, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5012, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5012, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 4);
	
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5013,
			'Self-Assessment Questionnaire',
			'A self-assessment questionnaire is sent to a supplier.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Self-Assessment Questionnaire',
				send_trigger = 'A self-assessment questionnaire is sent to a supplier.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5013;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5013, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	
	
	/* Chain company invitation */
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5014,
			'Chain company invitation',
			'A chain company invitation (without requiring a questionnaire) is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain company invitation',
				send_trigger = 'A chain company invitation (without requiring a questionnaire) is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5014;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'LINK', 'Link', 'A hyperlink to the invitation landing page', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);
		
		--Chain supplier survey alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5015,
			'Chain supplier survey',
			'A supplier survey has been shared with supplier after the supplier submits the on-board questionnaire.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain supplier survey',
				send_trigger = 'A supplier survey has been shared with supplier.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5015;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'LINK', 'Link', 'A hyperlink to the supplier survey page', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'EXPIRATION', 'Expiration', 'The date the supplier survey expires', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'SITE_NAME', 'Site name', 'The site name', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'SECONDARY_COMPANY', 'Secondary company', 'Placeholder for a secondary reference company', 12);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'SURVEY_NAME', 'Survey name', 'Survey name', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5015, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 14);		
		
	-- Chain questionnaire reminder
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5016,
			'Questionnaire reminder',
			'A questionnaire is not shared (not submitted) and it is past the reminder date.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire reminder',
				send_trigger = 'A questionnaire is not shared (not submitted) and it is past the reminder date.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5016;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire edit link', 'A hyperlink to the questionnaire edit page', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5016, 0, 'DUE_DATE', 'Expiration', 'The due date of the questionnaire', 7);
		
		
	-- Chain questionnaire overdue alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5017,
			'Questionnaire overdue',
			'A questionnaire is not shared (not submitted) and it is past the due date.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id);
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire overdue',
				send_trigger = 'A questionnaire is not shared (not submitted) and it is past the due date.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5017;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire edit link', 'A hyperlink to the questionnaire edit page', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5017, 0, 'DUE_DATE', 'Expiration', 'The due date of the questionnaire', 7);
		
		
	/* Chain request Questionnaire Invitation */	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5018,
			'Request Questionnaire Invitation',
			'An existing company questionnaire request invitation has been created',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Request Questionnaire Invitation',
				send_trigger = 'An existing company questionnaire request invitation has been created',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5018;
	END;

	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'QNNAIRE_REQUEST_LINK', 'Link', 'A hyperlink to the questionnaire request invitation landing page', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5018, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);
		
	/* Chain Create User*/	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5019,
			'Chain Create User',
			'A user has been created from the company details, create user tab.',
			'The user that created the new user.',
			v_std_alert_type_group_id
		);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE csr.std_alert_type SET
					description = 'Chain Create User',
					send_trigger = 'A user has been created from the company details, create user tab.',
					sent_from = 'The user that created the new user.'
				WHERE std_alert_type_id = 5019;
	END;

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5019, 0, 'COMPANY_NAME', 'Company name', 'The name of the company the created user belongs to', 9);
	
	/* Chain Audit Requst */
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5020,
			'Chain Audit Request',
			'An audit has been requested.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE csr.std_alert_type SET
					description = 'Chain Audit Requst',
					send_trigger = 'An audit has been requested.',
					sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
				WHERE std_alert_type_id = 5020;
	END;
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'AUDITOR_COMPANY_NAME', 'Auditor company name', 'The name of the auditor company', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'AUDITEE_COMPANY_NAME', 'Auditee company name', 'The name of the auditee company', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'REQUESTED_BY_COMPANY_NAME', 'Requested by company name', 'The name of the company requesting the audit', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'REQUESTED_BY_USER_NAME', 'Requested by user name', 'The name of the user requesting the audit', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'REQUESTED_BY_USER_FRIENDLY_NAME', 'Requested by user friendly name', 'The friendly name of the user requesting the audit', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'REQUESTED_BY_USER_EMAIL', 'Requested by user email', 'The email of the user requesting the audit', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5020, 0, 'AUDIT_REQUEST_LINK', 'Audit request link', 'A hyperlink to the audit request', 10);

	-- Chain supplier review
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5021,
			'Chain supplier review',
			'Sent on a scheduled basis for suppliers to review their data.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain supplier review',
				send_trigger = 'Sent on a scheduled basis for suppliers to review their data.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5021;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5021, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);

	-- Chain activity message
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5022,
			'Chain activity message',
			'Sent when a user adds a log entry message to a chain activity.',
			'The user who added the message.',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain activity message',
				send_trigger = 'Sent when a user adds a log entry message to a chain activity.',
				sent_from = 'The user who added the message.'
			WHERE std_alert_type_id = 5022;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'MESSAGE', 'Message', 'The message that has been added to the activity log', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 9);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 10);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 11);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 12);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 13);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 14);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 15);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'LOCATION', 'Location', 'The Location of the activity', 16);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'STATUS', 'Status', 'The status of the activity', 17);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TAGS', 'Tags', 'The tags of the activity', 18);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 19);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5022, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 20);
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5023,
			'Activity email received',
			'Sent when an email relating to an activity has been received.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Activity email received',
				send_trigger = 'Sent when an email relating to an activity has been received.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5023;
	END;
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 9);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 10);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 11);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 12);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'LOCATION', 'Location', 'The Location of the activity', 13);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'STATUS', 'Status', 'The status of the activity', 14);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TAGS', 'Tags', 'The tags of the activity', 15);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 16);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 17);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'MESSAGE', 'Message', 'The email contents received', 18);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5023, 0, 'MESSAGE_SUBJECT', 'Message subject', 'The subject of the email received', 19);

	
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5024,
			'Activity email error',
			'Sent when an email has been received to the activity inbox, but cannot be matched to an activity.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Activity email error',
				send_trigger = 'Sent when an email has been received to the activity inbox, but cannot be matched to an activity.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5024;
	END;
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5024, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5024, 0, 'TO_NAME', 'To name', 'The name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5024, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5024, 0, 'MESSAGE', 'Message', 'The email contents received', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5024, 0, 'MESSAGE_SUBJECT', 'Message subject', 'The subject of the email received', 5);
	
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5025,
			'Questionnaire Expired',
			'Sent to all supplier users when a questionnaire has expired and needs to be resent.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire Expired',
				send_trigger = 'Sent to all supplier users when a questionnaire has expired and needs to be resent.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5025;
	END;
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_NAME', 'To name', 'The name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_COMPANY', 'To company', 'The name of the company filling out the questionnaire', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'FROM_COMPANY', 'From company', 'The name of the company the questionnaire is for', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire that has expired', 7);

	
	-- Chain product invitation
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5026,
			'Chain product invitation',
			'A chain product invitation is created.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain product invitation',
				send_trigger = 'A chain product invitation is created.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5026;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 15);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5026, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 12);
	
	-- returned questionnaire notification
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5027,
		'Returned questionnaire notification',
		'A questionnaire is returned.',
		'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
		v_std_alert_type_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Returned questionnaire notification',
				send_trigger = 'A questionnaire is returned.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5027;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'SUBJECT', 'Subject', 'The subject', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'QUESTIONNAIRE_LINK', 'Questionnaire link', 'A hyperlink to the questionnaire', 12);	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'USER_NOTES', 'Transition comments', 'Notes added by the user that returned the questionnaire', 13);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5027, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 14);
	
	
	-- Questionnaire user added
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5028,
		'Questionnaire user added',
		'A new user added to a questionnaire.',
		'The user who changed the permission.',
		v_std_alert_type_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire user added',
				send_trigger = 'A new user added to a questionnaire.',
				sent_from = 'The user who changed the permission.'
			WHERE std_alert_type_id = 5028;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5028, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 10);
	
	-- Chain invitation expiration reminder
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5029,
			'Chain invitation expiration reminder',
			'A chain invitation is about to expire.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain invitation expiration reminder',
				send_trigger = 'A chain invitation is about to expire.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5029;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5029, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 11);

	-- Supplier Company associated with Product alert
	v_alert_id := 5030;
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (v_alert_id,
			'Supplier Company associated with Product alert',
			'Sent on a scheduled basis for suppliers to review their data.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			v_std_alert_type_group_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Supplier Company associated with Product alert',
				send_trigger = 'Sent on a scheduled basis for suppliers to review their data.',
				sent_from = 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = v_alert_id;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PRODUCT_ID', 'Product Id', 'The product id the alert is being sent for', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PRODUCT_NAME', 'Product Name', 'The product the alert is being sent for', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PURCHASER_COMPANY_NAME', 'Purchaser Company', 'The company to which the product is supplied to', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PURCHASER_COMPANY_SID', 'Purchaser Company Sid', 'The purchasing company sid with which the product has been associated to', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'SUPPLIER_COMPANY_NAME', 'Supplier Company', 'The company from which the product is supplied', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'SUPPLIER_COMPANY_SID', 'Supplier Company Sid', 'The supplier company sid with which the product has been associated to', 9);

	-- Company onboarding request
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
		VALUES (5031, 'Company relationship request approved',
					  'A new relationship created to a supplier.',
					  'The company who accepted the relationship.',
				v_std_alert_type_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type
			   SET description = 'Company relationship request approved',
				   send_trigger = 'A new relationship created to a supplier.',
				   sent_from = 'The company who accepted the relationship.'
			 WHERE std_alert_type_id = 5031;
	END;

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'REQUESTED_COMPANY', 'Relationship requested to', 'The company the relationship was requested to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'REQUESTING_COMPANY', 'Relationship requested by', 'The company the relationship is requested by', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'COMPANY_URL', 'Link to company', 'Link to the company that was created or matched', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5031, 0, 'FROM_EMAIL', 'From email', 'Address the alert was sent from', 8);


	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
		VALUES (5032, 'Company onboarding request refused',
					  'A new company request refused.',
					  'The company who denied the new supplier request.',
				v_std_alert_type_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type
			   SET description = 'Company onboarding request refused',
				   send_trigger = 'A new company request refused.',
				   sent_from = 'The company who denied the new supplier request.'
			 WHERE std_alert_type_id = 5032;
	END;

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'REQUESTED_COMPANY', 'Relationship requested to', 'The company the relationship was requested to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'REQUESTING_COMPANY', 'Relationship requested by', 'The company the relationship is requested by', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5032, 0, 'FROM_EMAIL', 'From email', 'Address the alert was sent from', 7);
END;
/

