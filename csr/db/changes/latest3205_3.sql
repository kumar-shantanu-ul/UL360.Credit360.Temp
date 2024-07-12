-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METERING_OPTIONS ADD (
	PROC_API_KEY			VARCHAR2(256)
);

--
-- NOTE: NO CSRIMP FOR THE API KEY - WE DON'T WANT THE CLONED SITE HAVING ACCESS TO THE API USING THE SOURCE HOST 
-- CREDENTIALS, BESIDES WHICH THE KEY WILL NOT MATCH THE NEW HOST AND WILL NEED TO BE CREATED FOR THE NEW SITE.

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
@../meter_pkg
@../meter_body

@update_tail
