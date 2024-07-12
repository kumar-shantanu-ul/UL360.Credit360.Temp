-- Please update version.sql too -- this keeps clean builds in sync
define version=2498
@update_header

DECLARE
  v_cat NUMBER(10);
  v_out_act security.security_pkg.T_ACT_ID;
BEGIN
  FOR r IN (SELECT cat.app_sid, alert_frame_id, send_type, reply_to_name, reply_to_email, lang, subject, body_html, item_html
              FROM csr.customer_alert_type cat
              JOIN csr.alert_template_body atb ON cat.customer_alert_type_id = atb.customer_alert_type_id
              JOIN csr.alert_template at ON cat.customer_alert_type_id = at.customer_alert_type_id
             WHERE std_alert_type_id = 52)
  LOOP
    
    security.user_pkg.LogonAuthenticated(
          in_sid_id => 3,
          in_act_timeout => NULL,
          in_app_sid => r.app_sid,
          out_act_id => v_out_act);
    
    SELECT min(customer_alert_type_id)
      INTO v_cat
      FROM csr.customer_alert_type
     WHERE std_alert_type_id = 44
       AND app_sid = r.app_sid;
    
    IF v_cat IS NOT NULL THEN
      csr.alert_pkg.SaveTemplateAndBody(v_cat,
          r.alert_frame_id,
          r.send_type,
          r.reply_to_name,
          r.reply_to_email,
          r.lang,
          r.subject,
          r.body_html,
          r.item_html
          );
    END IF;
  END LOOP;
END;
/

BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (SELECT lang, subject, body_html, item_html FROM csr.default_alert_template_body WHERE std_alert_type_id = 52)
	LOOP
		UPDATE csr.default_alert_template_body 
		   SET lang = r.lang, subject = r.subject, body_html = r.body_html, item_html = r.item_html
		 WHERE std_alert_type_id = 44;
	END LOOP;
END;
/


@../section_pkg

@../section_body

@update_tail
