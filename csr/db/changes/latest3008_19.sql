-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- remove dupes before adding unique constraint

-- *** Grants ***
grant select,insert,update,delete on csrimp.incident_type to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
