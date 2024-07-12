-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_header ADD (
	page_company_col_sid	NUMBER (10, 0),
	user_company_col_sid	NUMBER (10, 0)
);

ALTER TABLE csrimp.chain_company_header ADD (
	page_company_col_sid	NUMBER (10, 0),
	user_company_col_sid	NUMBER (10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE chain.company_header ADD CONSTRAINT fk_company_hdr_page_comp_col 
	FOREIGN KEY (app_sid, page_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid)
;

ALTER TABLE chain.company_header ADD CONSTRAINT fk_company_hdr_user_comp_col
	FOREIGN KEY (app_sid, user_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid)
;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/plugin_pkg

@../audit_body
@../plugin_body
@../schema_body
@../chain/plugin_body
@../csrimp/imp_body

@update_tail
