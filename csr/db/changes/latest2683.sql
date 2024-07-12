-- Please update version.sql too -- this keeps clean builds in sync
define version=2683
@update_header


--re-running ONLY (temp)
--DROP TABLE CSR.INBOUND_FEED_ACCOUNT;
--DROP TABLE CSR.INBOUND_FEED_ATTACHMENT;
--end

CREATE TABLE CSR.INBOUND_FEED_ACCOUNT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ACCOUNT_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_CSR_INBOUND_FEED_ACCOUNT PRIMARY KEY (APP_SID, ACCOUNT_SID)
);


CREATE TABLE CSR.INBOUND_FEED_ATTACHMENT (
    APP_SID 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ACCOUNT_SID 	NUMBER(10) NOT NULL,
    MESSAGE_UID 	NUMBER(10) NOT NULL,
    NAME 			VARCHAR2(256) NOT NULL,
    RECEIPT_DATE 	DATE NOT NULL,
    PROCESSED_DATE 	DATE,
	ATTACHMENT		BLOB,
    CONSTRAINT PK_CSR_INBOUND_FEED_ATTACHMENT PRIMARY KEY (APP_SID, ACCOUNT_SID, MESSAGE_UID, NAME)
);


@../feed_pkg
@../feed_body


-- Add alerts
DECLARE 
	alert_id NUMBER(2);
BEGIN

	-- Inbound Feed Failure
	alert_id := 69;

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (alert_id, 
		 'Inbound feed - failure', 
		 q'[This alert is sent when an inbound feed email was received but not processed. 'Inbound feed - failure' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'); 

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'REF', 'Reference', 'The MessageUID of the originating email', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'SUBJECT_RCVD', 'Subject (Received)', 'The subject of the originating email', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'ERRORS', 'Errors', 'The errors in the email', 5);

	-- Inbound Feed Success
	alert_id := 70;

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (alert_id, 
		 'Inbound feed - success', 
		 q'[This alert is sent when an inbound feed email was received. 'Inbound feed - success' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'); 

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'REF', 'Reference', 'The MessageUID of the originating email', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (alert_id, 0, 'SUBJECT_RCVD', 'Subject (Received)', 'The subject of the originating email', 4);

END;
/

@../csr_data_pkg
--@../csr_data_body

INSERT INTO csr.cms_imp_result
VALUES (5, 'Nothing To Do');

@update_tail