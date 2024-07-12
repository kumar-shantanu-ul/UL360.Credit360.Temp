-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_request_action ADD SENT_DTM DATE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data


INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
VALUES (5031, 'Company relationship request approved',
		'A new relationship created to a supplier.',
		'The company who accepted the relationship.',
		8);

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


INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
VALUES (5032, 'Company onboarding request refused',
		'A new company request refused.',
		'The company who denied the new supplier request.',
		8);

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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_pkg

@../chain/company_body
@../chain/setup_body

@update_tail
