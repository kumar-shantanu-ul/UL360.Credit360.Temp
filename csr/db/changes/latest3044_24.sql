-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=24
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
@../templated_report_pkg
@../region_picker_pkg

@../templated_report_body
@../region_picker_body
@../region_body

@update_tail
