-- Allow script to be re-run to add in additional languages
SET SERVEROUTPUT ON;

PROMPT enter the host
DECLARE
	PROCEDURE EnableAlert(
		in_alert_id 			IN NUMBER
	)
	AS
		v_alert_frame_id			NUMBER;
		v_customer_alert_type_id	NUMBER;
	BEGIN
		-- get alert frame
		BEGIN
			SELECT MIN(alert_frame_id)
			  INTO v_alert_frame_id
			  FROM csr.alert_frame
			 WHERE name = 'Default';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.alert_pkg.CreateFrame('Default', v_alert_frame_id);
		END;

		-- create or retrieve alert
		BEGIN
			INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
				 VALUES (csr.customer_alert_type_id_seq.nextval, in_alert_id)
			RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				dbms_output.put_line('The data change request alert is already enabled.');
				SELECT customer_alert_type_id INTO v_customer_alert_type_id
				  FROM csr.customer_alert_type
				 WHERE std_alert_type_id = in_alert_id;
		END;

		-- create alert template
		BEGIN
			INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type) VALUES (v_customer_alert_type_id, v_alert_frame_id, 'manual');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				dbms_output.put_line('Customer Alert Template already created.');
		END;

		-- add templates for each lang on site
		INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT v_customer_alert_type_id, ts.lang, dt.subject, dt.body_html, dt.item_html
		  FROM csr.default_alert_template_body dt
		  JOIN aspen2.translation_set ts
			ON ts.lang = dt.lang
		   AND dt.std_alert_type_id = in_alert_id
		  LEFT JOIN csr.alert_template_body atb
			ON atb.lang = dt.lang
		   AND atb.customer_alert_type_id = v_customer_alert_type_id
		   AND atb.app_sid = ts.application_sid
		 WHERE ts.application_sid = security.security_pkg.getapp
		   AND ts.hidden = 0
		   AND atb.body_html IS NULL;
	END;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');

	-- enable alerts
	EnableAlert(csr.csr_data_pkg.ALERT_SHEET_CHANGE_REQ);
	EnableAlert(csr.csr_data_pkg.ALERT_SHEET_CHANGE_REQ_REJ);
	EnableAlert(csr.csr_data_pkg.ALERT_SHEET_CHANGE_REQ_APPR);
END;
/

COMMIT;

SET SERVEROUTPUT OFF;

EXIT;
