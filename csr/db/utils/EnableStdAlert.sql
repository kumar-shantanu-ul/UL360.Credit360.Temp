-- Allow script to be re-run to add in additional languages
SET SERVEROUTPUT ON;

PROMPT Enter the host and the id of the alert (std_alert) to enable.
DECLARE
	v_host		 				VARCHAR2(32767);
	v_std_alert_type_id			NUMBER;

	v_alert_frame_id 			NUMBER;
	v_customer_alert_type_id	NUMBER;
BEGIN

	v_host:='&&1';
	v_std_alert_type_id:=&&2;

	security.user_pkg.logonadmin(v_host);

	BEGIN
		INSERT INTO csr.customer_alert_type
			(customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(csr.customer_alert_type_id_seq.nextval, v_std_alert_type_id)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			--raise_application_error(-20001, 'The alert is already enabled.');
			dbms_output.put_line('The alert is already enabled.');
			SELECT customer_alert_type_id INTO v_customer_alert_type_id
			  FROM csr.customer_alert_type
			 WHERE std_alert_type_id = v_std_alert_type_id;
	END;

	SELECT min(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM csr.alert_frame
	 WHERE name = 'Default';
	
	IF v_alert_frame_id IS NULL THEN
		SELECT min(alert_frame_id)
		  INTO v_alert_frame_id
		  FROM csr.alert_frame;
	END IF;

	IF v_alert_frame_id IS NULL THEN
		dbms_output.put_line('Inserting default alert frame.');
		v_alert_frame_id:=1;
		INSERT INTO csr.alert_frame (alert_frame_id, name) VALUES (v_alert_frame_id, 'Default');
	END IF;

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
					AND dt.std_alert_type_id = v_std_alert_type_id
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
