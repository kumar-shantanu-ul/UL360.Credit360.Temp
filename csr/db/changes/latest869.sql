-- Please update version.sql too -- this keeps clean builds in sync
define version=869
@update_header

INSERT INTO CSR.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_ID', 'Issue id', 'The issue id', 15);

DELETE FROM CSR.alert_type_param WHERE alert_type_id = 19 AND field_name = 'ISSUE_ID' AND display_pos = 15;

@update_tail
