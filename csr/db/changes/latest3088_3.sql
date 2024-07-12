-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

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

@../compliance_body

@update_tail