-- Please update version.sql too -- this keeps clean builds in sync
define version=3421
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (4, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (57, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
