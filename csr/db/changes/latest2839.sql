-- Please update version.sql too -- this keeps clean builds in sync
define version=2839
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Functions ***

-- *** Grants ***

-- ** Cross schema constraints ***

-- ** types **

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- ** New package grants **

-- *** Packages ***
@../scenario_run_pkg
@../scenario_run_body

@update_tail
