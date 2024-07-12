-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=30
@update_header


-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.PRODUCT_HEADER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE CHAIN.PRODUCT_TAB_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.PRODUCT_HEADER(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	viewing_own_company    NUMBER(1) DEFAULT 0 NOT NULL,
	PAGE_COMPANY_COL_SID   NUMBER(10, 0),
	USER_COMPANY_COL_SID   NUMBER(10, 0),
	CONSTRAINT CHK_PRD_HEAD_VIEW_OWN_CMP_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT CHK_PRD_HEAD_VIEWING_OWN_TYPES CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id)),
	CONSTRAINT PRODUCT_HEADER_PK PRIMARY KEY (APP_SID, PRODUCT_HEADER_ID)
);

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;


CREATE TABLE CHAIN.PRODUCT_TAB(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	LABEL                  VARCHAR2(254)     NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	VIEWING_OWN_COMPANY    NUMBER(1) DEFAULT 0 NOT NULL,
	OPTIONS				   VARCHAR2(255),
	PAGE_COMPANY_COL_SID   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	FLOW_CAPABILITY_ID	   NUMBER(10) NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10) NULL,
	CONSTRAINT CHK_PRD_TAB_VIEW_OWN_CMP_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT CHK_PRD_TAB_VIEWING_OWN_TYPES CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id)),
	CONSTRAINT PRODUCT_TAB_PK PRIMARY KEY (APP_SID, PRODUCT_TAB_ID)
);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;



CREATE TABLE CSRIMP.CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)	NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)	NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)	NOT NULL,
	POS                    NUMBER(10, 0)	NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	viewing_own_company    NUMBER(1)		NOT NULL,
	PAGE_COMPANY_COL_SID   NUMBER(10, 0),
	USER_COMPANY_COL_SID   NUMBER(10, 0),
	CONSTRAINT PK_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_HEADER_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)	NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)	NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)	NOT NULL,
	POS                    NUMBER(10, 0)	NOT NULL,
	LABEL                  VARCHAR2(254)	NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	VIEWING_OWN_COMPANY    NUMBER(1)		NOT NULL,
	OPTIONS				   VARCHAR2(255),
	PAGE_COMPANY_COL_SID   NUMBER(10)		NULL,
	USER_COMPANY_COL_SID   NUMBER(10)		NULL,
	FLOW_CAPABILITY_ID	   NUMBER(10)		NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10) NULL,
	CONSTRAINT PK_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_TAB_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_HEADER UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


-- Alter tables


-- *** Grants ***
grant select, insert, update on chain.product_header to CSR;
grant select, insert, update on chain.product_tab to CSR;

grant select on chain.product_header_id_seq to CSR;
grant select on chain.product_tab_id_seq to CSR;

create index chain.ix_product_heade_plugin_id on chain.product_header (plugin_id);
create index chain.ix_product_tab_plugin_id on chain.product_tab (plugin_id);

grant select, insert, update, delete on csrimp.chain_product_header to tool_user;
grant select, insert, update, delete on csrimp.chain_product_tab to tool_user;
grant select, insert, update on chain.product_header to csrimp;
grant select, insert, update on chain.product_tab to csrimp;
grant select on chain.product_header_id_seq to csrimp;
grant select on chain.product_tab_id_seq to csrimp;

grant execute on chain.company_product_pkg to csr;
grant execute on chain.certification_pkg to csr;


-- ** Cross schema constraints ***
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;


ALTER TABLE chain.product_header ADD CONSTRAINT fk_product_hdr_page_comp_col 
	FOREIGN KEY (app_sid, page_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid);

ALTER TABLE chain.product_header ADD CONSTRAINT fk_product_hdr_user_comp_col
	FOREIGN KEY (app_sid, user_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_PAGE_COMP_COL 
	FOREIGN KEY (APP_SID, PAGE_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_USER_COMP_COL
	FOREIGN KEY (APP_SID, USER_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

	

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

--C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.product_id, tr.description product_name, cp.company_sid, c.name company_name, cp.product_type_id, pt.description product_type_name, ver.sku, cp.lookup_key, cp.last_edited_by, 
		   cu.full_name last_edited_name, last_edited_dtm, ver.product_active is_active,
		   0 weight_val, NULL weight_measure_conv_id, 'kg' weight_unit,
		   0 volume_val, NULL volume_measure_conv_id, 'cm3' volume_unit,
		   0 is_fully_certified, 1 is_owner, 0 is_supplier, 
       ver.version_number, ver.published
	  FROM chain.company_product cp
 LEFT JOIN csr.csr_user cu ON cp.last_edited_by = cu.csr_user_sid
	  JOIN chain.v$product_type pt ON cp.product_type_id = pt.product_type_id
	  JOIN chain.company c ON cp.company_sid = c.company_sid
	  JOIN chain.v$company_product_version ver ON cp.product_id = ver.product_id
	  JOIN chain.company_product_version_tr tr ON tr.product_id = cp.product_id AND tr.version_number = ver.version_number AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');


-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (18, 'Chain Product Header');
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (19, 'Chain Product Tab');

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 18, 'Chain Product Header', '/csr/site/chain/manageProduct/controls/ProductHeader.js', 'Chain.ManageProduct.ProductHeader', 'Credit360.Chain.Plugins.ProductHeader', 'Product header.');

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 19, 'Chain Product Details Tab', '/csr/site/chain/manageProduct/controls/ProductDetailsTab.js', 'Chain.ManageProduct.ProductDetailsTab', 'Credit360.Chain.Plugins.ProductDetails', 'Product Details tab.');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../schema_pkg
@../schema_body

@../csrimp/imp_pkg
@../csrimp/imp_body

@../chain/chain_body
@../chain/plugin_pkg
@../chain/plugin_body

@../chain/company_product_pkg
@../chain/company_product_body


@update_tail
