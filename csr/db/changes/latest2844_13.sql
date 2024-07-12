-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE chain.customer_options ADD INVITATION_EXPIRATION_REM_DAYS NUMBER(10) DEFAULT 5 NOT NULL;
ALTER TABLE chain.customer_options ADD INVITATION_EXPIRATION_REM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.invitation ADD REMINDER_SENT NUMBER(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (5029,
		'Chain invitation expiration reminder',
		'A chain invitation is about to expire.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		8
	);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE csr.std_alert_type SET
			description = 'Chain invitation expiration reminder',
			send_trigger = 'A chain invitation is about to expire.',
			sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		WHERE std_alert_type_id = 5029;
END;
/	

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
VALUES (5029, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5029, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);		

-- ** New package grants **

-- *** Packages ***

@../chain/invitation_pkg
@../chain/invitation_body

@../chain/setup_body

@update_tail
