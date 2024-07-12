-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.deleg_plan ADD last_applied_dynamic NUMBER(1);
ALTER TABLE csrimp.deleg_plan ADD last_applied_dynamic NUMBER(1);

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
@../deleg_plan_pkg
@../deleg_plan_body
@../schema_body
@../csrimp/imp_body

@update_tail
