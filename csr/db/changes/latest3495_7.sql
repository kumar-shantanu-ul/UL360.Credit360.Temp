-- Please update version.sql too -- this keeps clean builds in sync
define version=3495
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.REGION_TREE
ADD IS_SYSTEM_MANAGED NUMBER(1, 0) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.


-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.region_tree
SET is_system_managed = 1
WHERE is_fund = 1 OR region_tree_root_sid in (SELECT region_sid FROM csr.secondary_region_tree_ctrl);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_tree_pkg

@../region_tree_body
@../region_body

@update_tail
