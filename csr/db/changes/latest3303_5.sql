-- Please update version.sql too -- this keeps clean builds in sync
define version=3303
define minor_version=5
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
@../chain/product_metric_report_pkg
@../chain/prdct_supp_mtrc_report_pkg

@../chain/activity_report_body
@../chain/prdct_supp_mtrc_report_body
@../chain/product_metric_report_body

@update_tail
