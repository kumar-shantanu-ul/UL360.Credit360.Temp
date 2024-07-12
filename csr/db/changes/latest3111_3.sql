-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.company_product_tag (
	APP_SID								NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_ID							NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID						NUMBER(10, 0)    NOT NULL,
    TAG_ID								NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_COMPANY_PRODUCT_TAG PRIMARY KEY (APP_SID, PRODUCT_ID, TAG_GROUP_ID, TAG_ID),
	CONSTRAINT FK_COMPANY_PRODUCT_TAG_PROD FOREIGN KEY (APP_SID, PRODUCT_ID) REFERENCES CHAIN.COMPANY_PRODUCT (APP_SID, PRODUCT_ID)
);

CREATE TABLE chain.product_supplier_tag (
	APP_SID								NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_SUPPLIER_ID					NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID						NUMBER(10, 0)    NOT NULL,
    TAG_ID								NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_PRODUCT_SUPPLIER_TAG PRIMARY KEY (APP_SID, PRODUCT_SUPPLIER_ID, TAG_GROUP_ID, TAG_ID),
	CONSTRAINT FK_PRODUCT_SUPPLIER_TAG_PRSP FOREIGN KEY (APP_SID, PRODUCT_SUPPLIER_ID) REFERENCES CHAIN.PRODUCT_SUPPLIER (APP_SID, PRODUCT_SUPPLIER_ID)
);

-- Alter tables
ALTER TABLE csr.tag_group ADD (
	APPLIES_TO_CHAIN_PRODUCTS			NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	APPLIES_TO_CHAIN_PRODUCT_SUPPS		NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCTS IN (1, 0)),
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_S_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCT_SUPPS IN (1, 0))
);

ALTER TABLE csrimp.tag_group ADD (
	APPLIES_TO_CHAIN_PRODUCTS			NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	APPLIES_TO_CHAIN_PRODUCT_SUPPS		NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCTS IN (1, 0)),
    CONSTRAINT CHK_APPLIES_TO_CHAIN_PRD_S_1_0 CHECK (APPLIES_TO_CHAIN_PRODUCT_SUPPS IN (1, 0))
);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE chain.company_product_tag ADD (
	CONSTRAINT FK_COMPANY_PRODUCT_TAG_TAG FOREIGN KEY (APP_SID, TAG_GROUP_ID, TAG_ID) REFERENCES CSR.TAG_GROUP_MEMBER (APP_SID, TAG_GROUP_ID, TAG_ID)
);

ALTER TABLE chain.product_supplier_tag ADD (
	CONSTRAINT FK_PRODUCT_SUPPLIER_TAG_TAG FOREIGN KEY (APP_SID, TAG_GROUP_ID, TAG_ID) REFERENCES CSR.TAG_GROUP_MEMBER (APP_SID, TAG_GROUP_ID, TAG_ID)
);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Chain.Plugins.ProductSupplierDetailsDto'
	 WHERE js_class = 'Chain.ManageProduct.ProductSupplierDetailsTab';

	COMMIT;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../tag_pkg
@../chain/company_product_pkg
@../chain/product_report_pkg
@../chain/product_supplier_report_pkg

@../tag_body
@../chain/company_product_body
@../chain/product_report_body
@../chain/product_supplier_report_body

@../schema_body
@../csrimp/imp_body

@update_tail
