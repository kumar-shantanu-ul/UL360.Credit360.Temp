define version=3014
define minor_version=0
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
@..\..\..\aspen2\cms\db\filter_pkg

@..\..\..\aspen2\cms\db\filter_body

@update_tail
