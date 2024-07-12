-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CHAIN.PRODUCT_SUPPLIER_TAB_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.PRODUCT_SUPPLIER_TAB(
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_SUPPLIER_TAB_ID     NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID					NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID				NUMBER(10, 0)     NOT NULL,
	POS							NUMBER(10, 0)     NOT NULL,
	LABEL						VARCHAR2(254)     NOT NULL,
	VIEWING_OWN_PRODUCT			NUMBER(1),
	VIEWING_AS_SUPPLIER			NUMBER(1),
	CONSTRAINT CK_PRD_SUP_TAB_VW_OWN_CMP_1_0 CHECK (VIEWING_OWN_PRODUCT IS NULL OR VIEWING_OWN_PRODUCT IN (1, 0)),
	CONSTRAINT CK_PRD_SUP_TAB_VW_AS_SUPP_1_0 CHECK (VIEWING_AS_SUPPLIER IS NULL OR VIEWING_AS_SUPPLIER IN (1, 0)),
	CONSTRAINT PRODUCT_SUPPLIER_TAB_PK PRIMARY KEY (APP_SID, PRODUCT_SUPPLIER_TAB_ID)
);

CREATE TABLE CHAIN.PROD_SUPP_TAB_PRODUCT_TYPE (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_SUPPLIER_TAB_ID     NUMBER(10, 0)     NOT NULL,
	PRODUCT_TYPE_ID				NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PROD_SUPP_TAB_PRODUCT_TYPE PRIMARY KEY (APP_SID, PRODUCT_SUPPLIER_TAB_ID, PRODUCT_TYPE_ID)
);

ALTER TABLE CHAIN.PROD_SUPP_TAB_PRODUCT_TYPE ADD CONSTRAINT FK_PROD_SUPP_TAB_PROD_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_SUPPLIER_TAB_ID)
    REFERENCES CHAIN.PRODUCT_SUPPLIER_TAB(APP_SID, PRODUCT_SUPPLIER_TAB_ID)
;

ALTER TABLE CHAIN.PROD_SUPP_TAB_PRODUCT_TYPE ADD CONSTRAINT FK_PROD_SUPP_TAB_PROD_TYPE_PT
    FOREIGN KEY (APP_SID, PRODUCT_TYPE_ID)
    REFERENCES CHAIN.PRODUCT_TYPE(APP_SID, PRODUCT_TYPE_ID)
;

CREATE TABLE CHAIN.PROD_SUPP_TAB_COMPANY_TYPE (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_SUPPLIER_TAB_ID     NUMBER(10, 0)     NOT NULL,
	COMPANY_TYPE_ID				NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PROD_SUPP_TAB_COMPANY_TYPE PRIMARY KEY (APP_SID, PRODUCT_SUPPLIER_TAB_ID, COMPANY_TYPE_ID)
);

ALTER TABLE CHAIN.PROD_SUPP_TAB_COMPANY_TYPE ADD CONSTRAINT FK_PROD_SUPP_TAB_COMP_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_SUPPLIER_TAB_ID)
    REFERENCES CHAIN.PRODUCT_SUPPLIER_TAB(APP_SID, PRODUCT_SUPPLIER_TAB_ID)
;

ALTER TABLE CHAIN.PROD_SUPP_TAB_COMPANY_TYPE ADD CONSTRAINT FK_PROD_SUPP_TAB_COMP_TYPE_CT
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE chain.capability SET capability_name = 'Product suppliers of suppliers' WHERE capability_name = 'Product suppliers' AND capability_type_id = 3;
UPDATE chain.capability SET capability_name = 'Add product suppliers of suppliers' WHERE capability_name = 'Add supplier to products' AND capability_type_id = 3;

BEGIN
	BEGIN
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 200, 'Business relationship changes');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 201, 'Product type changes');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 202, 'Company product changes');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (20, 'Chain Product Supplier Tab');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
			values (94, 19, 'Chain Product Suppliers Tab', '/csr/site/chain/manageProduct/controls/ProductSuppliersTab.js', 'Chain.ManageProduct.ProductSuppliersTab', 'Credit360.Chain.Plugins.ProductSuppliersDto', 'This tab shows the suppliers who contribute to a product.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
			values (95, 20, 'Chain Product Supplier Details Tab', '/csr/site/chain/manageProduct/controls/ProductSupplierDetailsTab.js', 'Chain.ManageProduct.ProductSupplierDetailsTab', 'Credit360.Plugins.EmptyDto', 'This tab shows the suppliers who contribute to a product.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../chain/chain_pkg
@../chain/company_product_pkg
@../chain/plugin_pkg

@../chain/company_product_body
@../chain/product_report_body
@../chain/plugin_body

@update_tail
