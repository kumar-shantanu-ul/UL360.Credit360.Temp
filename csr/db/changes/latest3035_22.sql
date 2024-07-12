-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../approval_dashboard_pkg
@../portlet_pkg

@../approval_dashboard_body
@../portlet_body
@../portal_dashboard_body

@update_tail
