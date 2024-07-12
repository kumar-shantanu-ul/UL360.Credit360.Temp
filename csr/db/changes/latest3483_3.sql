-- Please update version.sql too -- this keeps clean builds in sync
define version=3483
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER DROP CONSTRAINT CK_SITE_TYPE;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_SITE_TYPE CHECK (SITE_TYPE IN ('Customer', 'Prospect', 'Sandbox', 'Staff', 'Retired', 'AutomationTest'));

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
@../csr_app_body

@update_tail
