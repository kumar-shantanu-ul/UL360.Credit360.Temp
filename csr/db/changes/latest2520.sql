-- Please update version.sql too -- this keeps clean builds in sync
define version=2520
@update_header

CREATE TABLE CSR.AUDIT_ISS_ALL_CLOSED_ALERT(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_SID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID          NUMBER(10, 0)    NOT NULL,
    ALERT_SENT_DTM     	  DATE 			   NOT NULL,
    CONSTRAINT PK_AUDIT_ISS_ALL_CLOSED_ALERT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, CSR_USER_SID, ALERT_SENT_DTM)
);

ALTER TABLE CSR.AUDIT_ISS_ALL_CLOSED_ALERT ADD CONSTRAINT FK_INTERNAL_AUDIT
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
    REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID)
;

ALTER TABLE CSR.AUDIT_ISS_ALL_CLOSED_ALERT ADD CONSTRAINT FK_CSR_USER
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

@latest2520_packages

DECLARE
	v_default_alert_frame_id	NUMBER;
	v_customer_alert_type_id	NUMBER;
	v_all_closed_alert_type_id	NUMBER := CSR.TEMP_CSR_DATA_PKG.ALERT_AUDIT_ALL_ISSUES_CLOSED;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (v_all_closed_alert_type_id, 'All audit issues have been closed',
		'When the last open issue in an audit is closed.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 1, 'AUDIT_REGION', 'Audit region', 'The name of the region that the audit relates to', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 1, 'AUDIT_TYPE_LABEL', 'Audit Type Label', 'Audit type label', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_all_closed_alert_type_id, 1, 'AUDIT_LINK', 'Audit link', 'Link to the audit', 8);	

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (v_all_closed_alert_type_id, v_default_alert_frame_id, 'manual');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (v_all_closed_alert_type_id, 'en',
		'<template>Audits whose issues have all been closed</template>',
		'<template><p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p><p>The following audits'' issues have all now been closed:</p><mergefield name="ITEMS"/></template>', 
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/>. <mergefield name="AUDIT_LINK"/></p></template>'
		);
END;
/

DROP PACKAGE csr.TEMP_CSR_DATA_PKG;

@..\audit_pkg
@..\audit_body

@update_tail
