define rap5_version=2
@update_header

CREATE GLOBAL TEMPORARY TABLE TT_ID
( 
	ID							NUMBER(10) NOT NULL,
	POSITION					NUMBER(10)
) 
ON COMMIT DELETE ROWS; 

CREATE GLOBAL TEMPORARY TABLE TT_COMPONENT_TREE
(
	TOP_COMPONENT_ID			NUMBER(10) NOT NULL,
	CONTAINER_COMPONENT_ID		NUMBER(10),
	CHILD_COMPONENT_ID			NUMBER(10) NOT NULL,
	POSITION					NUMBER(10)
)
ON COMMIT DELETE ROWS;

/*******************************************************************
	MUDDLE CURRENT TABLES
*******************************************************************/
PROMPT >> Prefixing current tables with OLD_
DECLARE
	v_tables		T_STRING_LIST;
BEGIN
	v_tables := T_STRING_LIST(
		'COMPONENT_SOURCE',
		'COMPONENT_TYPE_CONTAINMENT',
		'CMPNT_CMPNT_RELATIONSHIP',
		'COMPONENT',
		'COMPONENT_TYPE',
		'CMPNT_PROD_RELATIONSHIP',
		'CMPNT_PROD_REL_PENDING',
		'PRODUCT',
		'PRODUCT_CODE_TYPE'
	);
	
	FOR i IN v_tables.FIRST .. v_tables.LAST
	LOOP
		
		EXECUTE IMMEDIATE 'ALTER TABLE '||v_tables(i)||' RENAME TO OLD_'||v_tables(i);
		
	END LOOP;
END;
/

/*******************************************************************
	APPLY THE SCHEMA CHANGES
*******************************************************************/

--
-- ER/Studio 8.0 SQL Code Generation
-- Company :      Microsoft
-- Project :      component changes.dm1
-- Author :       Microsoft
--
-- Date Created : Thursday, March 31, 2011 23:02:29
-- Target DBMS : Oracle 10g
--

-- 
-- TABLE: ACCEPTANCE_STATUS 
--

CREATE TABLE ACCEPTANCE_STATUS(
    ACCEPTANCE_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION             VARCHAR2(100)    NOT NULL,
    ISNEW                   NUMBER(10, 0),
    CONSTRAINT PK_ACCEPTANCE_STATUS PRIMARY KEY (ACCEPTANCE_STATUS_ID)
)
;



-- 
-- TABLE: ALL_COMPONENT_TYPE 
--

CREATE TABLE ALL_COMPONENT_TYPE(
    COMPONENT_TYPE_ID       NUMBER(10, 0)    NOT NULL,
    HANDLER_CLASS           VARCHAR2(255)    NOT NULL,
    HANDLER_PKG             VARCHAR2(255)    NOT NULL,
    NODE_JS_PATH            VARCHAR2(255)    NOT NULL,
    DESCRIPTION             VARCHAR2(100)    NOT NULL,
    EDITOR_CARD_GROUP_ID    NUMBER(10, 0),
    ISNEW                   NUMBER(10, 0),
    CONSTRAINT PK_ALL_COMPONENT_TYPE PRIMARY KEY (COMPONENT_TYPE_ID)
)
;



-- 
-- TABLE: COMPONENT 
--

CREATE TABLE COMPONENT(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_ID      NUMBER(10, 0)     NOT NULL,
    CREATED_BY_SID    NUMBER(10, 0)     NOT NULL,
    CREATED_DTM       DATE              DEFAULT SYSDATE NOT NULL,
    DESCRIPTION       VARCHAR2(4000),
    COMPONENT_CODE    VARCHAR2(100),
    DELETED           NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    ISNEW             NUMBER(10, 0),
    CHECK (DELETED IN (0,1)),
    CONSTRAINT PK_COMPONENT PRIMARY KEY (APP_SID, COMPONENT_ID)
)
;



-- 
-- TABLE: COMPONENT_BIND 
--

