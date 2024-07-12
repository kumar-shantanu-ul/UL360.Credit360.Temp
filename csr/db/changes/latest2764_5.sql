-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	PROCEDURE AddMissingAlert(
		in_app_sid				NUMBER,
		in_std_alert_type_id 	NUMBER
	)
	AS
		v_customer_alert_type_id NUMBER;
	BEGIN
		-- Get the next value for customer alert type
		SELECT csr.customer_alert_type_id_seq.nextval INTO v_customer_alert_type_id
		  FROM dual;

		-- Add in the new customer alert type
		INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
		 	 VALUES (v_customer_alert_type_id, in_std_alert_type_id);

		-- and the default templates
		INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			 SELECT in_app_sid, v_customer_alert_type_id, taf.alert_frame_id, 'manual' send_type
			   FROM csr.default_alert_template dat, csr.customer_alert_type cat, csr.temp_alert_frame taf
			  WHERE cat.std_alert_type_id = dat.std_alert_type_id AND dat.default_alert_frame_id = taf.default_alert_frame_id
			    AND cat.std_alert_type_id = in_std_alert_type_id
			    AND cat.app_sid = in_app_sid;

		-- Add the template body for this customer copied from default template body which should cover all languages
		INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			 SELECT in_app_sid, v_customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
			   FROM csr.default_alert_template_body datb, csr.customer_alert_type cat
			  WHERE cat.std_alert_type_id = datb.std_alert_type_id 
			    AND cat.std_alert_type_id = in_std_alert_type_id
			    AND cat.app_sid = in_app_sid;
	END;

BEGIN
	security.user_pkg.logonadmin();
	-- Should really create a "delegation returned" default alert template and body copied from "delegation changed alert"
	INSERT INTO csr.default_alert_template(std_alert_type_id, default_alert_frame_id, send_type)
		 SELECT csr.csr_data_pkg.ALERT_SHEET_RETURNED, default_alert_frame_id, send_type
		   FROM csr.default_alert_template
		  WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED;

	INSERT INTO csr.default_alert_template_body(std_alert_type_id, lang, subject, body_html, item_html)
		 SELECT csr.csr_data_pkg.ALERT_SHEET_RETURNED, lang, subject, body_html, item_html
		   FROM csr.default_alert_template_body
		  WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED;

	-- Get all the customers that don't have the sheet changed alert
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE app_sid NOT IN (
		 	SELECT app_sid
		 	  FROM csr.customer_alert_type
		 	 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_CHANGED
	 	)
		   AND app_sid NOT IN (
		 	SELECT app_sid
		 	  FROM csr.customer_alert_type
		 	 WHERE std_alert_type_id = csr.csr_data_pkg.ALERT_SHEET_RETURNED
	 	)
	)
	LOOP
		security.security_pkg.SetApp(r.app_sid);

		-- Create the two missing templates for each customer
		AddMissingAlert(r.app_sid, csr.csr_data_pkg.ALERT_SHEET_CHANGED);
		AddMissingAlert(r.app_sid, csr.csr_data_pkg.ALERT_SHEET_RETURNED);

		security.security_pkg.SetApp(NULL);
 	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail