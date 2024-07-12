-- Please update version too -- this keeps clean builds in sync
define version=2869
define minor_version=0
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
@..\division_pkg
@..\division_body
@..\logon_policy_pkg
@..\logon_policy_body

@update_tail
