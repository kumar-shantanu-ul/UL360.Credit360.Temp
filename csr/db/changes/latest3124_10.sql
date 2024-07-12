-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index csr.ix_secondary_reg_user_sid on csr.secondary_region_tree_ctrl (app_sid, user_sid);
create index csr.ix_secondary_reg_region_root_s on csr.secondary_region_tree_ctrl (app_sid, region_root_sid);

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

@update_tail
