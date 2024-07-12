-- Please update version.sql too -- this keeps clean builds in sync
define version=2853
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\energy_star_pkg
@..\energy_star_job_pkg

@..\energy_star_body
@..\energy_star_job_body

@update_tail
