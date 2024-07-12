-- Please update version.sql too -- this keeps clean builds in sync
define version=1136
@update_header

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (40, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);
	
@..\donations\funding_commitment_body
	
@update_tail

