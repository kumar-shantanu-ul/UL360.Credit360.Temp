-- Please update version.sql too -- this keeps clean builds in sync
define version=746
@update_header

INSERT INTO csr.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (31, 'Survey email',
	'A survey email is manually triggered.',
	'The user who triggers the survey release.'
);  



-- Survey email
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 1);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user who changed the delegation state', 2);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'FROM_NAME', 'From name', 'The name of the user who changed the delegation state', 3);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'SURVEY_URL', 'Survey link', 'A hyperlink to the survey', 4);

@update_tail