CREATE TABLE COMPONENT_BIND(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_ID         NUMBER(10, 0)    NOT NULL,
    COMPONENT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    COMPANY_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    ISNEW                NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_BIND PRIMARY KEY (APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
)
;



-- 
-- TABLE: COMPONENT_RELATIONSHIP 
--

CREATE TABLE COMPONENT_RELATIONSHIP(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    CONTAINER_COMPONENT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONTAINER_COMPONENT_ID         NUMBER(10, 0)    NOT NULL,
    CHILD_COMPONENT_TYPE_ID        NUMBER(10, 0)    NOT NULL,
    CHILD_COMPONENT_ID             NUMBER(10, 0)    NOT NULL,
    COMPANY_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    POSITION                       NUMBER(10, 0),
    ISNEW                          NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_RELATIONSHIP PRIMARY KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CONTAINER_COMPONENT_ID, CHILD_COMPONENT_TYPE_ID, CHILD_COMPONENT_ID, COMPANY_SID)
)
;



-- 
-- TABLE: COMPONENT_SOURCE 
--

CREATE TABLE COMPONENT_SOURCE(
    APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_TYPE_ID     NUMBER(10, 0)     NOT NULL,
    PROGRESSION_ACTION    VARCHAR2(100)     NOT NULL,
    CARD_TEXT             VARCHAR2(2000)    NOT NULL,
    DESCRIPTION_XML       VARCHAR2(4000),
    POSITION              NUMBER(10, 0)     NOT NULL,
    CARD_GROUP_ID         NUMBER(10, 0),
    ISNEW                 NUMBER(10, 0)
)
;



-- 
-- TABLE: COMPONENT_SUPPLIER_TYPE 
--

CREATE TABLE COMPONENT_SUPPLIER_TYPE(
    COMPONENT_SUPPLIER_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                   VARCHAR2(100)    NOT NULL,
    ISNEW                         NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_SUPPLIER_TYPE PRIMARY KEY (COMPONENT_SUPPLIER_TYPE_ID)
)
;



-- 
-- TABLE: COMPONENT_TYPE 
--

CREATE TABLE COMPONENT_TYPE(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    ISNEW                NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_TYPE PRIMARY KEY (APP_SID, COMPONENT_TYPE_ID)
)
;



-- 
-- TABLE: COMPONENT_TYPE_CONTAINMENT 
--

CREATE TABLE COMPONENT_TYPE_CONTAINMENT(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    CONTAINER_COMPONENT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CHILD_COMPONENT_TYPE_ID        NUMBER(10, 0)    NOT NULL,
    ALLOW_ADD_EXISTING             NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    ALLOW_ADD_NEW                  NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    ISNEW                          NUMBER(10, 0),
    CHECK (ALLOW_ADD_EXISTING IN (0, 1)),
    CHECK (ALLOW_ADD_NEW IN (0, 1)),
    CONSTRAINT PK_COMPONENT_TYPE_CONTAINMENT PRIMARY KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
)
;



-- 
-- TABLE: PRODUCT 
--

CREATE TABLE PRODUCT(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    PRODUCT_ID                  NUMBER(10, 0)    NOT NULL,
    COMPANY_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    PSEUDO_ROOT_COMPONENT_ID    NUMBER(10, 0)    NOT NULL,
    COMPONENT_TYPE_ID           NUMBER(10, 0)    DEFAULT 1 NOT NULL,
    ACTIVE                      NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CODE2_MANDATORY             NUMBER(1, 0)     NOT NULL,
    CODE2                       VARCHAR2(100),
    CODE3                       VARCHAR2(100),
    CODE3_MANDATORY             NUMBER(1, 0)     NOT NULL,
    NEED_REVIEW                 NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    ISNEW                       NUMBER(10, 0),
    CONSTRAINT CHK_PROD_ACTIVE CHECK (ACTIVE IN (1,0)),
    CONSTRAINT CHK_PROD_NEED_REVIEW CHECK (NEED_REVIEW IN (1,0)),
    CONSTRAINT CHK_PROD_CMPNT_TYPE CHECK (COMPONENT_TYPE_ID IN (1)),
    CHECK (CODE2 IS NOT NULL OR CODE2_MANDATORY = 0),
    CHECK (CODE3 IS NOT NULL OR CODE3_MANDATORY = 0),
    CHECK (CODE2_MANDATORY IN (0, 1)),
    CHECK (CODE3_MANDATORY IN (0, 1)),
    CONSTRAINT PK_PRODUCT PRIMARY KEY (APP_SID, PRODUCT_ID)
)
;



-- 
-- TABLE: PRODUCT_CODE_TYPE 
--

