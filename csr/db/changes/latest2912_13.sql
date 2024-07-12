-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
-- Missing in package_grants but in latest936.
GRANT EXECUTE ON csr.energy_star_account_pkg TO security;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\energy_star_pkg
@@..\energy_star_body

@update_tail
