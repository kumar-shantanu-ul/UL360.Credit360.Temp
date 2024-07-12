-- Please update version.sql too -- this keeps clean builds in sync
define version=3386
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
	INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
	VALUES(66, 'Use new SP signature? CHECK WIKI BEFORE SETTING TO Y', 'y/n to', 3, 'n', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		-- Do nothing...
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail
