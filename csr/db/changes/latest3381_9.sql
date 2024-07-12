-- Please update version.sql too -- this keeps clean builds in sync
define version=3381
define minor_version=9
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
@../initiative_pkg
@../initiative_body
@../initiative_grid_body
@../initiative_report_body

@update_tail
