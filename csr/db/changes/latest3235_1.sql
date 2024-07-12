-- Please update version.sql too -- this keeps clean builds in sync
define version=3235
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
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Compliance Languages', 0, 'Enable compliance languages feature.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_pkg

@../compliance_body

@update_tail
