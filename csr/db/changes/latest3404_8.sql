-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=8
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
UPDATE csr.util_script_param
   SET param_hint = 'SP called when importing child data for responses. Type "NULL" or whitespace if no child helper SP is needed',
	   param_name = 'Child Helper SP (Type "NULL" or whitespace if no child helper SP is needed)'
 WHERE util_script_id = 66
   AND pos = 4;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_body

@update_tail
