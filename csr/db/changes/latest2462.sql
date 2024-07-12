-- Please update version.sql too -- this keeps clean builds in sync
define version=2462
@update_header

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'RELATED_OBJECT_NAME', 'Related Object Name (e.g Non-Compliance name)', 'For audit issues this field contains the name of the non-compliance', 18);

@..\issue_pkg
@..\issue_body

@update_tail
