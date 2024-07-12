-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=11
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
@../chain/company_filter_pkg
@../chain/product_report_pkg
@../chain/product_supplier_report_pkg

@../audit_report_body
@../chain/activity_report_body
@../chain/business_rel_report_body
@../chain/company_filter_body
@../chain/certification_report_body
@../chain/product_report_body
@../chain/product_supplier_report_body

@update_tail
