-- Please update version.sql too -- this keeps clean builds in sync
define version=1567
@update_header

BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view section history', 1);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

--
-- route POS change
--
ALTER TABLE CSR.ROUTE_STEP ADD (
    POS                 NUMBER(10, 0)   
)
;    
--DROP INDEX CSR.UK_ROUTE_STEP_POS ;

-- fill the pos with initial values
DECLARE   
  v_pos 		number(10);
  v_route_id  	number(10);
BEGIN
  v_pos := 0;
  v_route_id := 0;

  FOR r IN (SELECT route_step_id,route_id , work_days_offset FROM csr.route_step ORDER BY route_id, work_days_offset DESC)
  LOOP
	IF v_route_id != r.route_id THEN
	  v_pos := 0;
	  v_route_id := r.route_id;
	END IF;
	
	UPDATE csr.route_step
	   SET pos = v_pos
	 WHERE route_step_id = r.route_step_id;
  
	v_pos := v_pos + 1;
	
  END LOOP;
  COMMIT;
END;
/

-- 
-- INDEX: CSR.UK_ROUTE_STEP_POS 
--
ALTER TABLE CSR.ROUTE_STEP MODIFY POS NOT NULL;

CREATE UNIQUE INDEX CSR.UK_ROUTE_STEP_POS ON CSR.ROUTE_STEP(APP_SID, ROUTE_ID, POS)
;

--
-- New alert type
--

DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (48, 'Section overdue reminder',
		'The date the question is due',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 0, 'HOST', 'Site host address', 'Address of the website', 3);
						
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 1, 'DUE_DTM', 'Current step due date', 'Date when section is going to be due', 1);
			
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (48, 1, 'STATE_LABEL', 'Flow State', 'Section''s current flow state name', 4);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (48, v_default_alert_frame_id, 'manual');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (48, 'en-gb',
		'<template>Following questions are going to be overdue</template>',
		'<template><p>Dear <mergefield name="TO_FULL_NAME"/>. You''re receiving this email because there are questions awaiting your input.</p>'||
		'<template/>', 
		'<template><p>The question <mergefield name="SECTION_TITLE"/> is currently at the <mergefield name="TO_STATE_LABEL"/> state in the annual report update process with due date: <mergefield name="DUE_DTM"/>.</p></template>'
		);
		

	-- add new alert to all customers that uses flow on sections
	FOR r IN (
		SELECT DISTINCT app_sid 
		  FROM csr.section_module
		 WHERE flow_sid is NOT NULL
	)
	LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
				SELECT r.app_sid, csr.customer_alert_type_id_seq.nextval, std_alert_type_id
				  FROM csr.std_alert_type 
				 WHERE std_alert_type_id IN (48);		
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
	
END;
/

ALTER TABLE CSR.ROUTE_STEP_USER ADD REMINDER_SENT_DTM DATE;

@../csr_data_pkg
@../section_pkg
@../section_body

@update_tail