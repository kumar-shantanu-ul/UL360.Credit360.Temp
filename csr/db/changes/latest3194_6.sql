-- Please update version.sql too -- this keeps clean builds in sync
define version=3194
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.osha_mapping DROP CONSTRAINT PK_OSHA_MAPPING;
ALTER TABLE csr.osha_mapping ADD CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID);

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
@../osha_body

@update_tail
