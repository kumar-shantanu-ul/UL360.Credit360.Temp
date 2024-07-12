-- Please update version.sql too -- this keeps clean builds in sync
define version=3421
define minor_version=7
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
	VALUES (29, 0, 'ACTION_SHEET_URL', 'Action sheet link', 'A hyperlink to the sheet where the data change request was made.', 13);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../delegation_body

@update_tail
