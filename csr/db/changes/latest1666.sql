-- Please update version.sql too -- this keeps clean builds in sync
define version=1666
@update_header

DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (50, 'Sheet automatically approved notification',
		'A sheet is automatically approved.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	-- user cover started
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (50, 0, 'SHEET_NAME', 'Sheet name', 'The name of the sheet that has been approved.', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (50, 0, 'EDITING_URL', 'Sheet editing URL', 'The editing URL of the sheet that has been approved.', 2);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (50, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (50, 'en',
		'<template>A sheet has been automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your sheets has been automatically approved for you.</p>'||
		'<p>The sheet <mergefield name="SHEET_NAME"/> has been approved. You can view the sheet here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');
	
	
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (51, 'Sheet not automatically approved notification',
		'A sheet could not be automatically approved due to intolerances.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (51, 0, 'SHEET_NAME', 'Sheet name', 'The name of the sheet that has been approved.', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (51, 0, 'EDITING_URL', 'Sheet editing URL', 'The URL of the sheet that has been approved.', 2);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (51, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (51, 'en',
		'<template>A sheet could not be automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your sheets could not be automatically approved due to intolerances.</p>'||
		'<p>The sheet <mergefield name="SHEET_NAME"/> has intolerances. You can view the sheet here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');	
END;
/

@..\auto_approve_body

--Fix (mostly) for csrimp
UPDATE csr.sheet_value set set_by_user_sid = 3 WHERE (app_sid, set_by_user_sid ) NOT IN (SELECT app_sid, csr_user_sid FROM csr.csr_user);

AlTER TABLE csr.sheet_value ADD CONSTRAINT FK_SHEET_VAL_SET_BY_CSR_USER 
    FOREIGN KEY (APP_SID, SET_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

@update_tail
