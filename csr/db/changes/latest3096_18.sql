-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables


-- SETTINGS FOR PRODUCT IMPORTER
CREATE SEQUENCE CSR.AUTO_IMP_PRODUCT_SETTINGS_SEQ;

CREATE TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUTO_IMP_PRODUCT_SETTINGS_ID	NUMBER(10) NOT NULL,
	AUTOMATED_IMPORT_CLASS_SID		NUMBER(10) NOT NULL,
	STEP_NUMBER						NUMBER(10) NOT NULL,
	MAPPING_XML						SYS.XMLTYPE NOT NULL,
	AUTOMATED_IMPORT_FILE_TYPE_ID	NUMBER(10) NOT NULL,
	DSV_SEPARATOR					CHAR,
	DSV_QUOTES_AS_LITERALS			NUMBER(1),
	EXCEL_WORKSHEET_INDEX			NUMBER(10),
	ALL_OR_NOTHING					NUMBER(1),
	HEADER_ROW						NUMBER(10),
	CONCATENATOR					CHAR,
	DEFAULT_COMPANY_SID				NUMBER(10),
	COMPANY_MAPPING_TYPE_ID			NUMBER(10),
	PRODUCT_MAPPING_TYPE_ID			NUMBER(10) NOT NULL,
	PRODUCT_TYPE_MAPPING_TYPE_ID	NUMBER(10) NOT NULL,
	CMS_MAPPING_XML					SYS.XMLTYPE,
	TAB_SID							NUMBER(10),
	CONSTRAINT PK_AUTO_IMP_PRODUCT_SETTINGS PRIMARY KEY (AUTO_IMP_PRODUCT_SETTINGS_ID),
	CONSTRAINT UK_AUTO_IMP_PRODUCT_SETTINGS UNIQUE (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER),
	CONSTRAINT CK_AUTO_IMP_PRODUCT_SETTINGS CHECK (
		(COMPANY_MAPPING_TYPE_ID IS NULL AND DEFAULT_COMPANY_SID IS NOT NULL)
		OR COMPANY_MAPPING_TYPE_ID IS NOT NULL),
	CONSTRAINT CK_AUTO_IMP_PRODUCT_CMS CHECK (
		(CMS_MAPPING_XML IS NULL AND TAB_SID IS NULL)
		OR (CMS_MAPPING_XML IS NOT NULL AND TAB_SID IS NOT NULL))
);

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_SETTINGS_STEP
	FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
	REFERENCES CSR.AUTOMATED_IMPORT_CLASS_STEP(APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER);

ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_SET_FILETYPE
	FOREIGN KEY (AUTOMATED_IMPORT_FILE_TYPE_ID)
	REFERENCES CSR.AUTOMATED_IMPORT_FILE_TYPE(AUTOMATED_IMPORT_FILE_TYPE_ID);

ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_PROD_MAP
	FOREIGN KEY (PRODUCT_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);

ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_COMP_MAP
	FOREIGN KEY (COMPANY_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);

ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_TYPE_MAP
	FOREIGN KEY (PRODUCT_TYPE_MAPPING_TYPE_ID)
	REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);

-- Cross schema constraint
ALTER TABLE CSR.AUTO_IMP_PRODUCT_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_PROD_CMS_TAB
	FOREIGN KEY (APP_SID, TAB_SID)
	REFERENCES CMS.TAB(APP_SID, TAB_SID);

create index csr.ix_auto_imp_prod_automated_imp on csr.auto_imp_product_settings (automated_import_file_type_id);
create index csr.ix_auto_imp_prod_product_type_ on csr.auto_imp_product_settings (product_type_mapping_type_id);
create index csr.ix_auto_imp_prod_tab_sid on csr.auto_imp_product_settings (app_sid, tab_sid);
create index csr.ix_auto_imp_prod_company_mappi on csr.auto_imp_product_settings (company_mapping_type_id);
create index csr.ix_auto_imp_prod_product_mappi on csr.auto_imp_product_settings (product_mapping_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
	VALUES (7, 'Compliance product importer', 'Credit360.ExportImport.Automated.Import.Importers.ProductImporter.ProductImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../chain/company_pkg
@../chain/company_product_pkg
@../chain/product_type_pkg

@../automated_import_body
@../chain/company_body
@../chain/company_product_body
@../chain/product_type_body

@update_tail
