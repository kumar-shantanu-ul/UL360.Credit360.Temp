-- Please update version.sql too -- this keeps clean builds in sync
define version=3305
define minor_version=2
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
@..\superadmin_api_pkg

@..\superadmin_api_body

GRANT EXECUTE ON csr.superadmin_api_pkg TO support_users;

@update_tail
