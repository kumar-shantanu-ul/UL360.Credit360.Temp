-- Please update version.sql too -- this keeps clean builds in sync
define version=3309
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
@../region_set_body

@update_tail
