-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.import_source
  ADD override_company_active NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.chain_import_source
  ADD override_company_active NUMBER(1, 0) NOT NULL;

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
@../chain/chain_pkg
@../chain/dedupe_admin_pkg

@../chain/dedupe_admin_body
@../chain/company_dedupe_body
@../schema_body
@../csrimp/imp_body

@update_tail
