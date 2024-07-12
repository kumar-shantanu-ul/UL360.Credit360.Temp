-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.SECONDARY_REGION_TREE_CTRL MODIFY REDUCE_CONTENTION	DEFAULT NULL;
ALTER TABLE CSRIMP.SECONDARY_REGION_TREE_CTRL MODIFY APPLY_DELEG_PLANS	DEFAULT NULL;


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
