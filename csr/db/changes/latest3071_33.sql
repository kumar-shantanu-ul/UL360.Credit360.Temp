-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=33
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
@../chain/certification_report_body
@../chain/product_report_body
@../initiative_report_body
@../meter_list_body
@../property_report_body
@../user_report_body

@update_tail
