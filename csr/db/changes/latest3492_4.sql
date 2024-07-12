-- Please update version.sql too -- this keeps clean builds in sync
define version=3492
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../unit_test_pkg

@../automated_export_body
@../unit_test_body

@update_tail
