-- Please update version.sql too -- this keeps clean builds in sync
define version=3181
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.delegation_ind
 DROP CONSTRAINT CK_META_ROLE;

ALTER TABLE csrimp.delegation_ind
  ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN('MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'COMP_TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL', 'DP_NOT_CHANGED_COUNT', 'ACC_TOTAL_DP')) ENABLE;


ALTER TABLE csr.delegation_ind
 DROP CONSTRAINT CK_META_ROLE;

ALTER TABLE csr.delegation_ind
  ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN('MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'COMP_TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL', 'DP_NOT_CHANGED_COUNT', 'ACC_TOTAL_DP')) ENABLE;

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

@update_tail
