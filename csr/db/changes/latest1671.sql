-- Please update version.sql too -- this keeps clean builds in sync
define version=1671
@update_header
	
	UPDATE CSR.STD_ALERT_TYPE SET Description = 'Form automatically approved notification', SEND_trigger = 'A form is automatically approved.' where std_alert_type_id = 50;

	UPDATE csr.std_alert_type_param set description = 'Form name', help_text = 'The name of the form that has been approved.' where std_alert_type_id = 50 and field_name = 'SHEET_NAME';

	UPDATE csr.std_alert_type_param set description = 'Form editing URL', help_text = 'The editing URL of the form that has been approved.' where std_alert_type_id = 50  and field_name = 'EDITING_URL';

	UPDATE CSR.default_alert_template_body set subject = '<template>A form has been automatically approved</template>', body_html = '<template><p>Hello,</p>'||
		'<p>This is a notification that one of your forms has been automatically approved for you.</p>'||
		'<p>The form <mergefield name="SHEET_NAME"/> has been approved. You can view the form here: <mergefield name="EDITING_URL"/>.</p></template>' where std_alert_type_id = 50;

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (50, 'en-gb',
		'<template>A form has been automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your forms has been automatically approved for you.</p>'||
		'<p>The form <mergefield name="SHEET_NAME"/> has been approved. You can view the form here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');


	UPDATE CSR.STD_ALERT_TYPE SET Description = 'Form not automatically approved notification', SEND_trigger = 'A form could not be automatically approved due to values changing significantly.' where std_alert_type_id = 51;

	UPDATE csr.std_alert_type_param set description = 'Form name', help_text = 'The name of the form that could not be approved.' where std_alert_type_id = 51 and field_name = 'SHEET_NAME';

	UPDATE csr.std_alert_type_param set description = 'Form editing URL', help_text = 'The editing URL of the form that could not be approved.' where std_alert_type_id = 51 and field_name = 'EDITING_URL';

	UPDATE CSR.default_alert_template_body set subject = '<template>A form could not be automatically approved</template>', body_html = '<template><p>Hello,</p>'||
		'<p>This is a notification that one of your forms could not be automatically approved due to values changing significantly.</p>'||
		'<p>The form <mergefield name="SHEET_NAME"/> could not be automatically approved. You can view the form here: <mergefield name="EDITING_URL"/>.</p></template>' where std_alert_type_id = 51;


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (51, 'en-gb',
		'<template>A form could not be automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your forms could not be automatically approved due to values changing significantly.</p>'||
		'<p>The form <mergefield name="SHEET_NAME"/> could not be automatically approved. You can view the form here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');	

@update_tail
