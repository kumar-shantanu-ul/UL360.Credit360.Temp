-- Please update version.sql too -- this keeps clean builds in sync
define version=500
@update_header

BEGIN
	INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (4, 0, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 11);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
