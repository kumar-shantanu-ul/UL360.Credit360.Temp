--Please update version.sql too -- this keeps clean builds in sync
define version=2611
@update_header

DECLARE
	v_customer_alert_type_id			NUMBER;
	v_deleg_state_alert_type_id			NUMBER;
	v_sheet_returned_alert_type_id		NUMBER := csr.csr_data_pkg.ALERT_SHEET_RETURNED;
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE app_sid NOT IN (
			SELECT ca.app_sid
			  FROM csr.customer_alert_type ca 
			  JOIN csr.std_alert_type sa on ca.std_alert_type_id = sa.std_alert_type_id
			 WHERE sa.std_alert_type_id = v_sheet_returned_alert_type_id
		)
	)
	LOOP
		dbms_output.put_line('App => ' || r.app_sid);
		security.security_pkg.SetApp(r.app_sid);
		BEGIN
			-- Get delegation state changed customer alert id
			SELECT customer_alert_type_id
			  INTO v_deleg_state_alert_type_id
			  FROM csr.customer_alert_type
			 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED;

			SELECT csr.customer_alert_type_id_seq.NEXTVAL
			  INTO v_customer_alert_type_id
			  FROM dual;

			dbms_output.put_line('Adding customer alert => ' || v_customer_alert_type_id);
			-- insert new customer sheet returned alert
			INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
			     VALUES (v_customer_alert_type_id, v_sheet_returned_alert_type_id);				-- For 10g variable instead of csr_data_pkg.ALERT_SHEET_RETURNED

			-- copy template from delegation state change alert template
			INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email, from_name, from_email)
				 SELECT v_customer_alert_type_id, alert_frame_id, 'manual' send_type, reply_to_name, reply_to_email, from_name, from_email
				   FROM csr.alert_template
				  WHERE customer_alert_type_id = v_deleg_state_alert_type_id
				    AND app_sid = r.app_sid;

			INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
				 SELECT v_customer_alert_type_id, lang, subject, body_html, item_html
				   FROM csr.alert_template_body
				  WHERE customer_alert_type_id = v_deleg_state_alert_type_id
				    AND app_sid = r.app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				dbms_output.put_line(r.app_sid || ' => Delegation state changed alert does not exist');
				NULL;
		END;
		security.security_pkg.SetApp(null);
	END LOOP;
END;
/

@../csr_app_body
	
@update_tail
