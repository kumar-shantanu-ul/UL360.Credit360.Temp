-- Please update version.sql too -- this keeps clean builds in sync
define version=3211
define minor_version=4
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
@../region_report_pkg
@../region_report_body
@../../../aspen2/cms/db/filter_body

@update_tail
