-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=8
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
@../donations/donation_body
@../donations/donation_pkg
@../supplier/company_body
@../supplier/company_pkg
@../supplier/product_body
@../supplier/product_pkg

-- XXX: these are client specific, need to put them straight in the release script
-- they are for boots supplier which has no client specific schema -- it uses SUPPLIER
-- @../supplier/greenTick/product_info_body
-- @../supplier/greenTick/product_info_pkg


@update_tail
