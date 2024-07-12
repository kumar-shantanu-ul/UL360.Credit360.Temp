-- Please update version.sql too -- this keeps clean builds in sync
define version=3464
define minor_version=2
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
UPDATE csr.capability 
SET name = 'Prioritise sheet values in sheets'
WHERE name = 'Priortise sheet values in sheets';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
