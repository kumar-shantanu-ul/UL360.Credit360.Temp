-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=25
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
@..\..\..\aspen2\db\utils_pkg
@..\..\..\aspen2\db\utils_body
@..\portlet_body

@update_tail
