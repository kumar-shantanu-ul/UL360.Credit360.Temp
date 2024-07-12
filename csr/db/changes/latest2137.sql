-- Please update version.sql too -- this keeps clean builds in sync
define version=2137
@update_header

CREATE TABLE CSR.ISSUE_ALERT(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ID    		  NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID          NUMBER(10, 0)    NOT NULL,
    REMINDER_SENT_DTM     DATE,
    OVERDUE_SENT_DTM      DATE,
    CONSTRAINT PK_ISSUE_ALERT PRIMARY KEY (APP_SID, ISSUE_ID, CSR_USER_SID)
);

ALTER TABLE CSR.ISSUE_ALERT ADD CONSTRAINT FK_ISSUE_ALERT_ISSUE 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID)
;

ALTER TABLE CSR.ISSUE_ALERT ADD CONSTRAINT FK_ISSUE_ALERT_USER 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
	  
-- New alert types
DECLARE
	v_default_alert_frame_id	NUMBER;
	v_customer_alert_type_id	NUMBER;
	v_reminder_alert_type_id	NUMBER := 60;
	v_overdue_alert_type_id		NUMBER := 61;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (v_reminder_alert_type_id, 'Issues due to expire (reminder)',
		'There are issues that are about to expire. This is sent daily.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (v_overdue_alert_type_id, 'Issues expired (overdue)',
		'There are issues that have expired. This is sent daily.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	-- Expiring issues (reminder)
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 1, 'ISSUE_TYPE_LABEL', 'Issue type', 'The name of the issue type that is about to expire', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 1, 'ISSUE_REGION', 'Region name', 'The name of the region that the issue relates to', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 1, 'DUE_DTM', 'Due date', 'The date the issue should be resolved by', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_reminder_alert_type_id, 1, 'ISSUE_LINK', 'Issue link', 'Link to the issue', 9);

	-- Expired issues (overdue)
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 1, 'ISSUE_TYPE_LABEL', 'Issue type', 'The name of the issue type that has expired', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 1, 'ISSUE_REGION', 'Region name', 'The name of the region that the issue relates to', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 1, 'DUE_DTM', 'Due date', 'The date the issue was to be resolved by', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_overdue_alert_type_id, 1, 'ISSUE_LINK', 'Issue link', 'Link to the issue', 9);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (v_reminder_alert_type_id, v_default_alert_frame_id, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (v_overdue_alert_type_id, v_default_alert_frame_id, 'manual');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (v_reminder_alert_type_id, 'en',
		'<template>Issues are about to expire</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following issues are about to expire:</p><mergefield name="ITEMS"/></template>', 
		'<template><p><mergefield name="ISSUE_TYPE_LABEL"/> at <mergefield name="ISSUE_REGION"/> expires on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/></p></template>'
		);
	
	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (v_overdue_alert_type_id, 'en',
		'<template>Issues that have expired</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following issues have expired:</p><mergefield name="ITEMS"/></template>', 
		'<template><p><mergefield name="ISSUE_TYPE_LABEL"/> at <mergefield name="ISSUE_REGION"/> expired on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/></p></template>'
		);

	-- Add new alert types for all customers
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

@..\csr_data_pkg
@..\issue_pkg
@..\schema_pkg

@..\csr_data_body
@..\issue_body
@..\schema_body

@update_tail