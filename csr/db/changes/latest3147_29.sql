-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
--delete data which lives in non live environments due to mindtree bug in 3066_15.sql

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../region_body
@update_tail
