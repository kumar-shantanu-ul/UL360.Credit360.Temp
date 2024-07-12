-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_item_rollout
  ADD SUPPRESS_ROLLOUT NUMBER(1,0) DEFAULT 0;

ALTER TABLE csrimp.compliance_item_rollout
  ADD SUPPRESS_ROLLOUT NUMBER(1,0) DEFAULT 0;

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
@../compliance_pkg
@../csrimp/imp_pkg

@../compliance_body
@../csrimp/imp_body

@update_tail
