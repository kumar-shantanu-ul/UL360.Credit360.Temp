-- Please update version.sql too -- this keeps clean builds in sync
define version=1461
@update_header

INSERT INTO CSR.std_alert_type_param(std_alert_type_id, repeats, field_name, description, help_text, 
display_pos) 
VALUES (38, 0, 'COVER_START', 'Cover start', 'The date that the cover starts', 4);
INSERT INTO CSR.std_alert_type_param(std_alert_type_id, repeats, field_name, description, help_text, 
display_pos) 
VALUES (38, 0, 'COVER_END', 'Cover end', 'The date that the cover ends', 5);

@update_tail
