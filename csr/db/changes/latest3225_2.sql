-- Please update version.sql too -- this keeps clean builds in sync
define version=3225
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
