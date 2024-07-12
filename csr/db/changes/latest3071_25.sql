-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
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
@../property_report_pkg

@../chain/product_report_pkg
@../chain/company_filter_pkg

@../../../aspen2/cms/db/filter_pkg

@../property_report_body

@../chain/product_report_body
@../chain/company_filter_body

@../../../aspen2/cms/db/filter_body

@update_tail
