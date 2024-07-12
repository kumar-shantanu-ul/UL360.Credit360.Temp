-- Please update version.sql too -- this keeps clean builds in sync
define version=922
@update_header

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (39, 'Delegation data changed by other user.',
	'User other than delegee(s) edit a value on a delegation form.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);

-- Add template for new alert type
DECLARE
	v_default_alert_frame_id	number(10);
BEGIN
	SELECT default_alert_frame_id
	  INTO v_default_alert_frame_id
	  FROM	CSR.default_alert_frame
	 WHERE name = 'Default';

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (39, v_default_alert_frame_id, 'manual');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (39, 'en-gb',
		'<template>Data you are entering has been changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because data you are entering for this year'||CHR(38)||'apos;s CSR report has been changed.</p>'||
		'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has changed values in data you submitted for '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template/>');
		
END;
/

@../csr_data_pkg
@../sheet_pkg
@../sheet_body
@../delegation_pkg
@../delegation_body

@update_tail
