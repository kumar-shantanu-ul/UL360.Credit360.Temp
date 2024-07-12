-- Please update version.sql too -- this keeps clean builds in sync
define version=3382
define minor_version=6
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

@../delegation_body
@../factor_set_group_body
@../indicator_body
@../region_body
@../region_picker_body
@../region_tree_body

@update_tail
