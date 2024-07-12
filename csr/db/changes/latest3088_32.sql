-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- 0 = chain.filter_pkg.NULL_FILTER_ALL
ALTER TABLE chain.tt_filter_date_range 
  ADD NULL_FILTER NUMBER(10) DEFAULT 0 NOT NULL; 

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
@../chain/filter_pkg

@../../../aspen2/cms/db/filter_body
@../audit_report_body
@../chain/company_filter_body
@../chain/filter_body
@../compliance_library_report_body
@../csrimp/imp_body
@../initiative_report_body
@../meter_list_body
@../non_compliance_report_body
@../permit_report_body
@../property_report_body
@../region_report_body

@update_tail
