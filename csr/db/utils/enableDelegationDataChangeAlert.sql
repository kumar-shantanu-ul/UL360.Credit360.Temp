-- See also EnableStdAlert.sql
-- Allow script to be re-run to add in additional languages
SET SERVEROUTPUT ON;

prompt enter the host
DECLARE
	v_alert_frame_id 			number;
	v_customer_alert_type_id	number;
BEGIN
	user_pkg.logonadmin('&&1');

	BEGIN
		INSERT INTO csr.customer_alert_type
			(customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(csr.customer_alert_type_id_seq.nextval, 39)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			--raise_application_error(-20001, 'The delegation data change alert is already enabled.');
			dbms_output.put_line('The delegation data change alert is already enabled.');
			SELECT customer_alert_type_id INTO v_customer_alert_type_id
			  FROM csr.customer_alert_type
			 WHERE std_alert_type_id = 39;
	END;

	BEGIN
		SELECT min(alert_frame_id)
		  INTO v_alert_frame_id
		  FROM csr.alert_frame
		 WHERE name = 'Default';
	EXCEPTION
		WHEN no_data_found THEN
			BEGIN
				SELECT min(alert_frame_id)
				  INTO v_alert_frame_id
				  FROM csr.alert_frame;
			EXCEPTION
				 WHEN no_data_found THEN
					raise_application_error(-20001, 'No alert frames found for the application with sid '||sys_context('security','app'));
			END;
	END;


	BEGIN
		INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type) VALUES (v_customer_alert_type_id, v_alert_frame_id, 'manual');
	EXCEPTION
		WHEN dup_val_on_index THEN
			dbms_output.put_line('Customer Alert Template already created.');
	END;

	dbms_output.put_line('Add templates for each lang on site');
	INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
	SELECT v_customer_alert_type_id, ts.lang, dt.subject, dt.body_html, dt.item_html
	  FROM csr.default_alert_template_body dt
	  JOIN aspen2.translation_set ts 
					 ON ts.lang = dt.lang
					AND dt.std_alert_type_id = 39
	  LEFT JOIN csr.alert_template_body atb
					 ON atb.lang = dt.lang 
					AND atb.customer_alert_type_id = v_customer_alert_type_id
					AND atb.app_sid = ts.application_sid
	 WHERE ts.application_sid = security_pkg.getapp
	   AND ts.hidden = 0
	   AND atb.body_html IS NULL;

END;
/

COMMIT;

SET SERVEROUTPUT OFF;

EXIT
