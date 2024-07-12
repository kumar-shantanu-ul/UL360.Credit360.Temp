-- Please update version.sql too -- this keeps clean builds in sync
define version=919
@update_header

@..\csr_data_pkg

DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (38, 'User cover started message',
		'A period of user cover starts.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	-- user cover started
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (38, 0, 'USER_BEING_COVERED_NAME', 'User being covered name', 'The full name of the person who is now being covered', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (38, 0, 'USER_GIVING_COVER_NAME', 'User giving cover name', 'The full name of the person who is now giving cover (the recipient)', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (38, 0, 'COVER_DURATION', 'Cover duration', 'A description of how long the cover lasts', 3);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (38, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (38, 'en-gb',
		'<template>You have been asked to provide cover for another user in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because you have been asked to provide cover for another user while they are away.</p>'||
		'<p>Cover requested for <mergefield name="USER_BEING_COVERED_NAME"/> <mergefield name="COVER_DURATION"/>.</p></template>',
		'<template/>');
		
	-- find all apps where there is a "new delegation" alert -> seems reasonable to add the delegation user cover alert for these		
	FOR r IN (
		SELECT DISTINCT app_sid 
		  FROM csr.customer_alert_type
	     WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_NEW_DELEGATION
	)
	LOOP
		INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			SELECT r.app_sid, csr.customer_alert_type_id_seq.nextval, std_alert_type_id
			  FROM csr.std_alert_type 
			 WHERE std_alert_type_id IN (38);		
	END LOOP;
END;
/
		
@..\csr_data_pkg


@update_tail
