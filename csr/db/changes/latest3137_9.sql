-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
index_not_exists EXCEPTION;
PRAGMA EXCEPTION_INIT(index_not_exists, -1418);
BEGIN
	EXECUTE IMMEDIATE 'DROP INDEX CSR.UK_FACTOR_2';
EXCEPTION
	WHEN index_not_exists THEN NULL;
END;
/
CREATE UNIQUE INDEX CSR.UK_FACTOR_2 ON CSR.FACTOR (APP_SID, NVL(STD_FACTOR_ID, -FACTOR_ID), REGION_SID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_body

@update_tail
