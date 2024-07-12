-- Please update version.sql too -- this keeps clean builds in sync
define version=1522
@update_header

-- redo the view to include flow_item_id
CREATE OR REPLACE VIEW csr.v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, s.flow_item_id,
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, s.help_text, REF, plugin, plugin_config, section_status_sid, further_info_url
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

-- New SECTION_ALERT table


--
-- SEQUENCE: CSR.SECTION_ALERT_ID_SEQ 
--

CREATE SEQUENCE CSR.SECTION_ALERT_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;


-- 
-- TABLE: CSR.SECTION_ALERT 
--

CREATE TABLE CSR.SECTION_ALERT(
	APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_ALERT_ID          NUMBER(10, 0)    NOT NULL,
	CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
	SECTION_SID               NUMBER(10, 0)    NOT NULL,
	RAISED_DTM                DATE             NOT NULL,
	FROM_USER_SID             NUMBER(10, 0)    NOT NULL,
	NOTIFY_USER_SID           NUMBER(10, 0)    NOT NULL,
	FLOW_STATE_ID             NUMBER(10, 0)    NOT NULL,
	ROUTE_STEP_ID             NUMBER(10, 0),
	SENT_DTM                  DATE,
	CANCELLED_DTM             DATE,
	CONSTRAINT PK_SECTION_ALERT PRIMARY KEY (APP_SID, SECTION_ALERT_ID, SECTION_SID)
)
;




-- 
-- TABLE: CSR.SECTION_ALERT 
--

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_CAT_SECTION_ALERT_TYPE 
	FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
	REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID)
;

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_FLOW_STATE_SECTION_ALERT 
	FOREIGN KEY (APP_SID, FLOW_STATE_ID)
	REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID)
;

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_ROUTE_STEP_SECTION_ALERT 
	FOREIGN KEY (APP_SID, ROUTE_STEP_ID)
	REFERENCES CSR.ROUTE_STEP(APP_SID, ROUTE_STEP_ID)
;

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_SECTION_SECTION_ALERT 
	FOREIGN KEY (APP_SID, SECTION_SID)
	REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_USER_SECTION_ALERT_FROM 
	FOREIGN KEY (APP_SID, FROM_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.SECTION_ALERT ADD CONSTRAINT FK_USER_SECTION_ALERT_TO 
	FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;




@..\csr_data_pkg

-- new alert type
DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (44, 'Section state change message',
		'Section flow or route state has been changed.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 0, 'HOST', 'Site host address', 'Address of the website', 3);
						
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 1, 'DUE_DTM', 'Current step due date', 'Date when section is going to be due', 1);
			
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 1, 'FROM_FULL_NAME', 'From User', 'Full name of user that send it to you', 3);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (44, 1, 'STATE_LABEL', 'Flow State', 'Section''s current flow state name', 4);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (44, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (44, 'en-gb',
		'<template>Section has been changed</template>',
		'<template><p>Dear <mergefield name="TO_FULL_NAME"/>,</p>'||
		'<template/>', 
		'<template><p>The question <mergefield name="SECTION_TITLE"/> is currently at the <mergefield name="TO_STATE_LABEL"/> state in the annual report update process. It has been passed to you by <mergefield name="FROM_FULL_NAME".</p></template>'
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
				 WHERE std_alert_type_id IN (44);		
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
	
END;
/

@..\csr_data_pkg
@..\section_pkg
@..\section_body

@update_tail