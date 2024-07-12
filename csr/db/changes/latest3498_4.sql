-- Please update version.sql too -- this keeps clean builds in sync
define version=3498
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (
		SELECT cat.app_sid, alt.alert_frame_id
		  FROM csr.customer_alert_type cat
		  JOIN csr.alert_template alt ON cat.app_sid = alt.app_sid
		 WHERE std_alert_type_id = 20 -- csr.csr_data_pkg.ALERT_GENERIC_MAILOUT
	) LOOP
		INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT r.app_sid, cat.customer_alert_type_id, r.alert_frame_id, dat.send_type
		  FROM csr.default_alert_template dat
		  JOIN csr.customer_alert_type cat ON cat.app_sid = r.app_sid AND cat.std_alert_type_id = dat.std_alert_type_id
		 WHERE dat.std_alert_type_id = 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
		   AND NOT EXISTS (SELECT NULL FROM csr.alert_template WHERE app_sid = cat.app_sid AND customer_alert_type_id = cat.customer_alert_type_id);
		  
		INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.app_sid, cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM csr.default_alert_template_body datb 
		  JOIN csr.customer_alert_type cat ON cat.app_sid = r.app_sid AND cat.std_alert_type_id = datb.std_alert_type_id
		 WHERE datb.std_alert_type_id = 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
		   AND NOT EXISTS (SELECT NULL FROM csr.alert_template_body WHERE app_sid = cat.app_sid AND customer_alert_type_id = cat.customer_alert_type_id);
	END LOOP;
END;
/
		 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
