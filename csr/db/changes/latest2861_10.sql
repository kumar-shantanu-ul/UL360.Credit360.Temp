-- Please update version.sql too -- this keeps clean builds in sync
define version=2861
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_tab ADD (
	company_col_sid		NUMBER(10) NULL,
	supplier_col_sid	NUMBER(10) NULL
);

--plus csrimp updates
ALTER TABLE csrimp.chain_company_tab ADD (
	company_col_sid		NUMBER(10) NULL,
	supplier_col_sid	NUMBER(10) NULL
);
	
-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE chain.company_tab ADD CONSTRAINT fk_company_tab_company_col FOREIGN KEY (app_sid, company_col_sid) REFERENCES cms.tab_column(app_sid, column_sid);	
ALTER TABLE chain.company_tab ADD CONSTRAINT fk_company_tab_supplier_col FOREIGN KEY (app_sid, supplier_col_sid) REFERENCES cms.tab_column(app_sid, column_sid);	

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
UPDATE chain.company_tab target 
   SET target.company_col_sid = (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
		  FROM csr.plugin p
		  JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
		  JOIN cms.tab t ON t.tab_sid = p.tab_sid 
						AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'COMPANY_SID'
		 WHERE p.plugin_type_id = 10 
		   AND p.js_class = 'Chain.ManageCompany.CmsTab' 
		   AND p.form_path IS NOT NULL
		) source
	WHERE source.company_tab_id = target.company_tab_id
)
WHERE EXISTS (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
	      FROM csr.plugin p
	      JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
	      JOIN cms.tab t ON t.tab_sid = p.tab_sid 
						AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'COMPANY_SID'
	     WHERE p.plugin_type_id = 10 
	       AND p.js_class = 'Chain.ManageCompany.CmsTab' 
	       AND p.form_path IS NOT NULL
		) source
	 WHERE source.company_tab_id = target.company_tab_id
);

UPDATE chain.company_tab target 
   SET target.supplier_col_sid = (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
		  FROM csr.plugin p
		  JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
		  JOIN cms.tab t ON t.tab_sid = p.tab_sid AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'SUPPLIER_SID'
		 WHERE p.plugin_type_id = 10 
		   AND p.js_class = 'Chain.ManageCompany.CmsTab' 
		   AND p.form_path IS NOT NULL
		) source
	WHERE source.company_tab_id = target.company_tab_id
)
WHERE EXISTS (
	SELECT source.column_sid 
	  FROM (
		SELECT tc.column_sid, ct.company_tab_id
	      FROM csr.plugin p
	      JOIN chain.company_tab ct ON ct.plugin_id = p.plugin_id AND ct.app_sid = p.app_sid
	      JOIN cms.tab t ON t.tab_sid = p.tab_sid AND t.app_sid = p.app_sid
		  JOIN cms.tab_column tc ON tc.tab_sid = t.tab_sid AND tc.app_sid = p.app_sid AND tc.oracle_column = 'SUPPLIER_SID'
	     WHERE p.plugin_type_id = 10 
	       AND p.js_class = 'Chain.ManageCompany.CmsTab' 
	       AND p.form_path IS NOT NULL
		) source
	 WHERE source.company_tab_id = target.company_tab_id
);

-- ** New package grants **

-- *** Packages ***
@../chain/plugin_pkg
@../chain/plugin_body
@../schema_body
@../csrimp/imp_body


@update_tail
