-- Please update version.sql too -- this keeps clean builds in sync
define version=3158
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.dedupe_mapping ADD fill_nulls_under_ui_source NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_fill_nulls_zero_one CHECK (fill_nulls_under_ui_source IN (0,1));

ALTER TABLE csrimp.chain_dedupe_mapping ADD fill_nulls_under_ui_source NUMBER(1);

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
@..\chain\dedupe_admin_pkg

@..\chain\dedupe_admin_body
@..\chain\company_dedupe_body

@..\csrimp\imp_body

@..\schema_body

@update_tail
