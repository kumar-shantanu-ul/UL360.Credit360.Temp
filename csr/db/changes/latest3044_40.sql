-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=40
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

@..\chain\dedupe_admin_pkg

@..\chain\company_dedupe_body

@update_tail
