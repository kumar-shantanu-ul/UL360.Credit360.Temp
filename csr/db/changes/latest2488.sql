-- Please update version.sql too -- this keeps clean builds in sync
define version=2488
@update_header

CREATE SEQUENCE CSR.UPDATED_DELEG_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE TABLE CSR.UPDATED_DELEGATION_ALERT(
    APP_SID					        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    UPDATED_DELEGATION_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID                 NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID              NUMBER(10, 0)    NOT NULL,
    SHEET_ID                        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_UPDATED_DELEGATION_ALERT PRIMARY KEY (APP_SID, UPDATED_DELEGATION_ALERT_ID)
)
;


-- Update New Delegation alert description
UPDATE CSR.STD_ALERT_TYPE
   SET SEND_TRIGGER=q'[This alert is sent when a new delegation plan is created (or when additional regions are added to an existing delegation plan) and the user clicks 'Apply plan'. 'New delegation' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]'
 WHERE STD_ALERT_TYPE_ID=2;



-- Add alerts
DECLARE 
	alert_id NUMBER(1);
BEGIN

	-- Updated delegation
	alert_id := 8;

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (alert_id, 'Updated delegation', 
		 q'[This alert is sent when the user rolls out changes to existing forms by clicking Synchronise changes on the template for the delegation plan. 'Update delegation' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'); 


	-- New delegation
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

END;
/

@../csr_data_pkg
@../sheet_pkg
@../sheet_body
@../delegation_pkg
@../delegation_body
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
