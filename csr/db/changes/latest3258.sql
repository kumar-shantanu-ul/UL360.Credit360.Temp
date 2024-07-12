-- Please update version.sql too -- this keeps clean builds in sync
define version=3258
define minor_version=0
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
	VALUES (3, 1, 'ACTION_SHEET_URL', 'Action sheet link', 'A hyperlink that takes you to the sheet with the next available action.', 12);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../sheet_pkg
@../sheet_body

@update_tail
