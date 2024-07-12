PROMPT enter the host

DECLARE
	v_alert_frame_id 			NUMBER;
	v_customer_alert_type_id	NUMBER;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	 BEGIN
		INSERT INTO csr.customer_alert_type
			(customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(customer_alert_type_id_seq.NEXTVAL, csr.csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(-20001, 'The batched delegation state change alert is already enabled');
	END;
	
	-- Delete immediate delegation state change alert
	DELETE FROM csr.alert_template_body 
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED);
	DELETE FROM csr.alert_template 
	 WHERE customer_alert_type_id = (SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED);
	DELETE FROM csr.customer_alert_type
	 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED;

	 BEGIN
		SELECT MIN(alert_frame_id)
		  INTO v_alert_frame_id
		  FROM csr.alert_frame
		 WHERE name = 'Default';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			BEGIN
				SELECT MIN(alert_frame_id)
				  INTO v_alert_frame_id
				  FROM csr.alert_frame;
			EXCEPTION
				WHEN no_data_found THEN
					RAISE_APPLICATION_ERROR(-20001, 'No alert frames found for the application with sid '||sys_context('security','app'));
			END;
	END;

	INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type) VALUES (v_customer_alert_type_id, v_alert_frame_id, 'manual');	
	INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html) VALUES (v_customer_alert_type_id, 'en',
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
EXIT;