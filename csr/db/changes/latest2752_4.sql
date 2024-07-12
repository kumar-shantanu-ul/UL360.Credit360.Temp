-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=4
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
@..\audit_pkg
@..\audit_body
@..\energy_star_job_body

@update_tail