CREATE TABLE PRODUCT_CODE_TYPE(
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID                  NUMBER(10, 0)    NOT NULL,
    CODE_LABEL1                  VARCHAR2(100)    DEFAULT 'SKU' NOT NULL,
    CODE_LABEL2                  VARCHAR2(100),
    CODE2_MANDATORY              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CODE_LABEL3                  VARCHAR2(100),
    CODE3_MANDATORY              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    MAPPING_APPROVAL_REQUIRED    NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    ISNEW                        NUMBER(1, 0),
    CHECK (CODE2_MANDATORY IN (1,0)),
    CHECK (CODE3_MANDATORY IN (1,0)),
    CONSTRAINT PK_PRODUCT_CODE_TYPE PRIMARY KEY (APP_SID, COMPANY_SID)
)
;



-- 
-- TABLE: PURCHASED_COMPONENT 
--

CREATE TABLE PURCHASED_COMPONENT(
    APP_SID                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_ID                  NUMBER(10, 0)    NOT NULL,
    COMPONENT_TYPE_ID             NUMBER(10, 0)    DEFAULT 3 NOT NULL,
    COMPONENT_SUPPLIER_TYPE_ID    NUMBER(10, 0),
    ACCEPTANCE_STATUS_ID          NUMBER(10, 0),
    UNINVITED_SUPPLIER_ID         NUMBER(10, 0),
    PURCHASER_COMPANY_SID         NUMBER(10, 0),
    COMPANY_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    SUPPLIER_COMPANY_SID          NUMBER(10, 0),
    SUPPLIER_PRODUCT_ID           NUMBER(10, 0),
    ISNEW                         CHAR(10),
    CONSTRAINT CHK_PURCH_CMPNT_TYPE CHECK (COMPONENT_TYPE_ID IN (3)),
    CONSTRAINT "CHK_SUPPLIER_TYPE CHECK" CHECK ((
	COMPONENT_SUPPLIER_TYPE_ID = 0
) OR (
		COMPONENT_SUPPLIER_TYPE_ID = 1 
 	AND SUPPLIER_COMPANY_SID IS NOT NULL
) OR (
		COMPONENT_SUPPLIER_TYPE_ID = 2
	AND PURCHASER_COMPANY_SID IS NOT NULL
) OR (
		COMPONENT_SUPPLIER_TYPE_ID = 3
	AND UNINVITED_SUPPLIER_ID IS NOT NULL
)),
    CONSTRAINT PK32 PRIMARY KEY (APP_SID, COMPONENT_ID)
)
;



-- 
-- TABLE: UNINVITED_SUPPLIER 
--

CREATE TABLE UNINVITED_SUPPLIER(
    UNINVITED_SUPPLIER_ID    NUMBER(10, 0)     NOT NULL,
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID              NUMBER(10, 0)     NOT NULL,
    NAME                     VARCHAR2(1000)    NOT NULL,
    ISNEW                    NUMBER(10, 0),
    COUNTRY_CODE             VARCHAR2(2)       NOT NULL,
    CONSTRAINT PK_UNINVITED_SUPPLIER PRIMARY KEY (APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_ID)
)
;



-- 
-- INDEX: UNIQUE_COMPONENT_TYPE_ID 
--

CREATE UNIQUE INDEX UNIQUE_COMPONENT_TYPE_ID ON COMPONENT_BIND(APP_SID, COMPONENT_ID)
;
-- 
-- TABLE: ALL_COMPONENT_TYPE 
--

ALTER TABLE ALL_COMPONENT_TYPE ADD CONSTRAINT RefCARD_GROUP55 
    FOREIGN KEY (EDITOR_CARD_GROUP_ID)
    REFERENCES CARD_GROUP(CARD_GROUP_ID)
;


-- 
-- TABLE: COMPONENT 
--

ALTER TABLE COMPONENT ADD CONSTRAINT RefCUSTOMER_OPTIONS8 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE COMPONENT ADD CONSTRAINT RefCHAIN_USER60 
    FOREIGN KEY (CREATED_BY_SID, APP_SID)
    REFERENCES CHAIN_USER(USER_SID, APP_SID)
;


-- 
-- TABLE: COMPONENT_BIND 
--

ALTER TABLE COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT_TYPE79 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE COMPONENT_BIND ADD CONSTRAINT RefCOMPANY80 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT81 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;


-- 
-- TABLE: COMPONENT_RELATIONSHIP 
--

