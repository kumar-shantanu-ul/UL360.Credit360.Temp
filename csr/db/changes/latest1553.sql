-- Please update version.sql too -- this keeps clean builds in sync
define version=1553
@update_header

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (47, 'Weekly issues coming due',
	'There are issues you are involved in that are about to become overdue. This is sent on a scheduled basis, e.g. weekly.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet that the issue relates to', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'SHEET_URL', 'Sheet url', 'A link to the sheet that the issue relates to', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_DETAIL', 'Issue details', 'The issue details', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_LABEL', 'Issue label', 'The issue label', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_TYPE_DESCRIPTION', 'Issue type', 'The description of the issue type', 14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_ID', 'Issue id', 'The issue id', 15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'DUE_DTM', 'Due date', 'The due date of the issue', 16);

ALTER TABLE CSR.TPL_REPORT_NON_COMPL ADD
    TAG_ID                     NUMBER(10, 0)
;

CREATE INDEX CSR.IX_TPL_REP_NC_TAG ON CSR.TPL_REPORT_NON_COMPL(APP_SID, TAG_ID)
;

ALTER TABLE CSR.TPL_REPORT_NON_COMPL ADD CONSTRAINT FK_TPL_REP_NC_TAG 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSRIMP.TPL_REPORT_NON_COMPL ADD
    TAG_ID                     NUMBER(10, 0)
;

@..\templated_report_pkg
@..\audit_pkg
@..\csr_data_pkg
@..\issue_pkg

@..\csrimp\imp_body
@..\templated_report_body
@..\audit_body
@..\schema_body
@..\issue_body

@update_tail