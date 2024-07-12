-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=13
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
@../audit_migration_pkg

@../util_script_body
@../audit_migration_body

@update_tail
