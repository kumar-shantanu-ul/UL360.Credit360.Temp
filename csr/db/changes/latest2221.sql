-- Please update version.sql too -- this keeps clean builds in sync
define version=2221
@update_header

declare
	v_default_alert_frame_id	csr.default_alert_frame.default_alert_frame_id%TYPE;
begin
	begin
		INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (62, 'Delegation edited', 
			'Sent when an approver approves a sheet which they have edited first.',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		);
	exception
		when dup_val_on_index then
			null;
	end;
	
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'FROM_NAME', 'From name', 'The full name of the user raising the alert', 1);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'FROM_EMAIL', 'From email', 'The email of the user raising the alert', 2);
	exception
		when dup_val_on_index then
			null;
	end;
	begin		
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delgation involved', 3);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'SHEET_LINK', 'Sheet URL', 'Link to the sheet', 4);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 5);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 6);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 7);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (62, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 8);
	exception
		when dup_val_on_index then
			null;
	end;

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.DEFAULT_ALERT_FRAME;
	begin	
		INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
			(std_alert_type_id, default_alert_frame_id, send_type) 
		VALUES 
			(62, v_default_alert_frame_id, 'manual');		
	exception
		when dup_val_on_index then
			null;
	end;
	begin
	
		INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (62, 'en',
			'<template>A delegation you are involved with has been edited in CRedit360</template>',
			'<template>
			<p>Hello,</p>
			<p>You are receiving this email because a delegation you are involved in has been edited before approval.</p>
			<p><mergefield name="FROM_NAME" /> (<mergefield name="FROM_EMAIL" />) has edited the delegation <mergefield name="DELEGATION_NAME" />.</p>
			<p>To view the changes, please go to this web page:</p>
			<p><mergefield name="SHEET_URL" /></p>
			<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
			</template>',
			'<template/>'
			);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

@update_tail
