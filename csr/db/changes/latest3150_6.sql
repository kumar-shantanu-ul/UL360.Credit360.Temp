-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.target_dashboard_ind_member DROP COLUMN description;
ALTER TABLE csr.target_dashboard_reg_member DROP COLUMN description;

ALTER TABLE csrimp.target_dashboard_ind_member DROP COLUMN description;
ALTER TABLE csrimp.target_dashboard_reg_member DROP COLUMN description;

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
@../target_dashboard_pkg

@../indicator_body
@../region_body
@../schema_body
@../target_dashboard_body

@../csrimp/imp_body

@update_tail
