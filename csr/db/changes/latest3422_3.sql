-- Please update version.sql too -- this keeps clean builds in sync
define version=3422
define minor_version=3
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
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Initiative Temp Saving Apportion', 0, 'Initiatives with temp savings should apportion over partially spanned metric Initiative period intervals.');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../initiative_aggr_body

@update_tail
