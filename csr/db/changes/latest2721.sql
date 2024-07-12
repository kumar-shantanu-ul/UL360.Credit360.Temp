-- Please update version.sql too -- this keeps clean builds in sync
define version=2721
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
-- do nothing, this was unneccessary latest script
--@../region_pkg
--@../region_body
--@../role_body

@update_tail