ALTER TABLE COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND82 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_ID, CONTAINER_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND83 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_ID, CHILD_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_TYPE_CONTAINMEN37 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE_CONTAINMENT(APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
;


-- 
-- TABLE: COMPONENT_SOURCE 
--

ALTER TABLE COMPONENT_SOURCE ADD CONSTRAINT RefCOMPONENT_TYPE20 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE COMPONENT_SOURCE ADD CONSTRAINT RefCARD_GROUP56 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES CARD_GROUP(CARD_GROUP_ID)
;


-- 
-- TABLE: COMPONENT_TYPE 
--

ALTER TABLE COMPONENT_TYPE ADD CONSTRAINT RefCUSTOMER_OPTIONS19 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE COMPONENT_TYPE ADD CONSTRAINT RefALL_COMPONENT_TYPE21 
    FOREIGN KEY (COMPONENT_TYPE_ID)
    REFERENCES ALL_COMPONENT_TYPE(COMPONENT_TYPE_ID)
;


-- 
-- TABLE: COMPONENT_TYPE_CONTAINMENT 
--

ALTER TABLE COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE38 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE40 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;


-- 
-- TABLE: PRODUCT 
--

ALTER TABLE PRODUCT ADD CONSTRAINT RefCOMPONENT_BIND84 
    FOREIGN KEY (APP_SID, PRODUCT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE PRODUCT ADD CONSTRAINT RefCOMPONENT23 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE PRODUCT ADD CONSTRAINT RefCOMPONENT24 
    FOREIGN KEY (APP_SID, PSEUDO_ROOT_COMPONENT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;


-- 
-- TABLE: PRODUCT_CODE_TYPE 
--

ALTER TABLE PRODUCT_CODE_TYPE ADD CONSTRAINT RefCOMPANY88 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES COMPANY(APP_SID, COMPANY_SID)
;


-- 
-- TABLE: PURCHASED_COMPONENT 
--

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_BIND114 
    FOREIGN KEY (APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_SUPPLIER_TYPE115 
    FOREIGN KEY (COMPONENT_SUPPLIER_TYPE_ID)
    REFERENCES COMPONENT_SUPPLIER_TYPE(COMPONENT_SUPPLIER_TYPE_ID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefACCEPTANCE_STATUS116 
    FOREIGN KEY (ACCEPTANCE_STATUS_ID)
    REFERENCES ACCEPTANCE_STATUS(ACCEPTANCE_STATUS_ID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefUNINVITED_SUPPLIER117 
    FOREIGN KEY (APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_ID)
    REFERENCES UNINVITED_SUPPLIER(APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_ID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP118 
    FOREIGN KEY (APP_SID, COMPANY_SID, SUPPLIER_COMPANY_SID)
    REFERENCES SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP119 
    FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, COMPANY_SID)
    REFERENCES SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT120 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE PURCHASED_COMPONENT ADD CONSTRAINT RefPRODUCT122 
    FOREIGN KEY (APP_SID, SUPPLIER_PRODUCT_ID)
    REFERENCES PRODUCT(APP_SID, PRODUCT_ID)
;


-- 
-- TABLE: UNINVITED_SUPPLIER 
--

ALTER TABLE UNINVITED_SUPPLIER ADD CONSTRAINT RefCOUNTRY51 
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES POSTCODE.COUNTRY(COUNTRY)
;

ALTER TABLE UNINVITED_SUPPLIER ADD CONSTRAINT RefCOMPANY62 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES COMPANY(APP_SID, COMPANY_SID)
;


PROMPT >> Applying manual schema changes
-- drop the constraint to OLD_PRODUCT
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE PRODUCT_METRIC DROP CONSTRAINT RefPRODUCT516';
	EXCEPTION WHEN OTHERS THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE PRODUCT_METRIC DROP CONSTRAINT RefALL_PRODUCT437';
	EXCEPTION WHEN OTHERS THEN NULL;
	END;
END;
/
-- reapply the constraint
ALTER TABLE PRODUCT_METRIC ADD CONSTRAINT RefPRODUCT516 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES PRODUCT(APP_SID, PRODUCT_ID)
;


PROMPT >> Cleaning dead views and building changed views
drop view V$COMPANY_PRODUCT ;
drop view V$COMPANY_COMPONENT ;
drop view V$PRODUCT ;
drop view V$COMPONENT ;
drop view V$PRODUCT_RELATIONSHIP ;
drop view V$PRODUCT_REL_PENDING ;
drop view V$COMPANY_PRODUCT_EXTENDED ;

/***********************************************************************
	v$ccomponent_type - all activated components types in the application
***********************************************************************/
PROMPT >> Creating v$component_type
CREATE OR REPLACE VIEW v$component_type AS
	SELECT ct.app_sid, act.component_type_id, act.handler_class, act.handler_pkg, 
			act.node_js_path, act.description, act.editor_card_group_id
	  FROM component_type ct, all_component_type act
	 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ct.component_type_id = act.component_type_id
;


/***********************************************************************
	v$ccomponent - all components with component type id folded in
***********************************************************************/
PROMPT >> Creating v$component
CREATE OR REPLACE VIEW v$component AS
	SELECT cmp.app_sid, cmp.component_id, ctb.component_type_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			ctb.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM component cmp, component_bind ctb
	 WHERE cmp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cmp.app_sid = ctb.app_sid
	   AND cmp.component_id = ctb.component_id
;

/***********************************************************************
	v$product - all products bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$product
CREATE OR REPLACE VIEW v$product AS
	SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, 
			p.active, cmp.component_code code1, p.code2, p.code3, p.need_review,
			cmp.description, cmp.component_code, cmp.deleted,
			p.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM product p, component cmp
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.app_sid = cmp.app_sid
	   AND p.product_id = cmp.component_id
;

/***********************************************************************
	v$purchased_componet - all purchased components bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$purchased_component
CREATE OR REPLACE VIEW v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, pc.purchaser_company_sid, 
			pc.uninvited_supplier_id, pc.supplier_product_id
	  FROM purchased_component pc, component cmp
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
;

/***********************************************************************
	v$purchased_component_supplier - purchased component -> supplier data 
***********************************************************************/
PROMPT >> Creating v$purchased_component_supplier
CREATE OR REPLACE VIEW v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_id, 
			NULL supplier_name, NULL supplier_country_code, NULL supplier_country_name
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_supplier_type_id = 0 -- SUPPLIER_NOT_SET
	--
	 UNION
	--
	--EXISTING_SUPPLIER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.supplier_company_sid, NULL uninvited_supplier_id, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 1 -- EXISTING_SUPPLIER
	   AND pc.supplier_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--EXISTING_PURCHASER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.purchaser_company_sid supplier_company_sid, NULL uninvited_supplier_id, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 2 -- EXISTING_PURCHASER
	   AND pc.purchaser_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--UNINVITED_SUPPLIER (basic data, uninvited supplier data bound)
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			NULL supplier_company_sid, us.uninvited_supplier_id, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_id = us.uninvited_supplier_id
	   AND us.country_code = coun.country_code
;

PROMPT >> Building changed packages
drop package cmpnt_cmpnt_relationship_pkg;
drop package cmpnt_prod_relationship_pkg;
drop package logical_component_pkg;

@..\..\chain_pkg
@..\..\company_pkg
@..\..\component_pkg
@..\..\purchased_component_pkg
@..\..\product_pkg

@..\..\component_body
@..\..\product_body
@..\..\purchased_component_body
@..\..\company_body
@..\..\chain_link_body

PROMPT >> Setting up new basedata
BEGIN
	INSERT INTO acceptance_status (acceptance_status_id, description) VALUES (chain_pkg.ACCEPT_PENDING, 'Pending');
	INSERT INTO acceptance_status (acceptance_status_id, description) VALUES (chain_pkg.ACCEPT_ACCEPTED, 'Accepted');
	INSERT INTO acceptance_status (acceptance_status_id, description) VALUES (chain_pkg.ACCEPT_REJECTED, 'Rejected');
	
	INSERT INTO component_supplier_type (component_supplier_type_id, description) VALUES (chain_pkg.SUPPLIER_NOT_SET, 'Supplier not set');
	INSERT INTO component_supplier_type (component_supplier_type_id, description) VALUES (chain_pkg.EXISTING_SUPPLIER, 'Existing supplier');
	INSERT INTO component_supplier_type (component_supplier_type_id, description) VALUES (chain_pkg.EXISTING_PURCHASER, 'Existing purchaser');
	INSERT INTO component_supplier_type (component_supplier_type_id, description) VALUES (chain_pkg.UNINVITED_SUPPLIER, 'Uninvited supplier');
END;
/

PROMPT >> Updating component data
EXEC user_pkg.logonadmin;
BEGIN
	/******************************************************************************
		CHAIN CORE COMPONENTS
	******************************************************************************/
	component_pkg.CreateType(
		chain_pkg.PRODUCT_COMPONENT, 
		'Credit360.Chain.Products.Product',
		'chain.product_pkg', 
		'/csr/site/chain/components/products/ProductNode.js', 
		'Product'
	);

	component_pkg.CreateType(	
		chain_pkg.LOGICAL_COMPONENT, 
		'Credit360.Chain.Products.LogicalComponent',
		'chain.component_pkg', 
		'/csr/site/chain/components/products/LogicalNode.js', 
		'Logical',
		card_pkg.GetCardGroupId('Logical Component Wizard')
	);

	component_pkg.CreateType(
		chain_pkg.PURCHASED_COMPONENT, 
		'Credit360.Chain.Products.PurchasedComponent',
		'chain.purchased_component_pkg', 
		'/csr/site/chain/components/products/PurchasedNode.js', 
		'Purchased',
		card_pkg.GetCardGroupId('Purchased Component Wizard')
	);

	component_pkg.CreateType(
		chain_pkg.NOTSURE_COMPONENT, 
		'Credit360.Chain.Products.NotSureComponent',
		'chain.component_pkg', 
		'/csr/site/chain/components/products/NotSureNode.js', 
		'Not Sure',
		card_pkg.GetCardGroupId('Not Sure Component Wizard')
	);

	/******************************************************************************
		RAINFOREST ALLIANCE COMPONENTS
	******************************************************************************/
	component_pkg.CreateType(
		chain_pkg.RA_ROOT_PROD_COMPONENT, 
		'Credit360.Chain.Products.GenericComponent',
		'chain.component_pkg', 
		'/rainforestalliance/components/products/ClientComponentNode.js', 
		'Rainforest Alliance Product Root'
	);

	component_pkg.CreateType(
		chain_pkg.RA_ROOT_WOOD_COMPONENT, 
		'Credit360.Chain.Products.GenericComponent',
		'chain.component_pkg', 
		'/rainforestalliance/components/products/ClientComponentNode.js', 
		'Rainforest Alliance Wood Root'
	);

	component_pkg.CreateType (
		chain_pkg.RA_WOOD_COMPONENT, 
		'Clients.RainforestAlliance.WoodComponent', 
		'rfa.wood_component_pkg', 
		'/rainforestalliance/components/products/ClientComponentNode.js',
		'Rainforest Alliance Wood',
		card_pkg.GetCardGroupId('Wood Source Wizard')
	);

	component_pkg.CreateType (
		chain_pkg.RA_WOOD_ESTIMATE_COMPONENT, 
		'Clients.RainforestAlliance.WoodEstimateComponent', 
		'rfa.wood_component_pkg', 
		'/rainforestalliance/components/products/ClientComponentNode.js',
		'Rainforest Alliance Wood Estimate',
		card_pkg.GetCardGroupId('Wood Source Wizard')
	);
END;
/

commit;
PROMPT >> Copying data to the new tables...
PROMPT >> Copying OLD_PRODUCT_CODE_TYPE -> PRODUCT_CODE_TYPE
BEGIN
	INSERT INTO product_code_type
	(app_sid, company_sid, code_label1, code_label2, code2_mandatory, code_label3, code3_mandatory, mapping_approval_required)
	SELECT pct.app_sid, pct.company_sid, pct.code_label1, pct.code_label2, pct.code2_mandatory, pct.code_label3, pct.code3_mandatory, c.mapping_approval_required
	  FROM old_product_code_type pct, company c
	 WHERE pct.app_sid = c.app_sid
	   AND pct.company_sid = c.company_sid;
END;
/

UPDATE product_code_type SET code2_mandatory = 0, code3_mandatory = 0; 
-- workaround - this was causing an issue where codes had been made mandtory after products created
-- as we have no "real" products this will do for now

PROMPT >> Activating application COMPONENT_TYPE from OLD_COMPONENT_TYPE
BEGIN
	INSERT INTO component_type
	(app_sid, component_type_id)
	SELECT app_sid, component_type_id
	  FROM old_component_type;
END;
/

PROMPT >> Copying OLD_COMPONENT_SOURCE -> COMPONENT_SOURCE
BEGIN
	INSERT INTO component_source
	(app_sid, component_type_id, progression_action, card_text, description_xml, position, card_group_id)
	SELECT app_sid, component_type_id, progression_action, card_text, description_xml, position, card_group_id
	  FROM old_component_source;
END;
/

PROMPT >> Copying OLD_COMPONENT_TYPE_CONTAINMENT -> COMPONENT_TYPE_CONTAINMENT
BEGIN
	INSERT INTO component_type_containment
	(app_sid, container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT app_sid, container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
	  FROM old_component_type_containment;
END;
/

PROMPT >> Copying OLD_COMPONENT -> COMPONENT
BEGIN
	INSERT INTO component
	(app_sid, component_id, created_by_sid, created_dtm, description, component_code, deleted)
	SELECT app_sid, component_id, created_by_sid, created_dtm, description, component_code, deleted
	  FROM old_component;
END;
/

PROMPT >> Creating COMPONENT_BIND from OLD_COMPONENT 
BEGIN
	INSERT INTO component_bind
	(app_sid, component_id, component_type_id, company_sid)
	SELECT app_sid, component_id, component_type_id, company_sid
	  FROM old_component;
END;
/

PROMPT >> Copying COMPONENT_RELATIONSHIP from OLD_CMPNT_CMPNT_RELATIONSHIP
BEGIN
	INSERT INTO component_relationship
	(app_sid, company_sid, container_component_id, container_component_type_id, child_component_id, child_component_type_id, position)
	SELECT r.app_sid, con.company_sid, r.parent_component_id, con.component_type_id, r.component_id, chi.component_type_id, r.position
	  FROM old_cmpnt_cmpnt_relationship r, component_bind con, component_bind chi
	 WHERE r.app_sid = con.app_sid
	   AND r.app_sid = chi.app_sid
	   AND r.parent_component_id = con.component_id
	   AND r.component_id = chi.component_id;
END;
/

PROMPT >> Copying PRODUCT from OLD_PRODUCT
BEGIN
	INSERT INTO product
	(app_sid, product_id, company_sid, pseudo_root_component_id, active, code2_mandatory, code2, code3_mandatory, code3, need_review, component_type_id)
	SELECT op.app_sid, op.root_component_id, op.company_sid, op.product_builder_component_id, op.active, pct.code2_mandatory, op.code2, pct.code3_mandatory, op.code3, op.need_review, chain_pkg.PRODUCT_COMPONENT
	  FROM old_product op, product_code_type pct
	 WHERE op.app_sid = pct.app_sid
	   AND op.company_sid = pct.company_sid;
END;
/

PROMPT >> Copying PURCHASED_COMPONENT from OLD_CMPNT_PROD_RELATIONSHIP
PROMPT >> (i.e. suppliers who have accepected prod->component pairing)
BEGIN
	INSERT INTO purchased_component
	(app_sid, component_id, component_type_id, component_supplier_type_id, 
	company_sid, supplier_company_sid, acceptance_status_id, supplier_product_id)
	--buying_code, buying_description, selling_code, selling_description)
	SELECT r.app_sid, r.purchaser_component_id, chain_pkg.PURCHASED_COMPONENT, chain_pkg.EXISTING_SUPPLIER, 
		   r.purchaser_company_sid, r.supplier_company_sid, chain_pkg.ACCEPT_ACCEPTED, p.root_component_id
		   --r.buying_code, r.buying_description, r.selling_code, r.selling_description
	  FROM old_cmpnt_prod_relationship r, old_product p
	 WHERE r.app_sid = p.app_sid
	   AND r.supplier_product_id = p.product_id;
END;
/

PROMPT >> Copying PURCHASED_COMPONENT from OLD_CMPNT_PROD_REL_PENDING
PROMPT >> (i.e. suppliers who are pending accept or have rejected prod->component pairing)
BEGIN
	INSERT INTO purchased_component
	(app_sid, component_id, component_type_id, component_supplier_type_id, 
	company_sid, supplier_company_sid, acceptance_status_id, supplier_product_id)
	--buying_code, buying_description, selling_code, selling_description)
	SELECT r.app_sid, r.purchaser_component_id, chain_pkg.PURCHASED_COMPONENT, chain_pkg.EXISTING_SUPPLIER, 
		   r.purchaser_company_sid, r.supplier_company_sid, CASE WHEN r.rejected = 0 THEN chain_pkg.ACCEPT_PENDING ELSE chain_pkg.ACCEPT_REJECTED END, p.root_component_id
		   --r.buying_code, r.buying_description, r.selling_code, r.selling_description
	  FROM old_cmpnt_prod_rel_pending r, old_product p
	 WHERE r.app_sid = p.app_sid(+)
	   AND r.supplier_product_id = p.product_id(+);
END;
/

@update_tail