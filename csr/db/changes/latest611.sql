-- Please update version.sql too -- this keeps clean builds in sync
define version=611
@update_header

--ALERT_SHEET_CHANGE_REQ


@..\csr_data_pkg


INSERT INTO csr.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (29, 'Delegation data change request',
	'This alert is sent when a user submits a request to change data on a previously submitted delegation.',
	'The user who is requesting the change.'
); 

INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'COMMENT', 'Comment', 'The comment', 12);



-- 
-- SEQUENCE: SHEET_CHANGE_REQ_SEQ 
--

CREATE SEQUENCE csr.SHEET_CHANGE_REQ_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- 
-- TABLE: SHEET_CHANGE_REQ 
--

CREATE TABLE csr.SHEET_CHANGE_REQ(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_CHANGE_REQ_ID       NUMBER(10, 0)    NOT NULL,
    REQ_TO_CHANGE_SHEET_ID    NUMBER(10, 0)    NOT NULL,
    ACTIVE_SHEET_ID           NUMBER(10, 0)    NOT NULL,
    RAISED_DTM                DATE             DEFAULT SYSDATE NOT NULL,
    RAISED_BY_SID             NUMBER(10, 0)    NOT NULL,
    RAISED_NOTE               CLOB,
    PROCESSED_DTM             DATE,
    PROCESSED_BY_SID          NUMBER(10, 0),
    PROCESSED_NOTE            CLOB,
    IS_APPROVED               NUMBER(1, 0),
    CONSTRAINT CHK_SHEET_CHANGE_REQ_PROC CHECK (IS_APPROVED IS NULL OR (IS_APPROVED IN (1,0) AND PROCESSED_DTM IS NOT NULL AND PROCESSED_BY_SID IS NOT NULL)),
    CONSTRAINT PK_SHEET_CHANGE_REQ PRIMARY KEY (APP_SID, SHEET_CHANGE_REQ_ID)
);



-- 
-- INDEX: UK_SHEET_CHANGE_REQ_SINGLE 
--

-- i.e. if IS_APPROVED is null, then ensure there is only one row like this per sheet. Otherwise return sheet_change_req_id which is always unqiue
CREATE UNIQUE INDEX csr.UK_SHEET_CHANGE_REQ_SINGLE ON csr.SHEET_CHANGE_REQ(REQ_TO_CHANGE_SHEET_ID, DECODE(IS_APPROVED, null, 1, SHEET_CHANGE_REQ_ID));

-- 
-- TABLE: SHEET_CHANGE_REQ 
--

ALTER TABLE csr.SHEET_CHANGE_REQ ADD CONSTRAINT FK_SHEET_CHANGE_REQ_CSR_USER_1 
    FOREIGN KEY (APP_SID, PROCESSED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE csr.SHEET_CHANGE_REQ ADD CONSTRAINT FK_SHEET_CHANGE_REQ_CSR_USER_2 
    FOREIGN KEY (APP_SID, RAISED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE csr.SHEET_CHANGE_REQ ADD CONSTRAINT FK_SHEET_CHANGE_REQ_CUST 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID);

ALTER TABLE csr.SHEET_CHANGE_REQ ADD CONSTRAINT FK_SHEET_CHANGE_REQ_SHEET_1
    FOREIGN KEY (APP_SID, ACTIVE_SHEET_ID)
    REFERENCES csr.SHEET(APP_SID, SHEET_ID)
;

ALTER TABLE csr.SHEET_CHANGE_REQ ADD CONSTRAINT FK_SHEET_CHANGE_REQ_SHEET_2
    FOREIGN KEY (APP_SID, REQ_TO_CHANGE_SHEET_ID)
    REFERENCES csr.SHEET(APP_SID, SHEET_ID)
;

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'SHEET_CHANGE_REQ',
        policy_name     => 'SHEET_CHANGE_REQ_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

@update_tail
