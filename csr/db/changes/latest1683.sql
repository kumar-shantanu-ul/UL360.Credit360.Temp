-- Please update version.sql too -- this keeps clean builds in sync
define version=1683
@update_header

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_URL', 'Issue url', 'A link to the full screen issue details page', 16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'PARENT_OBJECT_URL', 'Parent object url', 'A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.', 17);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_URL', 'Issue url', 'A link to the full screen issue details page', 16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'PARENT_OBJECT_URL', 'Parent object url', 'A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.', 17);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_URL', 'Issue url', 'A link to the full screen issue details page', 17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'PARENT_OBJECT_URL', 'Parent object url', 'A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.', 18);

@../issue_pkg
@../issue_body

@update_tail
