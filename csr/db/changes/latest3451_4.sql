-- Please update version.sql too -- this keeps clean builds in sync
define version=3451
define minor_version=4
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
INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Prioritise sheet values in sheets', 0, 'When allowed: Use and show value from sheet if available, otherwise value from scrag. When not allowed: use scrag value first, if available');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
