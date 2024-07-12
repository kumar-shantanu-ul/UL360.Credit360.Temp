-- Please update version.sql too -- this keeps clean builds in sync
define version=732
@update_header

DECLARE
	v_alert_frame_id number;
BEGIN
	INSERT INTO csr.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (30, 'Delegation state changed',
		'The state of a sheet changes (by submitting, approving or rejecting). Notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
		'The user who changed the state.'
	);  
	-- Delegation state changed
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user who changed the delegation state', 6);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'FROM_NAME', 'From name', 'The name of the user who changed the delegation state', 7);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (30, 1, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);

	select min(default_alert_frame_id)
	  into v_alert_frame_id
	  from csr.default_alert_frame;
	  
	INSERT INTO csr.default_alert_template (alert_type_id, default_alert_frame_id, send_type) VALUES (30, v_alert_frame_id, 'manual');	
	INSERT INTO csr.default_alert_template_body (alert_type_id, lang, subject, body_html, item_html) VALUES (30, 'en-gb',
		'<template>Data you are involved with has changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
		'<mergefield name="ITEMS"/>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template><p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p></template>');
END;
/

@../csr_data_pkg
@../delegation_pkg
@../delegation_body
@../sheet_body

@update_tail
