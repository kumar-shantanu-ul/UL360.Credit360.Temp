-- Please update version.sql too -- this keeps clean builds in sync
define version=0
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

-- Fix up the data broken by the defect. The issue is that data with an error
-- code written against it - eg, mixed units, divide by zero, etc - has been
-- written with a val number of 0 rather than null. There is a check in the 
-- Value class (C#) that checks that value with an error code must have a null
-- val number.
BEGIN
	FOR r IN (
		SELECT app_sid, val_id
		  FROM csr.val 
		 WHERE val_number = 0  
		   AND error_code IS NOT NULL 
		   AND error_code != 0
	)
	LOOP
		UPDATE csr.val
		   SET val_number = NULL,
			   entry_val_number = NULL
		 WHERE app_sid = r.app_sid
		   AND val_id = r.val_id;
	END LOOP;

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
