-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_reminder_alert_type_id	NUMBER := 60;
	v_overdue_alert_type_id		NUMBER := 61;
BEGIN
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
	) LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_reminder_alert_type_id);
			
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_overdue_alert_type_id);

			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = r.app_sid
			   AND cat.std_alert_type_id IN (v_reminder_alert_type_id, v_overdue_alert_type_id)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;			
			
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT r.app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (v_reminder_alert_type_id, v_overdue_alert_type_id)
			   AND d.lang='en'
			   AND t.application_sid = r.app_sid
			   AND cat.app_sid = r.app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csr_app_body
@..\issue_body

@update_tail
