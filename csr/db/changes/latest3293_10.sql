-- Please update version.sql too -- this keeps clean builds in sync
define version=3293
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX csr.ix_compliance_req_reg_req ON csr.compliance_req_reg (app_sid, requirement_id);

CREATE INDEX csr.ix_ci_desc_ci ON csr.compliance_item_description (app_sid, compliance_item_id);
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
