-- Please update version.sql too -- this keeps clean builds in sync
define version=3368
define minor_version=1
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
BEGIN
	EXECUTE IMMEDIATE 'DROP PACKAGE csr.latest_xxx_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

@update_tail
