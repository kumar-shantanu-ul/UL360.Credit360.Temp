-- Please update version.sql too -- this keeps clean builds in sync
define version=868
@update_header

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_LABEL', 'Issue label', 'The issue label', 13);
INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_TYPE_DESCRIPTION', 'Issue type', 'The description of the issue type', 14);
INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 1, 'ISSUE_ID', 'Issue id', 'The issue id', 15);

@..\issue_body

@update_tail
