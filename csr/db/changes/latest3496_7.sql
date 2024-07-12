-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.SHEET_CREATED_ALERT_ID_SEQ;

CREATE TABLE CSR.SHEET_CREATED_ALERT(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_CREATED_ALERT_ID         NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID                NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID             NUMBER(10, 0)    NOT NULL,
    SHEET_ID                       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_CREATED_ALERT PRIMARY KEY (APP_SID, SHEET_CREATED_ALERT_ID)
)
;

-- Alter tables

-- Tidy up dangling records

-- >100K records on prd
DELETE FROM csr.new_planned_deleg_alert
 WHERE new_planned_deleg_alert_id IN (
	SELECT new_planned_deleg_alert_id FROM csr.new_planned_deleg_alert al
	  LEFT JOIN csr.customer c ON c.app_sid = al.app_sid
	 WHERE host is null
);

-- >2000K records on prd
DELETE FROM csr.new_planned_deleg_alert
 WHERE new_planned_deleg_alert_id IN (
	SELECT new_planned_deleg_alert_id FROM csr.new_planned_deleg_alert al
	  LEFT JOIN csr.sheet s ON s.sheet_id = al.sheet_id
	 WHERE s.sheet_id is null
);


ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_NOTIFY_USER
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_RAISED_USER
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_SHEET
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;

ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_NOTIFY_USER
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_RAISED_USER
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_SHEET
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;


create index csr.ix_new_planned_deleg_alrt_notify_user on csr.new_planned_deleg_alert(app_sid, notify_user_sid);
create index csr.ix_new_planned_deleg_alrt_raised_user on csr.new_planned_deleg_alert(app_sid, raised_by_user_sid);
create index csr.ix_new_planned_deleg_alert_sheet on csr.new_planned_deleg_alert(app_sid, sheet_id);
create index csr.ix_sheet_created_alrt_notify_user on csr.sheet_created_alert(app_sid, notify_user_sid);
create index csr.ix_sheet_created_alrt_raised_user on csr.sheet_created_alert(app_sid, raised_by_user_sid);
create index csr.ix_sheet_created_alert_sheet on csr.sheet_created_alert(app_sid, sheet_id);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_id NUMBER(10);
BEGIN
	-- Rename old alert type
	UPDATE csr.std_alert_type
	   SET description = 'Delegation plan - new forms created (legacy)', 
		   send_trigger = 'This alert is sent when delegation forms are created from a delegation plan, either by applying the delegation plan or by adding new regions to a delegation plan that has been applied dynamically. "Delegation plans - new forms created (legacy)" notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.'
	 WHERE std_alert_type_id = 68;
	
    -- Add new alert type 	
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID)
	VALUES (
			80,
			'Delegation - new forms created',
			'This alert is sent to all users involved in the delegation for each form when they are created. "Delegation - new forms created" notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			2 -- csr.data_pkg.ALERT_GROUP_DELEGTIONS
	);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

	-- Create default alert template
	SELECT default_alert_frame_id
	  INTO v_id
	  FROM csr.default_alert_frame
	 WHERE name = 'Default';
	  
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (80, v_id, 'inactive');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (80, 'en',
		'<template>New delegation forms to complete</template>',
		'<template><p>Hello <mergefield name="TO_FRIENDLY_NAME" />,</p><p>Delegation forms are now ready for you to complete and submit.</p><p><mergefield name="ITEMS" /></p><p>Many thanks for your co-operation.</p></template>',
		'<template><mergefield name="DELEGATION_NAME"/>(<mergefield name="SHEET_PERIOD_FMT"/>)- due <mergefield name="SUBMISSION_DTM_FMT"/><br/><mergefield name="SHEET_URL"/></template>'
	);

	-- Enable for all customers using default alert template
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
	SELECT app_sid, csr.customer_alert_type_id_seq.nextval, 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
	  FROM csr.customer_alert_type 
	 WHERE std_alert_type_id = 20; -- csr.csr_data_pkg.ALERT_GENERIC_MAILOUT
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../delegation_pkg
@../sheet_pkg

@../csr_app_body
@../csr_user_body
@../delegation_body
@../deleg_plan_body
@../sheet_body
@../util_script_body

@update_tail
