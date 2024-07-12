-- Please update version.sql too -- this keeps clean builds in sync
define version=3178
define minor_version=14
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
@..\deleg_plan_pkg
@..\unit_test_pkg

@..\deleg_plan_body
@..\unit_test_body

@update_tail
