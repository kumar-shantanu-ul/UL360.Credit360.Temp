-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=2
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
@../quick_survey_report_pkg
@../quick_survey_report_body
@../audit_report_pkg
@../audit_report_body
@../chain/activity_report_pkg
@../chain/activity_report_body
@../chain/bsci_2009_audit_report_pkg
@../chain/bsci_2009_audit_report_body
@../chain/bsci_2014_audit_report_pkg
@../chain/bsci_2014_audit_report_body
@../chain/bsci_ext_audit_report_pkg
@../chain/bsci_ext_audit_report_body
@../chain/bsci_supplier_report_pkg
@../chain/bsci_supplier_report_body
@../chain/business_rel_report_pkg
@../chain/business_rel_report_body
@../chain/certification_report_pkg
@../chain/certification_report_body
@../chain/company_filter_pkg
@../chain/company_filter_body
@../chain/company_request_report_pkg
@../chain/company_request_report_body
@../chain/dedupe_proc_record_report_pkg
@../chain/dedupe_proc_record_report_body
@../chain/prdct_supp_mtrc_report_pkg
@../chain/prdct_supp_mtrc_report_body
@../chain/product_metric_report_pkg
@../chain/product_metric_report_body
@../chain/product_report_pkg
@../chain/product_report_body
@../chain/product_supplier_report_pkg
@../chain/product_supplier_report_body
@../compliance_library_report_pkg
@../compliance_library_report_body
@../compliance_register_report_pkg
@../compliance_register_report_body
@../initiative_report_pkg
@../initiative_report_body
@../issue_report_pkg
@../issue_report_body
@../meter_list_pkg
@../meter_list_body
@../meter_report_pkg
@../meter_report_body
@../non_compliance_report_pkg
@../non_compliance_report_body
@../permit_report_pkg
@../permit_report_body
@../property_report_pkg
@../property_report_body
@../region_report_pkg
@../region_report_body
@../user_report_pkg
@../user_report_body

@update_tail
