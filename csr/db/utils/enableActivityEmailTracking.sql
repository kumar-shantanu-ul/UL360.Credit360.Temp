PROMPT please enter: host, email address, password
define host = '&&1'
define mailAddr = '&&2'
define password = '&&3'

DECLARE
	v_mail_root_sid	security.security_pkg.T_SID_ID;
	v_account_sid	security.security_pkg.T_SID_ID;
	v_inbox_sid		security.security_pkg.T_SID_ID;
	v_app_sid		security.security_pkg.T_SID_ID;
	v_invalid_sid	security.security_pkg.T_SID_ID;
	v_sat_ids					security.security_pkg.T_SID_IDS; -- std_alert_type ids
	v_sat_to_cat_id_map			security.security_pkg.T_SID_IDS; -- maps std_alert_type_ids to customer_alert_type ids
	v_af_id						csr.alert_frame.alert_frame_id%TYPE;
	v_customer_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;		
BEGIN
	security.user_pkg.LogonAdmin;
	
	SELECT app_sid
	  INTO v_app_sid
	  FROM csr.customer
	 WHERE host = '&&host';
	
	mail.mail_pkg.createAccount('&&mailAddr', '&&password', NULL, v_account_sid, v_mail_root_sid);
	
	
	UPDATE chain.customer_options
	   SET activity_mail_account_sid = v_account_sid
	 WHERE app_sid = v_app_sid;
	
	-- Turn off email tracking as this confuses things
	UPDATE csr.customer
	   SET use_tracker = 0
	 WHERE app_sid = v_app_sid;
	
	SELECT inbox_sid
	  INTO v_inbox_sid
	  FROM mail.account
	 WHERE account_sid = v_account_sid;
	
	mail.mailbox_pkg.createmailbox(v_inbox_sid, 'Invalid e-mails', v_account_sid, v_invalid_sid);
	
	security.user_pkg.logonadmin('&&host');
	
	v_sat_ids(0) := 5023;
	v_sat_ids(1) := 5024;
	
	FOR i IN v_sat_ids.FIRST .. v_sat_ids.LAST
	LOOP
		-- delete anything we might have already
		/*DELETE FROM csr.alert_template_body 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.alert_template 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.customer_alert_type 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);*/
	   
		-- shove in a new row
		INSERT INTO csr.customer_alert_type 
			(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, v_sat_ids(i))
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
		
		v_sat_to_cat_id_map(v_sat_ids(i)) := v_customer_alert_type_id;

		BEGIN
			SELECT MIN(alert_frame_id)
			  INTO v_af_id
			  FROM csr.alert_frame 
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			 GROUP BY app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.alert_pkg.CreateFrame('Default', v_af_id);
		END;

		INSERT INTO csr.alert_template 
			(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');
		 
	END LOOP;
	
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
	
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5023), r.lang, 
			'<template>Activity message received</template>', 
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>An activity you are involved in has received a message via email:<br/><br/><mergefield name="MESSAGE"/></template>', 
			'<template />');
		
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5024), r.lang, 
			'<template>Your message was not delivered - <mergefield name="MESSAGE_SUBJECT"/></template>', 
			'<template><div>Dear <mergefield name="TO_NAME"/>,<br/><br/>We could not link the email you sent us to an existing activity:<br/><br/><mergefield name="MESSAGE"/></div></template>', 
			'<template />');

	END LOOP;
	
END;
/