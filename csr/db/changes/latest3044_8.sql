-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_item_region ADD out_of_scope NUMBER (1, 0) DEFAULT 0 NOT NULL;
-- ALTER TABLE csr.compliance_item_region ADD CONSTRAINT CHK_COMPLIANCE_ITEM_REGION_OUT_OF_SCOPE_1_0 CHECK (out_of_scope IN (0,1))

ALTER TABLE csrimp.compliance_item_region ADD out_of_scope NUMBER (1, 0) NOT NULL;
-- ALTER TABLE csrimp.compliance_item_region ADD CONSTRAINT CHK_COMPLIANCE_ITEM_REGION_OUT_OF_SCOPE_1_0 CHECK (out_of_scope IN (0,1))

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
@../schema_body
@../csrimp/imp_body
@../compliance_body

@update_tail
