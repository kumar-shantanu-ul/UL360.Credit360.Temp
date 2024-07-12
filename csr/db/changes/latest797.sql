-- Please update version.sql too -- this keeps clean builds in sync
define version=797
@update_header

ALTER TABLE CSR.ISSUE_TYPE ADD (
	ALERT_MAIL_ADDRESS          VARCHAR2(100),
	ALERT_MAIL_NAME             VARCHAR2(100)
);

INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (12, 'Email received');

UPDATE CSR.ALERT_TYPE 
   SET SENT_FROM = 'A issue type configured address, or the configured system e-mail address when not found (this defaults to support@credit360.com, but can be changed from the site setup page).'
 WHERE ALERT_TYPE_ID IN (32, 33, 34, 35);

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 1, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet that the issue relates to', 11);
INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 1, 'SHEET_URL', 'Sheet url', 'A link to the sheet that the issue relates to', 12);
INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 13);

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (32, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 4);

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);

-- redefine issue_log.message as a clob
alter table csr.issue_log rename column message to old_message;
alter table csr.issue_log add (message clob);
update csr.issue_log set message = old_message;
alter table csr.issue_log modify (message not null);
alter table csr.issue_log drop column old_message;

@..\csr_data_pkg
@..\issue_pkg
@..\issue_body

@update_tail
