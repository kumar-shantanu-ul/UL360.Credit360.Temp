-- Please update version.sql too -- this keeps clean builds in sync
--define version=xxxx
--define minor_version=x
--@update_header

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

UPDATE csr.deleg_plan_deleg_region SET region_type = NULL WHERE region_type = -1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

--@update_tail
