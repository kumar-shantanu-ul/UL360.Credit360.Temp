-- Please update version.sql too -- this keeps clean builds in sync
define version=3451
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
@../factor_pkg
@../factor_set_group_pkg
 
@../factor_body
@../factor_set_group_body

@update_tail
