-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.dedupe_staging_link ADD staging_source_lookup_col_sid	NUMBER (10, 0);
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD staging_source_lookup_col_sid	NUMBER (10, 0);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_source_col
	FOREIGN KEY (app_sid, staging_tab_sid, staging_source_lookup_col_sid)
	REFERENCES cms.tab_column (app_sid, tab_sid, column_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_dedupe_pkg
@../chain/dedupe_admin_pkg

@../schema_body
@../chain/company_dedupe_body
@../chain/dedupe_admin_body
@../csrimp/imp_body

@update_tail
