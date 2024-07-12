-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=12
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
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION)
	VALUES ('Adjust period labels to start month', 0, 'Fix period labels for default period set with non January start month');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../period_body

@update_tail
