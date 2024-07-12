-- Please update version.sql too -- this keeps clean builds in sync
define version=3172
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
@../chain/company_product_body
@../chain/product_report_body
@../chain/product_supplier_report_body


@update_tail
