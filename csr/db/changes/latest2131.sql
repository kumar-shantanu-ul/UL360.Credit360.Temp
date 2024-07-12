-- Please update version.sql too -- this keeps clean builds in sync
define version=2131
@update_header

BEGIN
	security.user_pkg.logonadmin;
    FOR r in (
        select sid_Id from security.securable_object where name = 'Automatically approve Data Change Requests'
    )
    LOOP
        security.securableobject_pkg.deleteso(security.security_pkg.getact, r.sid_id);
    END LOOP;
    delete from csr.capability where name = 'Automatically approve Data Change Requests';
END;
/

DROP INDEX CSR.UK_SHEET_CHANGE_REQ_SINGLE;
CREATE UNIQUE INDEX CSR.UK_SHEET_CHANGE_REQ_SINGLE ON CSR.SHEET_CHANGE_REQ(REQ_TO_CHANGE_SHEET_ID, DECODE(IS_APPROVED, null, -1, sheet_change_req_id));

CREATE SEQUENCE CSR.SHEET_CHANGE_REQ_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE TABLE CSR.SHEET_CHANGE_REQ_ALERT(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_CHANGE_REQ_ALERT_ID    NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID              NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID           NUMBER(10, 0)    NOT NULL,
    SHEET_CHANGE_REQ_ID          NUMBER(10, 0)    NOT NULL,
    ACTION_TYPE                  VARCHAR2(1)      NOT NULL,
    CONSTRAINT CHK_SCR_ALERT_TYPE CHECK (ACTION_TYPE IN ('S', 'A', 'R')),
    CONSTRAINT PK_DELEG_DATA_CHANGE_ALERT_1 PRIMARY KEY (APP_SID, SHEET_CHANGE_REQ_ALERT_ID)
);

ALTER TABLE CSR.SHEET_CHANGE_REQ_ALERT ADD CONSTRAINT FK_SCR_SCR_ALERT 
    FOREIGN KEY (APP_SID, SHEET_CHANGE_REQ_ID)
    REFERENCES CSR.SHEET_CHANGE_REQ(APP_SID, SHEET_CHANGE_REQ_ID);

ALTER TABLE CSR.SHEET_CHANGE_REQ_ALERT ADD CONSTRAINT FK_USER_SCR_ALERT_NOTIFY 
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.SHEET_CHANGE_REQ_ALERT ADD CONSTRAINT FK_USER_SCR_ALERT_RAISED 
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);


INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (58, 'Delegation data change request approved',
    'This alert is sent when a user approves a delegation data change request.',
    'The user who is approving the change request.'
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (59, 'Delegation data change request rejected',
    'This alert is sent when a user rejects a delegation data change request.',
    'The user who is rejecting the change request.'
);


-- Delegation data change request approved
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'COMMENT', 'Comment', 'The comment', 12);



-- Delegation data change request rejected
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'COMMENT', 'Comment', 'The comment', 12);

@..\csr_data_pkg
@..\sheet_pkg
@..\delegation_pkg
@..\sheet_body
@..\delegation_body

@update_tail