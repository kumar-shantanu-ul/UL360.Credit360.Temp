-- Please update version.sql too -- this keeps clean builds in sync
define version=1096
@update_header

@..\csr_data_pkg

ALTER TABLE DONATIONS.FUNDING_COMMITMENT ADD REMINDER_SENT_DTM DATE;
grant execute on csr.csr_data_pkg to donations;
grant execute on csr.alert_pkg to donations;
grant select on csr.temp_alert_batch_run to donations;

DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN

	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) 
		VALUES(40, 'Funding Commitment Reminder', 
			'Reminder date on Funding Commitment Setup.',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- user cover started
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (40, 0, 'FC_NAME', 'Funding Commitment name', 'The full name of Funding Commitment', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (40, 0, 'PAYMENT_DTM', 'Payment date', 'The date of payment', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (40, 0, 'FC_LINK', 'Link to Funding commitment setup page', 'This will give direct link to correct funding commitment setup.', 3);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (40, v_default_alert_frame_id, 'automatic');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (40, 'en-gb',
		'<template>You have been asked to update details of Funding Commitment</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because you have been asked to check details of Funding Commitment. Click following link to go to review page <mergefield name="FC_LINK"/>.</p>'||
		'</template>', '<template/>');
		
	-- for now only BL is going to use it
	FOR r IN (
		SELECT app_sid 
		  FROM CSR.CUSTOMER WHERE host = 'britishland.credit360.com'
	)
	LOOP
		INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			SELECT r.app_sid, csr.customer_alert_type_id_seq.nextval, std_alert_type_id
			  FROM csr.std_alert_type 
			 WHERE std_alert_type_id IN (40);		
	END LOOP;
END;
/

@../donations/funding_commitment_pkg
@../donations/funding_commitment_body

@update_tail
