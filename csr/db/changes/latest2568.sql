-- Please update version.sql too -- this keeps clean builds in sync
define version=2568
@update_header

ALTER TABLE CSR.UPDATED_DELEGATION_ALERT RENAME TO UPDATED_PLANNED_DELEG_ALERT;

DECLARE
  v_id NUMBER(10);
BEGIN
  SELECT csr.UPDATED_DELEG_ALERT_ID_SEQ.nextval INTO v_id FROM DUAL;
  EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.UPDATED_PLANDELEG_ALERT_ID_SEQ START WITH ' || v_id || ' INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCACHE NOORDER';
END;
/
DROP SEQUENCE CSR.UPDATED_DELEG_ALERT_ID_SEQ;


CREATE SEQUENCE CSR.NEW_PLANDELEG_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

ALTER TABLE CSR.UPDATED_PLANNED_DELEG_ALERT
  RENAME COLUMN UPDATED_DELEGATION_ALERT_ID to UPDATED_PLANNED_DELEG_ALERT_ID;

ALTER TABLE CSR.UPDATED_PLANNED_DELEG_ALERT
  RENAME CONSTRAINT PK_UPDATED_DELEGATION_ALERT to PK_UPDATED_PLANNED_DELEG_ALERT;
  
CREATE TABLE CSR.NEW_PLANNED_DELEG_ALERT(
    APP_SID					        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    NEW_PLANNED_DELEG_ALERT_ID 		NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID                 NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID              NUMBER(10, 0)    NOT NULL,
    SHEET_ID                        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_NEW_PLANNED_DELEG_ALERT PRIMARY KEY (APP_SID, NEW_PLANNED_DELEG_ALERT_ID)
);


-- Put back the old description for New Delegation alert
UPDATE CSR.STD_ALERT_TYPE
   SET SEND_TRIGGER=q'[A new delegation is created and the creator requests that users be notified. New delegation notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]'
 WHERE STD_ALERT_TYPE_ID=2;

UPDATE CSR.STD_ALERT_TYPE
   SET DESCRIPTION='Delegation plan - forms updated'
 WHERE STD_ALERT_TYPE_ID=8;


-- Add alerts
DECLARE 
	alert_id NUMBER(2);
BEGIN

	-- New Planned delegation
	alert_id := 68;

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (alert_id, 
		 'Delegation plan - new forms created', 
		 q'[This alert is sent when delegation forms are created from a delegation plan, either by applying the delegation plan or by adding new regions to a delegation plan that has been applied dynamically. 'Delegation plans - new forms created' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'); 

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
@../csr_app_body
@../sheet_pkg
@../delegation_pkg
@../sheet_body
@../delegation_body
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail