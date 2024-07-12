-- Please update version.sql too -- this keeps clean builds in sync
define version=1382
@update_header

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (41, 'In-bound email processing failure',
	'A form that was emailed in was not processed correctly.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (42, 'In-bound email processed successfully',
	'A form that was emailed in was processed correctly.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);



INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TABLE_DESCRIPTION', 'Table name', 'The name of the table being inserted into', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'ERRORS', 'Errors', 'The problems encountered', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'SUBJECT_RCVD', 'Subject of received email', 'Inbound email subject', 7);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TABLE_DESCRIPTION', 'Table name', 'The name of the table being inserted into', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'REF', 'New reference', 'The reference for the logged item', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'SUBJECT_RCVD', 'Subject of received email', 'Inbound email subject', 8);

INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) 
	SELECT 41, MAX(default_alert_frame_id), 'manual' FROM csr.default_alert_frame;
INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) 
	SELECT 42, MAX(default_alert_frame_id), 'manual' FROM csr.default_alert_frame;

INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (41, 'en',
	'<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by email failed</template>',
	'<template><p>Hello,</p>'||
	'<p>Thank you for your email entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
	'<p>We were unable to process this for the following reasons:</p>'||
	'<p><mergefield name="ERRORS"/></p>'||
	'</template>',
	'<template/>');

INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (42, 'en',
	'<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by email was processed successfully</template>',
	'<template><p>Hello,</p>'||
	'<p>Thank you for your email entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
	'<p>It was processed successfully. Your reference is <mergefield name="REF"/>.</p>'||
	'</template>',
	'<template/>');
	
CREATE TABLE CSR.INBOUND_ISSUE_ACCOUNT (
    APP_SID             NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ACCOUNT_SID			NUMBER(10)		NOT NULL,
    ISSUE_TYPE_ID		NUMBER(10)		NOT NULL,
    CONSTRAINT PK_INBOUND_ISSUE_ACCOUNT PRIMARY KEY (ACCOUNT_SID)
);

ALTER TABLE CSR.INBOUND_ISSUE_ACCOUNT ADD CONSTRAINT FK_ISS_TYPE_INB_ISS_ACC
    FOREIGN KEY (APP_SID, ISSUE_TYPE_ID)
    REFERENCES CSR.ISSUE_TYPE(APP_SID, ISSUE_TYPE_ID);
	
CREATE TABLE CSR.INBOUND_CMS_ACCOUNT (
    APP_SID             NUMBER(10)      DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ACCOUNT_SID			NUMBER(10)		NOT NULL,
    TAB_SID				NUMBER(10)		NOT NULL,
	FLOW_SID			NUMBER(10),		
	DEFAULT_REGION_SID	NUMBER(10),	
    CONSTRAINT PK_INBOUND_CMS_ACCOUNT PRIMARY KEY (ACCOUNT_SID)
);

ALTER TABLE CSR.INBOUND_CMS_ACCOUNT ADD CONSTRAINT FK_FLOW_INBOUND_CMS_ACCOUNT
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID);
    
ALTER TABLE CSR.INBOUND_CMS_ACCOUNT ADD CONSTRAINT FK_REGION_INBOUND_CMS_ACCOUNT
    FOREIGN KEY (APP_SID, DEFAULT_REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID);


-- cross schema
ALTER TABLE CSR.INBOUND_ISSUE_ACCOUNT ADD CONSTRAINT FK_ACCOUNT_INB_ISS_ACC
	FOREIGN KEY (ACCOUNT_SID)
    REFERENCES MAIL.ACCOUNT(ACCOUNT_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INBOUND_CMS_ACCOUNT ADD CONSTRAINT FK_ACCOUNT_INBOUND_CMS_ACCOUNT
	FOREIGN KEY (ACCOUNT_SID)
    REFERENCES MAIL.ACCOUNT(ACCOUNT_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INBOUND_CMS_ACCOUNT ADD CONSTRAINT FK_TAB_INBOUND_CMS_ACCOUNT
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID) ON DELETE CASCADE;

-- RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'INBOUND_CMS_ACCOUNT',
		policy_name     => 'INBOUND_CMS_ACCOUNT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'INBOUND_ISSUE_ACCOUNT',
		policy_name     => 'INBOUND_ISSUE_ACCOUNT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/


@../../../yam/db/reader_pkg
@../issue_pkg
@../flow_pkg

@../../../yam/db/reader_body
@../issue_body
@../flow_body


@update_tail
