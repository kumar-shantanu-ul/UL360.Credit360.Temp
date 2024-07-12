-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer DROP COLUMN dynamic_deleg_plans_batched;
ALTER TABLE csrimp.customer DROP COLUMN dynamic_deleg_plans_batched;


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
@../region_pkg
@../deleg_plan_pkg

@../deleg_plan_body
@../property_body
@../region_body
@../region_tree_body
@../supplier_body
@../tag_body
@../schema_body
@../csrimp/imp_body

@update_tail
