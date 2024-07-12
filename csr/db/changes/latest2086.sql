-- Please update version.sql too -- this keeps clean builds in sync
define version=2086
@update_header

DECLARE 
	v_customer_alert_type_id	NUMBER(10);
	v_std_alert_type_id			NUMBER(10);
BEGIN
	v_std_alert_type_id := 57;
  
	INSERT INTO csr.std_alert_type (std_alert_type_id, parent_alert_type_id, description, send_trigger, sent_from, override_user_send_setting)
	VALUES (v_std_alert_type_id, null, 'Delegation returned', 'A delegation sheet has been returned.', 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).', 0);

	FOR u IN (
		SELECT cat.std_alert_type_id, cat.app_sid, cat.customer_alert_type_id, cat.get_params_sp,
			   atb.lang, atb.subject, atb.body_html, atb.item_html, 
			   at.alert_frame_id, at.send_type, at.reply_to_name, at.reply_to_email, at.from_name, at.from_email
		  FROM CSR.CUSTOMER_ALERT_TYPE cat
		  LEFT JOIN CSR.ALERT_TEMPLATE_BODY atb ON atb.CUSTOMER_ALERT_TYPE_ID = cat.CUSTOMER_ALERT_TYPE_ID
		  LEFT JOIN CSR.ALERT_TEMPLATE at ON at.CUSTOMER_ALERT_TYPE_ID = cat.CUSTOMER_ALERT_TYPE_ID
		WHERE std_alert_type_id = 4 --ALERT_SHEET_CHANGED
	)
	LOOP
		SELECT csr.customer_alert_type_id_seq.nextval INTO v_customer_alert_type_id FROM dual;
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_Id, std_alert_type_Id, get_params_sp) 
				VALUES (u.app_sid, v_customer_alert_type_id, v_std_alert_type_id, u.get_params_sp);

			-- this is a non-null field, but will be null if there is no template because of the left join
			IF u.alert_frame_id IS NOT NULL THEN
				INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email, from_name, from_email)
					VALUES (u.app_sid, v_customer_alert_type_id, u.alert_frame_id, u.send_type, u.reply_to_name, u.reply_to_email, u.from_name, u.from_email);
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- keyed on language so trap and pull in right ID
				SELECT customer_alert_type_id 
				  INTO v_customer_alert_type_id
				  FROM csr.customer_alert_type
				 WHERE app_sid = u.app_sid 
				   AND std_alert_type_Id = v_std_alert_type_Id; 
		END;
			
		--BEGIN
		IF u.lang IS NOT NULL THEN
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
				VALUES (u.app_sid, v_customer_alert_type_id, u.lang, u.subject, u.body_html, u.item_html);
		END IF;
		--EXCEPTION
			-- [rk: WHEN OTHERS is very rarely acceptable -- commented this out so that it blows up for someone so we
			-- can see which exception it's meant to be]
			--
			-- Do nothing - will only blow up if there is no template
			-- body. We still want to insert the alert type.
			--WHEN OTHERS THEN
				--NULL;
		--END;
	END LOOP;
END;
/

@..\delegation_body

@update_tail
