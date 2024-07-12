-- Please update version too -- this keeps clean builds in sync
define version=3093
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
@../chain/company_filter_pkg
@../chain/company_request_report_pkg
@../chain/dedupe_proc_record_report_pkg
@../chain/product_report_pkg
@../meter_list_pkg
@../permit_report_pkg
@../property_report_pkg
@../user_report_pkg

@../chain/company_filter_body
@../chain/company_request_report_body
@../chain/dedupe_proc_record_report_body
@../chain/product_report_body
@../meter_list_body
@../permit_report_body
@../property_report_body
@../user_report_body

@update_tail
