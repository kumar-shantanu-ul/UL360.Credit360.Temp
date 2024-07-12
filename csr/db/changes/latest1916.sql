-- Please update version.sql too -- this keeps clean builds in sync
define version=1916
@update_header

BEGIN
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 15);

EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
		
END;
/
@update_tail
