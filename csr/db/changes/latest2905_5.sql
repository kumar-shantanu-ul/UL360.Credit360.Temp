-- Please update version.sql too -- this keeps clean builds in sync
define version=2905
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
UPDATE chain.company_tab
   SET company_col_sid = supplier_col_sid
 WHERE company_col_sid IS NULL
   AND supplier_col_sid IS NOT NULL;

ALTER TABLE chain.company_tab RENAME COLUMN COMPANY_COL_SID TO PAGE_COMPANY_COL_SID;
ALTER TABLE chain.company_tab DROP CONSTRAINT FK_COMPANY_TAB_COMPANY_COL;
ALTER TABLE chain.company_tab DROP CONSTRAINT FK_COMPANY_TAB_SUPPLIER_COL;
ALTER TABLE chain.company_tab DROP COLUMN SUPPLIER_COL_SID;
ALTER TABLE chain.company_tab ADD USER_COMPANY_COL_SID NUMBER(10);


grant select on csr.audit_non_compliance_id_seq to csrimp;


ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT FK_COMPANY_TAB_PAGE_COMP_COL 
	FOREIGN KEY (APP_SID, PAGE_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID)
;
ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT FK_COMPANY_TAB_USER_COMP_COL
	FOREIGN KEY (APP_SID, USER_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID)
;
ALTER TABLE CSRIMP.CHAIN_COMPANY_TAB RENAME COLUMN COMPANY_COL_SID TO PAGE_COMPANY_COL_SID;
ALTER TABLE CSRIMP.CHAIN_COMPANY_TAB RENAME COLUMN SUPPLIER_COL_SID TO USER_COMPANY_COL_SID;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_body
@../chain/plugin_pkg
@../chain/plugin_body
@../csrimp/imp_body

@update_tail
