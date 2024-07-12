-- Please update version.sql too -- this keeps clean builds in sync
define version=3402
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
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Legacy Chart Wrappers (UD-13034)', 0, 'Legacy: Use legacy chart wrapper generation.');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
