define version=68
@update_header

/********************************************************/
PROMPT >> RAP5-LATEST02
/********************************************************/

CREATE GLOBAL TEMPORARY TABLE chain.TT_ID
( 
	ID							NUMBER(10) NOT NULL,
	POSITION					NUMBER(10)
) 
ON COMMIT DELETE ROWS; 

CREATE GLOBAL TEMPORARY TABLE chain.TT_COMPONENT_TREE
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
	v_tables		chain.T_STRING_LIST;
BEGIN
	v_tables := chain.T_STRING_LIST(
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
		
		EXECUTE IMMEDIATE 'ALTER TABLE chain.chain.'||v_tables(i)||' RENAME TO OLD_'||v_tables(i);
		
	END LOOP;
END;
/
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
		for r in (select constraint_name from all_constraints where table_name='OLD_' || v_tables(i) and constraint_type in ('P','U','R')) loop
			EXECUTE IMMEDIATE 'ALTER TABLE chain.chain.OLD_'||v_tables(i)||' drop constraint '||r.constraint_name||' cascade';
		end loop;
		
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

CREATE TABLE chain.ACCEPTANCE_STATUS(
    ACCEPTANCE_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION             VARCHAR2(100)    NOT NULL,
    ISNEW                   NUMBER(10, 0),
    CONSTRAINT PK_ACCEPTANCE_STATUS PRIMARY KEY (ACCEPTANCE_STATUS_ID)
)
;



-- 
-- TABLE: ALL_COMPONENT_TYPE 
--

CREATE TABLE chain.ALL_COMPONENT_TYPE(
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

CREATE TABLE chain.COMPONENT(
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

CREATE TABLE chain.COMPONENT_BIND(
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

CREATE TABLE chain.COMPONENT_RELATIONSHIP(
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

CREATE TABLE chain.COMPONENT_SOURCE(
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

CREATE TABLE chain.COMPONENT_SUPPLIER_TYPE(
    COMPONENT_SUPPLIER_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                   VARCHAR2(100)    NOT NULL,
    ISNEW                         NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_SUPPLIER_TYPE PRIMARY KEY (COMPONENT_SUPPLIER_TYPE_ID)
)
;



-- 
-- TABLE: COMPONENT_TYPE 
--

CREATE TABLE chain.COMPONENT_TYPE(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    ISNEW                NUMBER(10, 0),
    CONSTRAINT PK_COMPONENT_TYPE PRIMARY KEY (APP_SID, COMPONENT_TYPE_ID)
)
;



-- 
-- TABLE: COMPONENT_TYPE_CONTAINMENT 
--

CREATE TABLE chain.COMPONENT_TYPE_CONTAINMENT(
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

CREATE TABLE chain.PRODUCT(
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

CREATE TABLE chain.PRODUCT_CODE_TYPE(
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

CREATE TABLE chain.PURCHASED_COMPONENT(
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

CREATE TABLE chain.UNINVITED_SUPPLIER(
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

CREATE UNIQUE INDEX chain.UNIQUE_COMPONENT_TYPE_ID ON chain.COMPONENT_BIND(APP_SID, COMPONENT_ID)
;
-- 
-- TABLE: ALL_COMPONENT_TYPE 
--

ALTER TABLE chain.ALL_COMPONENT_TYPE ADD CONSTRAINT RefCARD_GROUP55 
    FOREIGN KEY (EDITOR_CARD_GROUP_ID)
    REFERENCES chain.CARD_GROUP(CARD_GROUP_ID)
;


-- 
-- TABLE: COMPONENT 
--

ALTER TABLE chain.COMPONENT ADD CONSTRAINT RefCUSTOMER_OPTIONS8 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.COMPONENT ADD CONSTRAINT RefCHAIN_USER60 
    FOREIGN KEY (CREATED_BY_SID, APP_SID)
    REFERENCES chain.CHAIN_USER(USER_SID, APP_SID)
;


-- 
-- TABLE: COMPONENT_BIND 
--

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT_TYPE79 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT RefCOMPANY80 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT81 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;


-- 
-- TABLE: COMPONENT_RELATIONSHIP 
--

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND82 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_ID, CONTAINER_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND83 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_ID, CHILD_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_TYPE_CONTAINMEN37 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE_CONTAINMENT(APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
;


-- 
-- TABLE: COMPONENT_SOURCE 
--

ALTER TABLE chain.COMPONENT_SOURCE ADD CONSTRAINT RefCOMPONENT_TYPE20 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_SOURCE ADD CONSTRAINT RefCARD_GROUP56 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES chain.CARD_GROUP(CARD_GROUP_ID)
;


-- 
-- TABLE: COMPONENT_TYPE 
--

ALTER TABLE chain.COMPONENT_TYPE ADD CONSTRAINT RefCUSTOMER_OPTIONS19 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.COMPONENT_TYPE ADD CONSTRAINT RefALL_COMPONENT_TYPE21 
    FOREIGN KEY (COMPONENT_TYPE_ID)
    REFERENCES chain.ALL_COMPONENT_TYPE(COMPONENT_TYPE_ID)
;


-- 
-- TABLE: COMPONENT_TYPE_CONTAINMENT 
--

ALTER TABLE chain.COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE38 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE40 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;


-- 
-- TABLE: PRODUCT 
--

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT_BIND84 
    FOREIGN KEY (APP_SID, PRODUCT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT23 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT24 
    FOREIGN KEY (APP_SID, PSEUDO_ROOT_COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;


-- 
-- TABLE: PRODUCT_CODE_TYPE 
--

ALTER TABLE chain.PRODUCT_CODE_TYPE ADD CONSTRAINT RefCOMPANY88 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;


-- 
-- TABLE: PURCHASED_COMPONENT 
--

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_BIND114 
    FOREIGN KEY (APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_SUPPLIER_TYPE115 
    FOREIGN KEY (COMPONENT_SUPPLIER_TYPE_ID)
    REFERENCES chain.COMPONENT_SUPPLIER_TYPE(COMPONENT_SUPPLIER_TYPE_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefACCEPTANCE_STATUS116 
    FOREIGN KEY (ACCEPTANCE_STATUS_ID)
    REFERENCES chain.ACCEPTANCE_STATUS(ACCEPTANCE_STATUS_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefUNINVITED_SUPPLIER117 
    FOREIGN KEY (APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_ID)
    REFERENCES chain.UNINVITED_SUPPLIER(APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP118 
    FOREIGN KEY (APP_SID, COMPANY_SID, SUPPLIER_COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefSUPPLIER_RELATIONSHIP119 
    FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT120 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefPRODUCT122 
    FOREIGN KEY (APP_SID, SUPPLIER_PRODUCT_ID)
    REFERENCES chain.PRODUCT(APP_SID, PRODUCT_ID)
;


-- 
-- TABLE: UNINVITED_SUPPLIER 
--

ALTER TABLE chain.UNINVITED_SUPPLIER ADD CONSTRAINT RefCOUNTRY51 
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES postcode.COUNTRY(COUNTRY)
;

ALTER TABLE chain.UNINVITED_SUPPLIER ADD CONSTRAINT RefCOMPANY62 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;


PROMPT >> Applying manual schema changes
-- drop the constraint to OLD_PRODUCT
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.PRODUCT_METRIC DROP CONSTRAINT RefPRODUCT516';
	EXCEPTION WHEN OTHERS THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.PRODUCT_METRIC DROP CONSTRAINT RefALL_PRODUCT437';
	EXCEPTION WHEN OTHERS THEN NULL;
	END;
END;
/
-- reapply the constraint
ALTER TABLE chain.PRODUCT_METRIC ADD CONSTRAINT RefPRODUCT516 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES chain.PRODUCT(APP_SID, PRODUCT_ID)
;


PROMPT >> Cleaning dead views and building changed views
drop view chain.V$COMPANY_PRODUCT ;
drop view chain.V$COMPANY_COMPONENT ;
drop view chain.V$PRODUCT ;
drop view chain.V$COMPONENT ;
drop view chain.V$PRODUCT_RELATIONSHIP ;
drop view chain.V$PRODUCT_REL_PENDING ;
drop view chain.V$COMPANY_PRODUCT_EXTENDED ;

/***********************************************************************
	v$ccomponent_type - all activated components types in the application
***********************************************************************/
PROMPT >> Creating v$component_type
CREATE OR REPLACE VIEW chain.v$component_type AS
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
CREATE OR REPLACE VIEW chain.v$component AS
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
CREATE OR REPLACE VIEW chain.v$product AS
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
CREATE OR REPLACE VIEW chain.v$purchased_component AS
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
CREATE OR REPLACE VIEW chain.v$purchased_component_supplier AS
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
drop package chain.cmpnt_cmpnt_relationship_pkg;
drop package chain.cmpnt_prod_relationship_pkg;
drop package chain.logical_component_pkg;

CREATE OR REPLACE PACKAGE CHAIN.action_pkg
IS

-- action reason types
-- TO DO change this to be case consistent with events
AC_RA_FIRST_REGISTRATION	 		CONSTANT VARCHAR2(50) := 'FIRST_REGISTRATION';
AC_RA_USER_REGISTRATION	 			CONSTANT VARCHAR2(50) := 'USER_REGISTRATION';
AC_RA_COMPANY_DETAILS_CHANGED 		CONSTANT VARCHAR2(50) := 'COMPANY_DETAILS_CHANGED';
AC_RA_QUESTIONNAIRE_ASSIGNED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_ASSIGNED';
AC_RA_QUESTIONNAIRE_SUBMITTED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_SUBMITTED';
AC_RA_QUESTIONNAIRE_APPROVED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_APPROVED';
AC_RA_DEPENDENT_DATA_UPDATED	 	CONSTANT VARCHAR2(50) := 'DEPENDENT_DATA_UPDATED';
-- TO DO switch these for ID's

-- Product actions
AC_RA_PRD_PURCHASER_MAP_NEEDED	 	CONSTANT VARCHAR2(50) := 'PURCHASER_MAP_NEEDED';
--AC_RA_PRD_SUPPLIER_MAP_NEEDED	 	CONSTANT VARCHAR2(50) := 'SUPPLIER_MAP_NEEDED';

AC_REP_ALLOW_MULTIPLE				CONSTANT NUMBER (10) := 1;
AC_REP_NO_MULTIPLE_UPDATE_DTM		CONSTANT NUMBER (10) := 2;
AC_REP_NO_MULTIPLE_LEAVE_DTM		CONSTANT NUMBER (10) := 3;
AC_REP_REOPEN						CONSTANT NUMBER (10) := 4;

PROCEDURE AddAction (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
);

PROCEDURE CompleteAction (
	in_action_id		IN  action.action_id%TYPE
);

PROCEDURE GetActions (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActions (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetReasonForActionId (
	in_reason_class		reason_for_action.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE AddCompanyDoActions (
	in_new_company_sid			security_pkg.T_SID_ID
);

PROCEDURE AddUserDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
);

PROCEDURE ConfirmCompanyDetailsDoActions (
	in_company_sid				security_pkg.T_SID_ID
);

PROCEDURE ConfirmUserDetailsDoActions (
	in_user_sid					security_pkg.T_SID_ID
);

PROCEDURE InviteQuestionnaireDoActions (
	in_to_company_sid			security_pkg.T_SID_ID,
	in_questionnaire_id			questionnaire.questionnaire_id%TYPE,
	in_from_company_sid			security_pkg.T_SID_ID,
	out_action_id				OUT action.action_id%TYPE
);

PROCEDURE ShareQuestionnaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);


PROCEDURE AcceptQuestionaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);
	

PROCEDURE ViewQResultsDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);

PROCEDURE StartActionPlanDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);

PROCEDURE CompanyDetailsUpdatedDoActions (
	in_company_sid				security_pkg.T_SID_ID
);

PROCEDURE GenerateAlertEntries (
	in_as_of_dtm		IN TIMESTAMP
);

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_for_company_url				IN	action_type.for_company_url%TYPE,
	in_related_questionnaire_url	IN	action_type.related_questionnaire_url%TYPE,
	in_related_company_url			IN	action_type.related_company_url%TYPE,
	in_for_user_url					IN	action_type.for_user_url%TYPE,
	in_other_url_1					IN	action_type.other_url_1%TYPE DEFAULT NULL,
	in_other_url_2					IN	action_type.other_url_2%TYPE DEFAULT NULL,
	in_other_url_3					IN	action_type.other_url_3%TYPE DEFAULT NULL,
	in_css_class					IN	action_type.css_class%TYPE DEFAULT NULL
);

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_clear_urls					IN  BOOLEAN,
	in_css_class					IN	action_type.css_class%TYPE DEFAULT NULL
);

PROCEDURE ClearActionTypeUrls (
	in_action_type_id				IN	action_type.action_type_id%TYPE
);

PROCEDURE SetActionTypeUrl (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
);

PROCEDURE CreateReasonForAction (
	in_reason_for_action_id			IN	reason_for_action.reason_for_action_id%TYPE,
	in_action_type_id				IN	reason_for_action.action_type_id%TYPE,
	in_class						IN	reason_for_action.CLASS%TYPE,
	in_reason_name					IN	reason_for_action.reason_name%TYPE,
	in_reason_desc					IN	reason_for_action.reason_description%TYPE,
	in_action_repeat_type_id		IN	reason_for_action.action_repeat_type_id%TYPE
);



END action_pkg;
/

 
CREATE OR REPLACE PACKAGE chain.chain_pkg
IS

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;

-- a general use code
UNDEFINED							CONSTANT NUMBER := 0;
HIDE_HELP_TEXT						CONSTANT VARCHAR2(1) := NULL;

SUBTYPE T_ACTIVE					IS NUMBER;
ACTIVE 								CONSTANT T_ACTIVE := 1;
INACTIVE 							CONSTANT T_ACTIVE := 0;

SUBTYPE T_DELETED					IS NUMBER;
DELETED 							CONSTANT T_DELETED := 1;
NOT_DELETED 						CONSTANT T_DELETED := 0;

INVERTED_CHECK						CONSTANT BOOLEAN := TRUE;
NORMAL_CHECK						CONSTANT BOOLEAN := FALSE;

SUBTYPE T_GROUP						IS VARCHAR2(100);
ADMIN_GROUP							CONSTANT T_GROUP := 'Administrators';
USER_GROUP							CONSTANT T_GROUP := 'Users';
PENDING_GROUP						CONSTANT T_GROUP := 'Pending Users';
CHAIN_ADMIN_GROUP					CONSTANT T_GROUP := 'Chain '||ADMIN_GROUP;
CHAIN_USER_GROUP					CONSTANT T_GROUP := 'Chain '||USER_GROUP;

COMPANY_UPLOADS						CONSTANT security.securable_object.name%TYPE := 'Uploads';
UNINVITED_SUPPLIERS					CONSTANT security.securable_object.name%TYPE := 'Uninvited Suppliers';

SUBTYPE T_CAPABILITY_PERM_TYPE		IS NUMBER(10);
SPECIFIC_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 0;
BOOLEAN_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 1;

SUBTYPE T_CAPABILITY_TYPE			IS NUMBER(10);
CT_ROOT								CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMMON							CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMPANY							CONSTANT T_CAPABILITY_TYPE := 1; 
CT_SUPPLIERS						CONSTANT T_CAPABILITY_TYPE := 2; 
CT_COMPANIES						CONSTANT T_CAPABILITY_TYPE := 3; -- both the CT_COMPANY and CT_SUPPLIERS nodes

/****************************************************************************************************/
SUBTYPE T_CAPABILITY				IS VARCHAR2(100);

-- treated as a either a COMPANY or SUPPLIER capability check depending on sid 
-- that is passed in with it compared with the company sid set in session
COMPANYorSUPPLIER					CONSTANT T_CAPABILITY := 'VIRTUAL.COMPANYorSUPPLIER';

/**** Root capabilities ****/
CAPABILITIES						CONSTANT T_CAPABILITY := 'Capabilities';
COMPANY								CONSTANT T_CAPABILITY := 'Company';
SUPPLIERS							CONSTANT T_CAPABILITY := 'Suppliers';

/**** Company/Suppliers nodes capabilities ****/
SPECIFY_USER_NAME					CONSTANT T_CAPABILITY := 'Specify user name';
QUESTIONNAIRE						CONSTANT T_CAPABILITY := 'Questionnaire';
SUBMIT_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Submit questionnaire';
SETUP_STUB_REGISTRATION				CONSTANT T_CAPABILITY := 'Setup stub registration';
RESET_PASSWORD						CONSTANT T_CAPABILITY := 'Reset password';
CREATE_USER							CONSTANT T_CAPABILITY := 'Create user';
EVENTS								CONSTANT T_CAPABILITY := 'Events';
ACTIONS								CONSTANT T_CAPABILITY := 'Actions';
TASKS								CONSTANT T_CAPABILITY := 'Tasks';
METRICS								CONSTANT T_CAPABILITY := 'Metrics';
PRODUCTS							CONSTANT T_CAPABILITY := 'Products';
COMPONENTS							CONSTANT T_CAPABILITY := 'Components';
PROMOTE_USER						CONSTANT T_CAPABILITY := 'Promote user';
PRODUCT_CODE_TYPES					CONSTANT T_CAPABILITY := 'Product code types';
UPLOADED_FILE						CONSTANT T_CAPABILITY := 'Uploaded file';

/**** Common capabilities ****/
IS_TOP_COMPANY						CONSTANT T_CAPABILITY := 'Is top company';
SEND_QUESTIONNAIRE_INVITE			CONSTANT T_CAPABILITY := 'Send questionnaire invitation';
SEND_NEWSFLASH						CONSTANT T_CAPABILITY := 'Send newsflash';
RECEIVE_USER_TARGETED_NEWS			CONSTANT T_CAPABILITY := 'Receive user-targeted newsflash';
APPROVE_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Approve questionnaire';

/****************************************************************************************************/

SUBTYPE T_VISIBILITY				IS NUMBER;
HIDDEN 								CONSTANT T_VISIBILITY := 0;
JOBTITLE 							CONSTANT T_VISIBILITY := 1;
NAMEJOBTITLE						CONSTANT T_VISIBILITY := 2;
FULL 								CONSTANT T_VISIBILITY := 3;

SUBTYPE T_REGISTRATION_STATUS		IS NUMBER;
PENDING								CONSTANT T_REGISTRATION_STATUS := 0;
REGISTERED 							CONSTANT T_REGISTRATION_STATUS := 1;
REJECTED							CONSTANT T_REGISTRATION_STATUS := 2;
MERGED								CONSTANT T_REGISTRATION_STATUS := 3;

SUBTYPE T_INVITATION_TYPE			IS NUMBER;
QUESTIONNAIRE_INVITATION			CONSTANT T_INVITATION_TYPE := 1;
STUB_INVITATION						CONSTANT T_INVITATION_TYPE := 2;

SUBTYPE T_INVITATION_STATUS			IS NUMBER;
-- ACTIVE = 1 (defined above)
EXPIRED								CONSTANT T_INVITATION_STATUS := 2;
CANCELLED							CONSTANT T_INVITATION_STATUS := 3;
PROVISIONALLY_ACCEPTED				CONSTANT T_INVITATION_STATUS := 4;
ACCEPTED							CONSTANT T_INVITATION_STATUS := 5;
REJECTED_NOT_EMPLOYEE				CONSTANT T_INVITATION_STATUS := 6;
REJECTED_NOT_SUPPLIER				CONSTANT T_INVITATION_STATUS := 7;

SUBTYPE T_GUID_STATE				IS NUMBER;
GUID_OK 							CONSTANT T_GUID_STATE := 0;
--GUID_INVALID						CONSTANT T_GUID_STATE := 1; -- probably only used in cs class
GUID_NOTFOUND						CONSTANT T_GUID_STATE := 2;
GUID_EXPIRED						CONSTANT T_GUID_STATE := 3;
GUID_ALREADY_USED					CONSTANT T_GUID_STATE := 4;

SUBTYPE T_ALERT_ENTRY_TYPE			IS NUMBER;
EVENT_ALERT							CONSTANT T_ALERT_ENTRY_TYPE := 1;
ACTION_ALERT						CONSTANT T_ALERT_ENTRY_TYPE := 2;

SUBTYPE T_ALERT_ENTRY_PARAM_TYPE	IS NUMBER;
ORDERED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 1;
NAMED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 2;

/****************************************************************************************************/

SUBTYPE T_SHARE_STATUS				IS NUMBER;
NOT_SHARED 							CONSTANT T_SHARE_STATUS := 11;
SHARING_DATA 						CONSTANT T_SHARE_STATUS := 12;
SHARED_DATA_RETURNED 				CONSTANT T_SHARE_STATUS := 13;
SHARED_DATA_ACCEPTED 				CONSTANT T_SHARE_STATUS := 14;
SHARED_DATA_REJECTED 				CONSTANT T_SHARE_STATUS := 15;

SUBTYPE T_QUESTIONNAIRE_STATUS		IS NUMBER;
ENTERING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 1;
REVIEWING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 2;
READY_TO_SHARE 						CONSTANT T_QUESTIONNAIRE_STATUS := 3;

/****************************************************************************************************/
SUBTYPE T_FLAG						IS BINARY_INTEGER;

ALLOW_NONE							CONSTANT T_FLAG := 0;
ALLOW_ADD_EXISTING					CONSTANT T_FLAG := 1;
ALLOW_ADD_NEW						CONSTANT T_FLAG := 2;
--ALLOW_EDIT							CONSTANT T_FLAG := 4;
ALLOW_ALL							CONSTANT T_FLAG := 3;

/****************************************************************************************************/
SUBTYPE T_ACCEPTANCE_STATUS			IS NUMBER;

ACCEPT_PENDING						CONSTANT T_ACCEPTANCE_STATUS := 1;
ACCEPT_ACCEPTED						CONSTANT T_ACCEPTANCE_STATUS := 2;
ACCEPT_REJECTED						CONSTANT T_ACCEPTANCE_STATUS := 3;

/****************************************************************************************************/
SUBTYPE T_SUPPLIER_TYPE				IS NUMBER;

SUPPLIER_NOT_SET					CONSTANT T_SUPPLIER_TYPE := 0;
EXISTING_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 1;
EXISTING_PURCHASER					CONSTANT T_SUPPLIER_TYPE := 2;
UNINVITED_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 3;

/****************************************************************************************************/
SUBTYPE T_MESSAGE_TYPE				IS NUMBER;
EVENT								CONSTANT T_MESSAGE_TYPE := 1;
ACTION								CONSTANT T_MESSAGE_TYPE := 2;

SUBTYPE T_REPEAT_TYPE				IS NUMBER;
NEVER_REPEAT						CONSTANT T_REPEAT_TYPE := 0;
REPEAT_IF_CLOSED					CONSTANT T_REPEAT_TYPE := 1;
REFRESH_IF_OPEN						CONSTANT T_REPEAT_TYPE := 2;
ALWAYS_REPEAT						CONSTANT T_REPEAT_TYPE := 3;

SUBTYPE T_ADDRESS_TYPE				IS NUMBER;
PRIVATE_ADDRESS						CONSTANT T_ADDRESS_TYPE := 1;
USER_ADDRESS						CONSTANT T_ADDRESS_TYPE := 2;
COMPANY_ADDRESS						CONSTANT T_ADDRESS_TYPE := 3;

SUBTYPE T_PRIORITY_TYPE				IS NUMBER;
--HIDDEN (defined above)			CONSTANT T_PRIORITY_TYPE := 0;
NEUTRAL								CONSTANT T_PRIORITY_TYPE := 1;
HIGHLIGHTED							CONSTANT T_PRIORITY_TYPE := 2;
XEXCLUSIVE							CONSTANT T_PRIORITY_TYPE := 3;

/****************************************************************************************************/
SUBTYPE T_MESSAGE_DEFINITION_LOOKUP	IS NUMBER;
-- Secondary directional stuff --
NONE_IMPLIED						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 0;
PURCHASER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
SUPPLIER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Administrative messaging --
CONFIRM_COMPANY_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
CONFIRM_YOUR_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Invitation messaging --
INVITATION_SENT						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
INVITATION_ACCEPTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
INVITATION_REJECTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;

-- Questionnaire messaging --
COMPLETE_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
QUESTIONNAIRE_SUBMITTED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
REVIEW_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 201;
QUESTIONNAIRE_APPROVED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 202;

-- Component messaging --
PRODUCT_MAPPING_REQUIRED			CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 300;

-- MAERSK --
SUPPLIER_REG_DETAILS_CHANGED		CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1000;
ACTION_PLAN_STARTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1000;

/****************************************************************************************************/
SUBTYPE T_COMPONENT_CODE			IS component.component_code%TYPE;

SUBTYPE T_COMPONENT_TYPE			IS NUMBER;

-- COMPONENT types
PRODUCT_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 1;
LOGICAL_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 2;
PURCHASED_COMPONENT					CONSTANT T_COMPONENT_TYPE := 3;
NOTSURE_COMPONENT					CONSTANT T_COMPONENT_TYPE := 4;

-- CLIENT SPECIFC COMPONENT TYPES 
RA_ROOT_PROD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 48;
RA_ROOT_WOOD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 49;
RA_WOOD_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 50;
RA_WOOD_ESTIMATE_COMPONENT			CONSTANT T_COMPONENT_TYPE := 51;

/****************************************************************************************************/

ERR_QNR_NOT_FOUND	CONSTANT NUMBER := -20500;
QNR_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_FOUND, -20500);

ERR_QNR_ALREADY_EXISTS	CONSTANT NUMBER := -20501;
QNR_ALREADY_EXISTS EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_EXISTS, -20501);

ERR_QNR_NOT_SHARED CONSTANT NUMBER := -20502;
QNR_NOT_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_SHARED, -20502);

ERR_QNR_ALREADY_SHARED CONSTANT NUMBER := -20503;
QNR_ALREADY_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_SHARED, -20503);



PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
);

PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE;


PROCEDURE IsChainAdmin(
	out_result				OUT  NUMBER
);

FUNCTION IsChainAdmin
RETURN BOOLEAN;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

FUNCTION IsElevatedAccount
RETURN BOOLEAN;

FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG;

END chain_pkg;
/

 
CREATE OR REPLACE PACKAGE chain.company_pkg
IS


/************************************************************
	SYS_CONTEXT handlers
************************************************************/

FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;


/************************************************************
	Securable object handlers
************************************************************/
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
);

/************************************************************
	Company Management Handlers
************************************************************/
-- this can be used to trigger a verification of each company's so structure during updates
PROCEDURE VerifySOStructure;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
);

-- uses security_pkg.getACT
PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_name					IN  company.name%TYPE,
	in_address_1			IN  company.address_1%TYPE,
	in_address_2			IN  company.address_2%TYPE,
	in_address_3			IN  company.address_3%TYPE,
	in_address_4			IN  company.address_4%TYPE,
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_phone				IN  company.phone%TYPE,
	in_fax					IN  company.fax%TYPE,
	in_website				IN  company.website%TYPE
);

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION GetCompanyName (
	in_company_sid 			IN security_pkg.T_SID_ID
) RETURN company.name%TYPE;

PROCEDURE SearchCompanies ( 
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchMyCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE StartRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
);

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE DeactivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);


FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
);

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsSupplier (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER;


PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
);

PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/*
PROCEDURE ForceSetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);
*/

END company_pkg;
/

 
CREATE OR REPLACE PACKAGE chain.component_pkg
IS

/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 *
 * NOTE: Component types registered using this method cannot be editted in the UI. See next overload for more info.
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
);

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 * @param in_editor_card_group_id	The card group that handles editting of this type
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
);


/**********************************************************************************
	APP MANAGEMENT
**********************************************************************************/
/**
 * Activates this type for the session application
 *
 * @param in_type_id			The type of component to activate
 */
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
);

/**********************************************************************************/
/* Component sources are application level UI configurations that allow us to set */
/* specific text and help data in a ComponentSource card. 						  */
/*                                                       . 						  */

/**
 * Clears component source data
 */
PROCEDURE ClearSources;

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 *
 * NOTE: Component source data added using this method will be used for all card groups.
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
);

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 * @param in_card_group_id		The card group to include this source data for
 *
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
);

/**
 * Gets component sources for a specific card manager
 *
 * @param in_card_group_id			The id of the card group to collect that sources for
 * @returns							The source data cursor
 */
PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************/
/* Component type containment acts as both a UI helper and database ri for which  */
/* types of components can house other types.									  */
/* This is set at application level.				 . 						      */
/*                                                       . 						  */

/**
 * Clears component type containment for this application
 */
PROCEDURE ClearTypeContainment;

/**
 * Sets component type containment with UI helper flags for a single container/child pair
 *
 * @param in_container_type_id		The container component type
 * @param in_child_type_id			The child component type
 * @param in_allow_flags			See chain_pkg for valid allow flags
 *
 * NOTE: This method will ensure that ActivateType is called for both 
 *		 the container and child types.
 */
PROCEDURE SetTypeContainment (
	in_container_type_id	IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id		IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags			IN chain_pkg.T_FLAG
);

/**
 * Gets type containment data for output to the ui
 *
 * @returns							The containment data cursor
 */
PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	UTILITY
**********************************************************************************/
/**
 * Checks if a component is of a specific type
 *
 * @param in_component_id			The id of the component to check
 * @param in_type_id				The presumed type
 * @returns							TRUE if the type matches, FALSE if not
 */
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN;

/**
 * Gets the owner company sid for given component id
 *
 * @param in_component_id			The id of the component
 * @returns							The company sid that owns the component
 */
FUNCTION GetCompanySid (
	in_component_id			IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Checks to see if a component is deleted
 *
 * @param in_component_id			The id of the component to check
 */
FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN;

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_id		The top id of the component in the tree
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
);

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_ids		The top ids of the components in the trees
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
);

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
/**
 * Gets the components types that are active in this application
 *
 * @returns							A cursor of (as above)
 */
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets the specific component type requested
 *
 * @param in_type_id				The specific component type to get
 * @returns							A cursor of (as above)
 */
PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
/**
 * Saves a component. If in_component_id <= 0, a new component is created.
 * If in_component_id > 0, the component is updated, provided that the type
 * passed in matches the expected type.
 *
 * @param in_component_id			The id (actual for existing, < 0 for new)
 * @param in_type_id				The type 
 * @param in_type_id				The description
 * @param in_type_id				The component code
 * @returns							The actual id of the component
 */
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE;

/**
 * Marks a component as deleted
 *
 * @param in_component_id			The id of the component to delete
 */
PROCEDURE DeleteComponent (
	in_component_id			IN component.component_id%TYPE
);

/**
 * Gets basic component data by component id
 *
 * @param in_component_id			The id of the component to get
 * @returns							A cursor containing the basic component data
 */
PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Gets child component data of a specific type for a top_component
 *
 * @param in_top_component_id		The top component of the tree to get
 * @param in_type_id				The type of component that we're looking for
 * @returns							A cursor containing the component data
 *
 * NOTE: The type is passed in because we allow a single method to collect data
 * for more than one type of component. You must ensure that you only return
 * components of the requested type, as this method may be called again
 * using an alternate type
 */
PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Searchs all components that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Searchs all components of a specific type that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @param in_of_type				The specific type to search for
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

/**
 * Attaches one component to another component
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Fully detaches a component from all container and child components
 *
 * @param in_component_id		The component id to detach
 */
PROCEDURE DetachComponent (
	in_component_id				IN component.component_id%TYPE	
);

/**
 * Detaches all child components from this component
 *
 * @param in_container_id			The component id to detach children from
 */
PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
);

/**
 * Detaches a specific container / child component pair
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Gets a table of all component ids that are children of the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE;

/**
 * Gets a table of all component ids that are children of the top component ids
 *
 * @param in_top_component_ids		An array of all top component ids to include
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE;


/**
 * Gets a heirarchy cursor of all parent id / component id relationships 
 * starting with the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns out_cur					The cursor (as above)
 */
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/

/**
 * Changes a not sure component type into another component type
 *
 * @param in_component_id			The id of the not sure component to change
 * @param in_to_type_id				The type to change the component to
 * @returns out_cur					A cursor the basic component data
 */
PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END component_pkg;
/
 
CREATE OR REPLACE PACKAGE chain.purchased_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
);

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

END purchased_component_pkg;
/
 
CREATE OR REPLACE PACKAGE chain.product_pkg
IS

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE
) RETURN NUMBER;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SearchProducts (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodes (
    in_company_sid      	IN  security_pkg.T_SID_ID,
	in_code_label1			IN  product_code_type.code_label1%TYPE,
	in_code_label2			IN  product_code_type.code_label2%TYPE,
	in_code_label3			IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory		IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory		IN 	product_code_type.code3_mandatory%TYPE
);

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
);

PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
);

PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
);

PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
);

END product_pkg;
/
 
CREATE OR REPLACE PACKAGE chain.chain_link_pkg
IS

PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE AddCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
);

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProduct (
	in_product_id			IN  product.product_id%TYPE
);

PROCEDURE KillProduct (
	in_product_id			IN  product.product_id%TYPE
);

-- subscribers of this method are expected to modify data in the tt_component_type_containment table
PROCEDURE FilterComponentTypeContainment;


END chain_link_pkg;
/ 
 
CREATE OR REPLACE PACKAGE BODY chain.chain_pkg
IS

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO chain_user
		(user_sid, registration_status_id)
		VALUES
		(in_user_sid, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
)
AS
BEGIN
	-- NO SEC CHECKS - you can only set default settings for the user that you're logged in as in the current application
	
	BEGIN
		INSERT INTO user_setting
		(name, number_value, string_value)
		VALUES
		(LOWER(TRIM(in_name)), in_number_value, in_string_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting
			   SET number_value = in_number_value,
			   	   string_value = in_string_value
			 WHERE name = LOWER(TRIM(in_name))
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END;

END;

-- we need to pass in dummy because for some very very strange reason, we get an exception if we pass in a string array as the first param 
PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_t_names				security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_names);
BEGIN
	-- NO SEC CHECKS - you can only get default settings for the user that you're logged in as in the current application
	OPEN out_cur FOR
		SELECT name, number_value, string_value
		  FROM user_setting
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND name IN (SELECT LOWER(TRIM(value)) FROM TABLE(v_t_names));
END;


PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	invitation_expiration_days,
				site_name,
				admin_has_dev_access,
				support_email,
				newsflash_summary_sp,
				questionnaire_filter_class,
				last_generate_alert_dtm,
				scheduled_alert_intvl_minutes,
				chain_implementation,
				company_helper_sp,
				default_receive_sched_alerts,
				override_send_qi_path,
				login_page_message,
				invite_from_name_addendum,
				sched_alerts_enabled,
				link_host,
				NVL(top_company_sid, 0) top_company_sid,
				product_url,
				NVL(default_url, '/') default_url
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 				security_pkg.T_SID_ID;
BEGIN
	v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');
	RETURN v_sid_id;
END;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM v$country
		 ORDER BY LOWER(name);
END;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE
AS
BEGIN
	RETURN TO_DATE(in_str_val, 'DD/MM/YY HH24:MI:SS');
END;

PROCEDURE IsChainAdmin  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainAdmin THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainAdmin 
RETURN BOOLEAN
AS
BEGIN
	RETURN IsChainAdmin(security_pkg.GetSid);
END;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, in_user_sid)) T
		 WHERE T.sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;			 
	END IF;	
	
	RETURN FALSE;
END;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN in_sid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Chain/BuiltIn/Invitation Respondent');
END;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsInvitationRespondant(in_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

FUNCTION IsElevatedAccount
RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;
	
	IF IsInvitationRespondant(security_pkg.GetSid) THEN
		RETURN TRUE;
	END IF;
	
	IF security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon') THEN
		RETURN TRUE;
	END IF;
	
	RETURN FALSE;
END;

-- use with care!
-- just issues the ACT, i.e. doesn't stick it into SYS_CONTEXT
FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID
AS
	v_act		security_pkg.T_ACT_ID;
BEGIN
	-- we don't want to set the security context
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(security_pkg.SID_BUILTIN_ADMINISTRATOR, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	RETURN v_act;
END;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN

	SELECT top_company_sid
	  INTO v_company_sid
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Top company sid is not set');
	END IF;

	RETURN v_company_sid;
END;

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG
AS
BEGIN
	IF security.bitwise_pkg.bitand(in_flags, in_flag) = 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;


END chain_pkg;
/
 
CREATE OR REPLACE PACKAGE BODY chain.company_pkg
IS

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')) || ' (' || v_cc || ')', '/', '\');
END;

FUNCTION TrySplitSOName (
	in_name					IN  security_pkg.T_SO_NAME,
	out_company_name		OUT company.name%TYPE,
	out_country_code		OUT company.country_code%TYPE
) RETURN BOOLEAN
AS
	v_idx	NUMBER;
BEGIN
	v_idx := LENGTH(in_name);

	
	IF SUBSTR(in_name, v_idx, 1) <> ')' THEN
		RETURN FALSE;
	END IF;
	
	WHILE v_idx > 1 LOOP
		v_idx := v_idx - 1;

		IF SUBSTR(in_name, v_idx, 1) = '(' THEN
			out_company_name := SUBSTR(in_name, 1, v_idx - 2);
			out_country_code := SUBSTR(in_name, v_idx + 1, LENGTH(in_name) - v_idx - 1);
	
			RETURN GenerateSOName(out_company_name, out_country_code) = in_name;
		END IF;
	END LOOP;

	RETURN FALSE;
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_sid				IN  security_pkg.T_SID_ID,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(in_on_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0,  
		in_to_sid, 
		in_permission_set
	);
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_path				IN  varchar2,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	AddPermission(
		in_on_sid, 
		securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, in_to_path), 
		in_permission_set
	);	
END;


/**
 *	The purpose of the procedure is to be a single point of company based securable object setup. 
 *  Any changes to this procedure should be flexible enough to deal with situations where the
 *  object may or may not already exists, already have permissions etc. so that it can
 *  be called during any update scripts.
 */
PROCEDURE CreateSOStructure (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_is_new_company		IN  BOOLEAN
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_ucd_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_ADMIN_GROUP);
	v_chain_users_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_USER_GROUP);
	v_capabilities_sid		security_pkg.T_SID_ID;
	v_capability_sid		security_pkg.T_SID_ID;
	v_admins_sid			security_pkg.T_SID_ID;
	v_users_sid				security_pkg.T_SID_ID;
	v_pending_sid			security_pkg.T_SID_ID;
	v_uploads_sid			security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
		
	/********************************************
		CREATE OBJECTS AND ADD PERMISSIONS
	********************************************/
	
	-- ADMIN GROUP
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.ADMIN_GROUP, v_admins_sid);
	END;
	
	-- USER GROUP
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.USER_GROUP, v_users_sid);
	END;
	
	-- PENDING USER GROUP 
	BEGIN
		v_pending_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.PENDING_GROUP, v_pending_sid);
	END;
	
	-- UPLOADS CONTAINER
	BEGIN
		v_uploads_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_UPLOADS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_UPLOADS, v_uploads_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uploads_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- UNINVITED SUPPLIERS CONTAINER
	BEGIN
		v_uninvited_sups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.UNINVITED_SUPPLIERS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- SETUP CAPABILITIES
	BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.CAPABILITIES);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.CAPABILITIES, v_capabilities_sid);
		
			-- don't inherit dacls
			securableobject_pkg.SetFlags(v_act_id, v_capabilities_sid, 0);
			-- clean existing ACE's
			acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capabilities_sid));
			
			AddPermission(v_capabilities_sid, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
	END;
	
	capability_pkg.RefreshCompanyCapabilities(in_company_sid);	

	/********************************************
		ADD OBJECTS TO GROUPS
	********************************************/
	-- add the users group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_users_sid, v_chain_users_sid);
	
	-- add the administrators group to the users group
	-- our group, so we're hacking this in
	--group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	BEGIN
		INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (v_admins_sid, v_users_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;

END;


FUNCTION GetGroupMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_name			IN  chain_pkg.T_GROUP
)
RETURN security.T_SO_TABLE
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN	
	RETURN group_pkg.GetDirectMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, in_group_name));
END;

-- collects a paged cursor of companies based on sids passed in as a T_ORDERED_SID_TABLE
PROCEDURE CollectSearchResults (
	in_all_results			IN  security.T_ORDERED_SID_TABLE,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_all_results);
	
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
		 	SELECT *
		 	  FROM v$company c, TABLE(in_all_results) T
		 	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND c.company_sid = T.SID_ID
		 	 ORDER BY LOWER(c.name);
	
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*, NVL(sr.active, chain_pkg.inactive) active_supplier
						  FROM v$company c, (SELECT * FROM v$supplier_relationship WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) sr, TABLE(in_all_results) T
		 	 			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	 			   AND c.app_sid = sr.app_sid(+)
		 	 			   AND c.company_sid = sr.supplier_company_sid(+)
		 	 			   AND c.company_sid = T.SID_ID
		 	 			 ORDER BY LOWER(c.name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

FUNCTION VerifyMembership (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_type			IN  chain_pkg.T_GROUP,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_g_sid					security_pkg.T_SID_ID;
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	BEGIN
		-- leave this in here so things don't blow up when we clean
		v_g_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, in_group_type);
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetMembersAsTable(v_act_id, v_g_sid))
		 WHERE sid_id = in_user_sid;
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN FALSE;
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;
	
	IF v_count > 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	END IF;
	
	RETURN v_count > 0;
END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/

/************************************************************
	SYS_CONTEXT handlers
************************************************************/
FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT in_company_sid;
BEGIN
	
	-- if v_company_sid is 0, try to get the existing company sid out of the context
	IF NVL(v_company_sid, 0) = 0 THEN
		v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;

	IF chain_pkg.IsElevatedAccount THEN
		SetCompany(v_company_sid);
		RETURN v_company_sid;
	END IF;
	
	-- first, verify that this user exists as a chain_user (ensures that views work at bare minimum)
	chain_pkg.AddUserToChain(SYS_CONTEXT('SECURITY', 'SID'));
		
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE
		   AND company_sid = v_company_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;

	-- if we've got a company sid, verify that the user is a member
	IF v_company_sid IS NOT NULL THEN
		-- is this user a group member?
		IF NOT chain_pkg.IsChainAdmin AND
		   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
		   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
			v_company_sid := NULL;
		END IF;
	END IF;
	
	-- if we don't have a company yet, check to see if a default company sid is set
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT cu.default_company_sid
			  INTO v_company_sid
			  FROM chain_user cu, v$company c
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cu.app_sid = c.app_sid
			   AND cu.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND cu.default_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, check to see if there is a top company set in customer options
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT co.top_company_sid
			  INTO v_company_sid
			  FROM customer_options co, company c
			 WHERE co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND co.app_sid = c.app_sid
			   AND co.top_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, grab the first company we're a member of alphabetically
	IF v_company_sid IS NULL THEN
		-- ok, no valid default set - might as well just sort them alphabetically by company name and 
		-- 		pick the first, at least it's predictable		
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c, (
					SELECT DISTINCT so.parent_sid_id company_sid
					  FROM security.securable_object so, TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, security_pkg.GetSid)) ug -- user group sids
					 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
					   AND so.sid_id = ug.sid_id
					   ) uc -- user companies
				 WHERE c.company_sid = uc.company_sid
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	-- if there's still no company set and we're a chain admin, pick the first company alphabetically.
	IF v_company_sid IS NULL AND chain_pkg.IsChainAdmin THEN
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;	
	END IF;

	-- set the company sid in the context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
	-- return the company sid (or 0 if it's been cleared)
	RETURN NVL(v_company_sid, 0);
	
END;


PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, 0);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	IF v_company_sid = 0 THEN
		v_company_sid := NULL;
	END IF;
	
	IF v_company_sid IS NOT NULL THEN
		IF chain_pkg.IsElevatedAccount THEN
			-- just make sure that the company exists
			SELECT COUNT(*)
			  INTO v_count
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = v_company_sid;
			
			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		ELSE
			-- is this user a group member?
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
					security_pkg.SetContext('CHAIN_COMPANY', NULL);
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		END IF;
	END IF;
		
	-- set the value in sys context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
END;

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM v$company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(name) = LOWER(in_name);
	
	SetCompany(v_company_sid);
END;


FUNCTION GetCompany
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;
	RETURN v_company_sid;
END;

/************************************************************
	Securable object handlers
************************************************************/

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
	v_chain_admins 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators');
	v_chain_users 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');
BEGIN
	
	IF in_parent_sid_id <> chain_pkg.GetCompaniesContainer THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain companies MUST be created under the application Chain/Companies container');
	END IF;
	
	IF NOT TrySplitSOName(in_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, '"'||in_name||'", "'||v_company_name||'", "'||v_country_code||'"Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
	
	-- Getting the securable object handler to create the company is a really bad idea. There are restrictions on the the characters that an SO name can comprise (and they need to
	-- be unique) - restrictions that are not applicable to company names.
	
    INSERT INTO company
    (company_sid, name, country_code)
    VALUES 
    (in_sid_id, v_company_name, TRIM(v_country_code));
    
	-- causes the groups and containers to get created
	CreateSOStructure(in_sid_id, TRUE);
	
	AddPermission(in_sid_id, security_pkg.SID_BUILTIN_ADMINISTRATOR, security_pkg.PERMISSION_STANDARD_ALL);
	AddPermission(in_sid_id, v_chain_admins, security_pkg.PERMISSION_WRITE);
	AddPermission(in_sid_id, v_chain_users, security_pkg.PERMISSION_WRITE);
	
	-- if we are creating a company add a company wide "check my details" action
	action_pkg.AddCompanyDoActions(in_sid_id);

	-- callout to customised systems
	chain_link_pkg.AddCompany(in_sid_id);
	
	-- add product codes defaults for the new company
	product_pkg.SetProductCodeDefaults(in_sid_id);
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
BEGIN
	IF (in_new_name IS NULL) THEN -- this is actually a virtual deletion - lets leave the name as is, but set the deleted flag
		UPDATE company
		   SET deleted = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id;
		
		RETURN;
	END IF;
		
	IF NOT TrySplitSOName(in_new_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
		
	UPDATE company
	   SET name = v_company_name,
	       country_code = TRIM(v_country_code)
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_helper_pkg	VARCHAR2(50); 
BEGIN

	--clean up all questionnaires
	FOR r IN (
		SELECT DISTINCT qt.db_class pkg
		  FROM questionnaire q, questionnaire_type qt 
		 WHERE q.questionnaire_type_id = qt.questionnaire_type_id 
		   AND q.app_sid = qt.app_sid
		   AND q.company_sid = in_sid_id
		   AND q.app_sid = security_pkg.GetApp
	)
	LOOP
		-- clear questionnaire types for this company
		IF r.pkg IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||r.pkg||'.DeleteQuestionnaires(:1);end;'
				USING in_sid_id; -- company sid
		END IF;	   
	
	END LOOP;
	
	-- now clean up all things linked to company
	
	DELETE FROM applied_company_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;


	DELETE FROM event_user_status 
	 WHERE event_id IN
	(
		SELECT event_id
		  FROM event 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM event
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- clean up actions
	DELETE FROM action_user_status 
	 WHERE action_id IN
	(
		SELECT action_id
		  FROM action 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action 
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;

	   
	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN
	(
		SELECT questionnaire_share_id
		  FROM questionnaire_share 
		 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM questionnaire_share 
	 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;
	   
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	
	DELETE FROM questionnaire
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	   
	
	DELETE FROM company_cc_email
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM company_metric
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	  
	DELETE FROM invitation_qnr_type 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_company_sid = in_sid_id) 
			OR (to_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
  
  UPDATE invitation 
     SET reinvitation_of_invitation_id = NULL
   WHERE reinvitation_of_invitation_id IN (
      SELECT invitation_id 
	    FROM invitation 
	   WHERE ((from_company_sid = in_sid_id) 
          OR (to_company_sid = in_sid_id))	
         AND app_sid = security_pkg.GetApp);
	   
	DELETE FROM invitation
	 WHERE ((from_company_sid = in_sid_id) 
		OR (to_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;


	DELETE FROM supplier_relationship
	 WHERE ((supplier_company_sid = in_sid_id) 
		OR (purchaser_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	   
	   
	-- are we OK blanking this? I think so as this is reset sensibly when ever a chain page is loaded
	UPDATE chain_user 
	   SET default_company_sid = NULL
	 WHERE default_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM newsflash_company WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	/* PRODUCT RELATED ITEMS TO CLEAR */
	-- clear the default product codes
	DELETE FROM product_code_type WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	-- clear all products and components and any links between them
	-- TODO: we'll need to fix this up...
	--DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));	
	--DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	--DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	--DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	-- clear tasks
	FOR tn IN (
		SELECT task_node_id
		  FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id 
		 ORDER BY parent_task_node_id DESC
	)
	LOOP
		FOR T IN (
			SELECT task_id
			  FROM task
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = in_sid_id 
			   AND task_node_id = tn.task_node_id
		)
		LOOP
			DELETE FROM task_doc
			 WHERE app_sid = security_pkg.GetApp
			   AND task_entry_id IN 
				(
					SELECT task_entry_id
					  FROM task_entry
					 WHERE app_sid = security_pkg.GetApp
					   AND task_id = T.task_id
				);
		
			 DELETE FROM task_entry
			  WHERE app_sid = security_pkg.GetApp
				AND task_id = T.task_id;

			
			 DELETE FROM task
			  WHERE app_sid = security_pkg.GetApp
			    AND task_id = T.task_id;
			  
		END LOOP;	
		
		DELETE FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND task_node_id = tn.task_node_id;
	END LOOP;
	
	chain_link_pkg.DeleteCompany(in_sid_id);
	
	DELETE FROM company
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

/************************************************************
	Company Management Handlers
************************************************************/

PROCEDURE VerifySOStructure
AS
BEGIN
	FOR r IN (
		SELECT company_sid
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		CreateSOStructure(r.company_sid, FALSE);
	END LOOP;
END;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	-- createSO does the sec check
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Company'), GenerateSOName(in_name, in_country_code), out_company_sid);
	
	UPDATE company
	   SET name = in_name
	 WHERE company_sid = out_company_sid;
END;

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	BEGIN
		SELECT company_sid INTO out_company_sid FROM company WHERE name=in_name AND country_code=in_country_code;
	EXCEPTION
		WHEN no_data_found THEN
			CreateCompany(in_name, in_country_code, out_company_sid);
			RETURN;
	END;		
	RAISE dup_val_on_index;
END;

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	-- user groups undder the company
	v_admin_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_pending_grp_sid		security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_users_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_other_company_grp_cnt	NUMBER;

BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	-- Now we need to delete all users from this company
	-- We cannot do this in DeleteSO for company as
	--		the users are NOT under the company in the tree - they are just members of groups under the company
	-- 		All the info we need to indentify which users to delete (group structure under company) is cleared by the security DeleteSO before the DeleteSO call is made above
	FOR r IN (
		SELECT DISTINCT user_sid 
		  FROM v$company_member 
		 WHERE company_sid = in_company_sid 
		   AND app_sid = security_pkg.GetApp
	)
	LOOP

		-- TO DO - this is not a full implementation but is to get round a current issue and will work currently
		-- we may need to implement a chain user SO type to do properly
		-- but - to prevent non chain users getting trashed this relies on 
		-- 		only chain users will be direct members unless we add people for no good reason via secmgr
		-- 		only users who have logged on to chain should be in chain user table  - though this could incluse superusers
	
		-- is this user in the groups of any other company
		SELECT COUNT(*) 
		INTO v_other_company_grp_cnt
		FROM 
		(
			-- this should just return chain company groups
			SELECT sid_id 
			  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(security_pkg.GetAct, r.user_sid))
			 WHERE sid_id NOT IN (v_admin_grp_sid, v_pending_grp_sid, v_users_grp_sid)
			 AND parent_sid_id IN (SELECT company_sid FROM company WHERE app_sid = security_pkg.GetApp)
		);
			
		IF v_other_company_grp_cnt = 0 THEN			
			-- this user is not a member of any other companies/groups so delete them
			chain.company_user_pkg.DeleteObject(security_pkg.GetAct, r.user_sid);
		END IF;
		
	END LOOP;
	
	-- finally delete the company
	securableobject_pkg.DeleteSO(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteCompany(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	securableobject_pkg.RenameSO(in_act_id, in_company_sid, NULL);
END;


PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_name					company.name%TYPE;
	v_cc					company.country_code%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Undelete access denied to company with sid '||in_company_sid);
	END IF;
	
	UPDATE company
	   SET deleted = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	RETURNING name, country_code
	  INTO v_name, v_cc;
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(v_name, v_cc));	
END;


PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_name					IN  company.name%TYPE,
	in_address_1			IN  company.address_1%TYPE,
	in_address_2			IN  company.address_2%TYPE,
	in_address_3			IN  company.address_3%TYPE,
	in_address_4			IN  company.address_4%TYPE,
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_phone				IN  company.phone%TYPE,
	in_fax					IN  company.fax%TYPE,
	in_website				IN  company.website%TYPE
)
AS
	v_cur_details			company%ROWTYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_cur_details.name <> in_name OR v_cur_details.country_code <> in_country_code THEN
		securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(in_name, in_country_code));
	END IF;
	
	UPDATE company
	   SET address_1 = in_address_1, 
		   address_2 = in_address_2, 
		   address_3 = in_address_3, 
		   address_4 = in_address_4, 
		   town = in_town, 
		   state = in_state, 
		   postcode = in_postcode, 
		   phone = in_phone, 
		   fax = in_fax, 
	 	   website = in_website
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, chain_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
END;

PROCEDURE GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_company_sid := GetCompanySid(in_company_name, in_country_code); 
END;

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	GetCompany(GetCompany(), out_cur);
END;

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF IsPurchaser(in_company_sid) THEN 
		-- default allow this to happen as this only implies read,and we
		-- don't really need a purchasers capability for anything other than this
		NULL;
	ELSE
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
		END IF;
	END IF;

	OPEN out_cur FOR
		SELECT c.*, code_label1, code_label2, code2_mandatory, code_label3, code3_mandatory	
		  FROM v$company c, product_code_type pct
		 WHERE c.company_sid = pct.company_sid(+) 
		   AND c.app_sid = pct.app_sid(+)
		   AND c.company_sid = in_company_sid
		   AND c.app_sid = security_pkg.GetApp;
END;

FUNCTION GetCompanyName (
	in_company_sid 			IN security_pkg.T_SID_ID
) RETURN company.name%TYPE
AS
	v_n			company.name%TYPE;
BEGIN
	
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		SELECT name
		  INTO v_n
		  FROM v$company
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid;
	ELSE	
		BEGIN
			SELECT c.name
			  INTO v_n
			  FROM v$company c, v$company_relationship cr
			 WHERE c.app_sid = security_pkg.GetApp
			   AND c.app_sid = cr.app_sid
			   AND c.company_sid = in_company_sid
			   AND c.company_sid = cr.company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_n := ' ';
		END;
	END IF;

	RETURN v_n;
END;

	 
PROCEDURE SearchCompanies ( 
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanies(0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, v$company_relationship cr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = cr.app_sid
		   AND c.company_sid = cr.company_sid 
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF (NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ)) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;
		
		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;
		
		RETURN;
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND ((in_only_active = chain_pkg.active AND sr.active = chain_pkg.active) OR (in_only_active = chain_pkg.inactive))
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: This method already exists in company_pkg as SearchSuppliers (you can search with text = '' and page_size 0 for all results)
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
END;

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: this method should be moved to company_pkg	 
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.purchaser_company_sid 
		   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
END;


PROCEDURE SearchMyCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF chain_pkg.IsChainAdmin(SYS_CONTEXT('SECURITY', 'SID')) THEN
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
				SELECT company_sid
				  FROM v$company
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND active = chain_pkg.ACTIVE
				   AND LOWER(name) LIKE v_search
				);
	ELSE
		-- bulk collect company sid's that match our search result
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT c.company_sid
			  FROM v$company_member cm, v$company c
			 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cm.app_sid = c.app_sid
			   AND cm.company_sid = c.company_sid
			   AND cm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND LOWER(c.name) LIKE v_search
		  );
	END IF;
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE StartRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	StartRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	BEGIN
		INSERT INTO supplier_relationship
		(purchaser_company_sid, supplier_company_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
	
	UPDATE supplier_relationship
	   SET active = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	purchased_component_pkg.RelationshipActivated(in_purchaser_company_sid, in_supplier_company_sid);
	
	chain_link_pkg.ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
)
AS
	v_force						NUMBER(1) DEFAULT 0;
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	IF in_force THEN
		v_force := 1;
	END IF;
	
	DELETE 
	  FROM supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (   active = chain_pkg.PENDING
	   		OR v_force = 1);
END;

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = sysdate + interval '1' minute
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_company_sid;
END;

PROCEDURE DeactivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_company_sid;
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	IF NOT chain_pkg.IsChainAdmin AND
	   NOT VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
	   NOT VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
)
AS
BEGIN
	IF IsMember(in_company_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;


PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;	
	IF IsSupplier(in_supplier_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	RETURN v_count > 0;
END;

-- TO DO - if this gets used a lot we might need a new COMPANYorSUPPLIERorPURCHASER type capability
-- but this is only intended to be used for a specific "GetPurchaserCompany" which is a read only "get me the company details of someone I sell to"
PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsPurchaser(in_purchaser_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsPurchaser(in_purchaser_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(in_purchaser_company_sid, in_supplier_company_sid);
END;

FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_status					supplier_relationship.active%TYPE;
BEGIN

	BEGIN
		SELECT active
		  INTO v_status
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_status := -1;
	END;
	
	RETURN v_status;
END;

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;
	
	SELECT active
	  INTO v_active
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_active = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;
	
	UPDATE company
	   SET active = chain_pkg.ACTIVE,
	       activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	chain_link_pkg.ActivateCompany(in_company_sid);
END;

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
		
	OPEN out_cur FOR
		SELECT email
		  FROM company_cc_email
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	DELETE FROM company_cc_email
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF in_emails IS NULL OR in_emails.COUNT = 0 OR in_emails(1) IS NULL THEN
		RETURN;
	END IF;

	FOR i IN in_emails.FIRST .. in_emails.LAST 
	LOOP
		BEGIN
			INSERT INTO company_cc_email
			(company_sid, lower_email, email)
			VALUES
			(in_company_sid, LOWER(TRIM(in_emails(i))), TRIM(in_emails(i)));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
END;

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- this cursor should provide two colomns, one row - columns named: email_from_name, email_from_address
	-- TODO: Actually look this up (only return a valid cursor IF the email_from_address is set)
	OPEN out_cur FOR
		SELECT support_email email_from_name, support_email email_from_address FROM customer_options WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF chain_pkg.IsChainAdmin(in_user_sid) THEN
		OPEN out_count_cur FOR
			SELECT COUNT(*) companies_count
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
		
		OPEN out_companies_cur FOR
			SELECT company_sid, name
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
	
		RETURN;
	END IF;
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) companies_count
		  FROM v$company_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	
	OPEN out_companies_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company_member cm, v$company c
		 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.app_sid = c.app_sid
		   AND cm.company_sid = c.company_sid
		   AND cm.user_sid = in_user_sid;
END;

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing stub registration data');
	END IF;
	
	UPDATE company
	   SET allow_stub_registration = in_active,
	       approve_stub_registration = in_approve
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	DELETE FROM email_stub
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF in_stubs IS NULL OR in_stubs.COUNT = 0 OR in_stubs(1) IS NULL THEN
		RETURN;
	END IF;

	
	FOR i IN in_stubs.FIRST .. in_stubs.LAST 
		LOOP
			BEGIN
				INSERT INTO email_stub
				(company_sid, lower_stub, stub)
				VALUES
				(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), LOWER(TRIM(in_stubs(i))), TRIM(in_stubs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
	END LOOP;
	
END;


PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data required for stub registration');
	END IF;
	
	UPDATE company
	   SET stub_registration_guid = user_pkg.GenerateAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND stub_registration_guid IS NULL;
	
	OPEN out_options_cur FOR
		SELECT stub_registration_guid, allow_stub_registration, approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	OPEN out_stubs_cur FOR
		SELECT stub 
		  FROM email_stub 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY lower_stub;

END;

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- no sec checks (public page)
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE -- company is active
		   AND allow_stub_registration = chain_pkg.ACTIVE -- allow stub registration
		   AND LOWER(stub_registration_guid) = LOWER(in_guid) -- match guid
		   			-- email stubs are set
		   AND company_sid IN (SELECT company_sid FROM email_stub WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));
		
		OPEN out_state_cur FOR
			SELECT chain_pkg.GUID_OK guid_state FROM DUAL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			
			RETURN;
	END;
	
	OPEN out_company_cur FOR
		SELECT company_sid, name, country_name
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid;
	
	OPEN out_stubs_cur FOR
		SELECT stub, lower_stub
		  FROM email_stub
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid
		 ORDER BY lower_stub;
END;

END company_pkg;
/
 
CREATE OR REPLACE PACKAGE BODY chain.component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
PROCEDURE FillTypeContainment
AS
BEGIN
	DELETE FROM tt_component_type_containment;
	
	INSERT INTO tt_component_type_containment
	(container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	chain_link_pkg.FilterComponentTypeContainment;
END;

FUNCTION CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_component_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to components for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to components for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

FUNCTION GetTypeId (
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_COMPONENT_TYPE
AS
	v_type_id 				chain_pkg.T_COMPONENT_TYPE;
BEGIN
	SELECT component_type_id
	  INTO v_type_id
	  FROM component_bind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	RETURN v_type_id;
END;

FUNCTION GetHandlerPkg (
	in_type_id				chain_pkg.T_COMPONENT_TYPE
) RETURN all_component_type.handler_pkg%TYPE
AS
	v_hp					all_component_type.handler_pkg%TYPE;
BEGIN
	SELECT handler_pkg
	  INTO v_hp
	  FROM v$component_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_type_id = in_type_id;
	
	RETURN v_hp;
END;

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ActivateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type
		(component_type_id)
		VALUES
		(in_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
)
AS
BEGIN
	CreateType(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, NULL); 
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO all_component_type
		(component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id)
		VALUES
		(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, in_editor_card_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_component_type
			   SET handler_class = in_handler_class,
			   	   handler_pkg = in_handler_pkg,
			   	   node_js_path = in_node_js_path,
			   	   description = in_description,
			   	   editor_card_group_id = in_editor_card_group_id
			 WHERE component_type_id = in_type_id;
	END;
END;

PROCEDURE ClearSources
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearSources can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
)
AS
BEGIN
	AddSource(in_type_id, in_action, in_text, in_description, null);
END;


PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
)
AS
	v_max_pos				component_source.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddSource can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_action <> LOWER(TRIM(in_action)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Actions must be formatted as trimmed and lower case');
	END IF;
	
	ActivateType(in_type_id);
	
	SELECT MAX(position)
	  INTO v_max_pos
	  FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO component_source
	(component_type_id, card_text, progression_action, description_xml, card_group_id, position)
	VALUES
	(in_type_id, in_text, in_action, in_description, in_card_group_id, NVL(v_max_pos, 0) + 1);
	
	-- I don't think there's anything wrong with adding the actions to both cards, but feel free to correct this...
	card_pkg.AddProgressionAction('Chain.Cards.ComponentSource', in_action);
	card_pkg.AddProgressionAction('Chain.Cards.ComponentBuilder.ComponentSource', in_action);
END;

PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, progression_action, card_text, description_xml
		  FROM component_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NVL(card_group_id, in_card_group_id) = in_card_group_id
		 ORDER BY position;
END;

PROCEDURE ClearTypeContainment
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTypeContainment can only be run as BuiltIn/Administrator');
	END IF;

	DELETE 
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE SetTypeContainment (
	in_container_type_id				IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id					IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags						IN chain_pkg.T_FLAG
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTypeContainment can only be run as BuiltIn/Administrator');
	END IF;
	
	ActivateType(in_container_type_id);
	ActivateType(in_child_type_id);
	
	BEGIN
		INSERT INTO component_type_containment
		(container_component_type_id, child_component_type_id)
		VALUES
		(in_container_type_id, in_child_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
		
	UPDATE component_type_containment
	   SET allow_add_existing = chain_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_EXISTING),
	       allow_add_new = chain_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_NEW)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_type_id = in_container_type_id
	   AND child_component_type_id = in_child_type_id;

END;

PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	FillTypeContainment;
	
	OPEN out_cur FOR
		SELECT * FROM tt_component_type_containment;
END;

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN
AS
	v_type_id		chain_pkg.T_COMPONENT_TYPE;
BEGIN
	BEGIN
		SELECT component_type_id
		  INTO v_type_id
		  FROM component_bind
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	IF v_type_id = in_type_id THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;

FUNCTION GetCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN
	BEGIN
		SELECT company_sid 
		  INTO v_company_sid 
		  FROM component_bind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
		
	RETURN v_company_sid;
	
END;

FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_deleted				component.deleted%TYPE;
BEGIN
	-- don't worry about sec as there's not much we can do with a bool flag...

	SELECT deleted
	  INTO v_deleted
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id;
	
	RETURN v_deleted = chain_pkg.DELETED;
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
)
AS
	v_top_component_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TT_COMPONENT_TREE
	 WHERE top_component_id = in_top_component_id;
	
	-- if we've already got entries, get out
	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	SELECT T_NUMERIC_ROW(in_top_component_id, NULL)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;
	
	RecordTreeSnapshot(v_top_component_ids);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
)
AS
	v_unrecorded_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT T_NUMERIC_ROW(item, NULL)
	  BULK COLLECT INTO v_unrecorded_ids
	  FROM TABLE(in_top_component_ids)
	 WHERE item NOT IN (SELECT top_component_id FROM TT_COMPONENT_TREE);
	 
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_unrecorded_ids);
	
	-- if there's nothing here, then they've all been collected
	IF v_count = 0 THEN
		RETURN;
	END IF;
	
	-- insert the top components
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT item, null, item, 0
	  FROM TABLE(v_unrecorded_ids);
	
	-- insert the tree
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT top_component_id, container_component_id, child_component_id, rownum
	  FROM (
			SELECT CONNECT_BY_ROOT container_component_id top_component_id, container_component_id, child_component_id
			  FROM component_relationship
			 START WITH container_component_id IN (SELECT item FROM TABLE(v_unrecorded_ids))
			CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
			 ORDER SIBLINGS BY position
		);
END;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetType(NULL, out_cur);	
END;

PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id		
		  FROM v$component_type
		 WHERE app_sid = security_pkg.GetApp
		   AND component_type_id = NVL(in_type_id, component_type_id);
END;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE
AS
	v_component_id			component.component_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF v_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		v_user_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/UserCreatorDaemon');
	END IF;
	
	IF NVL(in_component_id, 0) < 1 THEN

		INSERT INTO component 
		(component_id,  description, component_code, created_by_sid)
		VALUES 
		(component_id_seq.nextval, in_description, in_component_code, v_user_sid) 
		RETURNING component_id INTO v_component_id;
		
		INSERT INTO component_bind
		(component_id, component_type_id)
		VALUES
		(v_component_id, in_type_id);

	ELSE

		IF NOT IsType(in_component_id, in_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot save component with id '||in_component_id||' because it is not of type '||in_type_id);
		END IF;
		
		v_component_id := in_component_id;
		
		UPDATE component
		   SET description = in_description, 
			   component_code = in_component_code
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	END IF;
	
	RETURN v_component_id;
END;

PROCEDURE DeleteComponent (
	in_component_id		   	IN component.component_id%TYPE
)
AS
BEGIN
	IF IsDeleted(in_component_id) THEN
	   	RETURN;
    END IF;
	
	-- TODO: shouldn't DeleteComponent be checking the delete permission?
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE component 
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id; 
	
	-- call the handler
	EXECUTE IMMEDIATE GetHandlerPkg(GetTypeId(in_component_id))||'.DeleteComponent('||in_component_id||')';
	
	-- detach the component from everything
	DetachComponent(in_component_id);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT component_id, component_type_id, company_sid, created_by_sid, created_dtm, description, component_code
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id
		   AND deleted = chain_pkg.NOT_DELETED;
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT c.component_id, c.component_type_id, c.description, c.component_code, c.deleted, c.company_sid, c.created_by_sid, c.created_dtm
		  FROM v$component c, TT_COMPONENT_TREE ct
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND c.component_type_id = in_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	SearchComponents(in_page, in_page_size, in_search_term, NULL, out_count_cur, out_result_cur);
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	FillTypeContainment;
	
	-- bulk collect component id's that match our search result
	SELECT security.T_ORDERED_SID_ROW(component_id, null)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT c.component_id
		  FROM v$component c, tt_component_type_containment ctc
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND c.component_type_id = NVL(in_of_type, component_type_id)
		   AND c.component_type_id = ctc.child_component_type_id
		   AND ctc.container_component_type_id = in_container_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		   AND (   LOWER(description) LIKE v_search
				OR LOWER(component_code) LIKE v_search)
	  );
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) total_count,
		   CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
		  FROM TABLE(v_results);
			
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT *
			  FROM v$component c, TABLE(v_results) T
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.component_id = T.SID_ID
			   AND c.deleted = chain_pkg.NOT_DELETED
			 ORDER BY LOWER(c.description), LOWER(c.component_code);

	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*
						  FROM v$component c, TABLE(v_results) T
						 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND c.component_id = T.SID_ID
						   AND c.deleted = chain_pkg.NOT_DELETED
						 ORDER BY LOWER(c.description), LOWER(c.component_code)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
	v_position				component_relationship.position%TYPE;
	v_container_type_id		chain_pkg.T_COMPONENT_TYPE;
	v_child_type_id			chain_pkg.T_COMPONENT_TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	v_company_sid := component_pkg.GetCompanySid(in_container_id);
	
	IF v_company_sid <> component_pkg.GetCompanySid(in_child_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannont attach components which are owned by different companies');
	END IF;
	
	SELECT NVL(MAX(position), 0) + 1
	  INTO v_position
	  FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
	
	SELECT component_type_id
	  INTO v_container_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_container_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	SELECT component_type_id
	  INTO v_child_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	BEGIN 
		INSERT INTO component_relationship
		(container_component_id, container_component_type_id, child_component_id, child_component_type_id, company_sid, position)
		VALUES
		(in_container_id, v_container_type_id, in_child_id, v_child_type_id, v_company_sid, v_position);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;


PROCEDURE DetachComponent (
	in_component_id			IN component.component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	-- fully delete component relationship, no matter whether this component is the parent or the child
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (child_component_id = in_component_id OR container_component_id = in_component_id);
END;

PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	-- fully delete all child attachments
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
END;

PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE) ;

	-- delete component relationship
	DELETE FROM component_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id
	   AND child_component_id = in_child_id;

END;

/*
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE
AS
	v_top_component_ids		T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	SELECT T_NUMERIC_ROW(in_top_component_id, 0)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;	
	
	RETURN GetComponentTreeIds(v_top_component_ids);
END;

FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	-- this intentionally barfs if we get more than one company_sid
	SELECT cb.company_sid
	  INTO v_company_sid
	  FROM component_bind cb, TABLE(in_top_component_ids) c
	 WHERE cb.component_id = c.item
	 GROUP BY cb.company_sid;
	
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(child_component_id, rn)
	  BULK COLLECT INTO v_component_ids
	  FROM (
	  		-- add the rownum
	  		SELECT child_component_id, rownum rn 
	  		  FROM (
				-- get unique ids
				SELECT UNIQUE child_component_id
				  FROM (
				  	-- include all of the top_component_ids that we've passed in
					SELECT item child_component_id FROM TABLE(in_top_component_ids)
					 UNION ALL
					-- wrap it to accomodate the order by / union
					SELECT child_component_id
					  FROM (
					    -- walk the tree
						SELECT child_component_id
						  FROM component_relationship
						 WHERE app_sid = security_pkg.GetApp
						 START WITH container_component_id IN (SELECT item FROM TABLE(in_top_component_ids))
					   CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
						 ORDER SIBLINGS BY position
						   )
				   )
			   )
		   );
	
	RETURN v_component_ids;
END;
*/
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT child_component_id, container_component_id
		  FROM TT_COMPONENT_TREE
		 WHERE top_component_id = in_top_component_id
		 ORDER BY position;
END;

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/


PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF NOT IsType(in_component_id, chain_pkg.NOTSURE_COMPONENT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot change component type to '||in_to_type_id||'of component with id '||in_component_id||' because it is not a NOT SURE component');
	END IF;
	
	-- THIS MAY BARF - I've set the constraint to deferrable initially deferred, so I _think_ it should be ok...
	
	UPDATE component_bind
	   SET component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	UPDATE component_relationship
	   SET child_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND child_component_id = in_component_id;
	
	UPDATE component_relationship
	   SET container_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_component_id;
	
	GetType(in_to_type_id, out_cur); 
END;

END component_pkg;
/

 
CREATE OR REPLACE PACKAGE BODY chain.purchased_component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/

PROCEDURE RefeshSupplierActions (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
	v_action_id				action.action_id%TYPE;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component pc, v$supplier_relationship sr
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = sr.app_sid
	   AND pc.company_sid = in_company_sid
	   AND pc.company_sid = sr.purchaser_company_sid
	   AND pc.supplier_company_sid = in_supplier_company_sid
	   AND pc.supplier_company_sid = sr.supplier_company_sid
	   AND pc.acceptance_status_id = chain_pkg.ACCEPT_PENDING;
	
	IF v_count = 0 THEN
		-- clear the action
		SELECT MIN(action_id)
		  INTO v_action_id
		  FROM action
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND for_company_sid = in_supplier_company_sid
		   AND related_company_sid = in_company_sid
		   AND is_complete = 0
		   AND reason_for_action_id = action_pkg.GetReasonForActionId(action_pkg.AC_RA_PRD_PURCHASER_MAP_NEEDED);
		
		IF v_action_id IS NOT NULL THEN
			action_pkg.CompleteAction(v_action_id);
		END IF;
	ELSE
		-- set the action
		-- this action won't add twice
		action_pkg.AddAction(
			in_supplier_company_sid, 
			null, 
			in_company_sid, 
			null,
			null, 
			null, 
			action_pkg.GetReasonForActionId(action_pkg.AC_RA_PRD_PURCHASER_MAP_NEEDED), 
			null, 
		v_action_id);		
	END IF;

END;

PROCEDURE CollectToCursor (
	in_component_ids		IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pc.component_id, pc.description, pc.component_code, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				-- supplier data
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, pcs.supplier_country_code, pcs.supplier_country_name
		  FROM v$purchased_component pc, v$purchased_component_supplier pcs, TABLE(in_component_ids) i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = pcs.app_sid
		   AND pc.component_id = i.item
		   AND pc.component_id = pcs.component_id
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY i.pos;
END;

-- note that this procedure could be called by either the supplier or purchaser 
-- (if the purcher component is being deleted)
-- i.e. - be careful about getting the company sid from sys context
PROCEDURE SetSupplier (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID
)
AS
	v_cur_data				purchased_component%ROWTYPE;
	v_supplier_type_id		component_supplier_type.component_supplier_type_id%TYPE;
	v_current_supplier_sid	security_pkg.T_SID_ID;		
BEGIN
	
	-- figure out which type of supplier we're attaching to...
	IF NVL(in_supplier_sid, 0) > 0 THEN
		-- activate the virtual relationship so that we can attach to companies with pending relationships as well
		company_pkg.ActivateVirtualRelationship(in_supplier_sid);
		
		IF uninvited_pkg.IsUninvitedSupplier(in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.UNINVITED_SUPPLIER;
		ELSIF company_pkg.IsSupplier(in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.EXISTING_SUPPLIER;
		ELSIF company_pkg.IsPurchaser(in_supplier_sid) THEN 
			v_supplier_type_id := chain_pkg.EXISTING_PURCHASER;
		END IF;
		
		company_pkg.DeactivateVirtualRelationship(in_supplier_sid);
		
		IF v_supplier_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied attaching to company with sid ('||in_supplier_sid||') - they are not a current purchaser or supplier');
		END IF;
	ELSE
		v_supplier_type_id := chain_pkg.SUPPLIER_NOT_SET;
	END IF;
	
	BEGIN
		-- try to setup minimum data in case it doesn't exist already
		INSERT INTO purchased_component
		(component_id, component_supplier_type_id)
		VALUES
		(in_component_id, chain_pkg.SUPPLIER_NOT_SET);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- get the current data
	SELECT *
	  INTO v_cur_data
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	-- this is a bit of a strange way, but I think we're best to have an update statement per 
	-- supplier_type entry as the data that we need is highly dependant on this state
	
	IF v_supplier_type_id = chain_pkg.SUPPLIER_NOT_SET THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	
	ELSIF v_supplier_type_id = chain_pkg.UNINVITED_SUPPLIER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = in_supplier_sid,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_PURCHASER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = in_supplier_sid,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_SUPPLIER 
	  -- ONLY DO THIS IF THE SUPPLIER COMPANY IS CHANGING
	  AND (    v_cur_data.component_supplier_type_id <> chain_pkg.EXISTING_SUPPLIER 
	  		OR v_cur_data.supplier_company_sid <> in_supplier_sid
	  	  )
	 THEN
	  
		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = chain_pkg.ACCEPT_PENDING,
			   supplier_company_sid = in_supplier_sid,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
	
		-- if it was an existing supplier
		IF v_cur_data.component_supplier_type_id = chain_pkg.EXISTING_SUPPLIER THEN
			RefeshSupplierActions(v_cur_data.company_sid, v_cur_data.supplier_company_sid);
		END IF;
		
		RefeshSupplierActions(v_cur_data.company_sid, in_supplier_sid);
	END IF;
END;

/**********************************************************************************
	PUBLIC -- ICOMPONENT HANDLER PROCEDURES
**********************************************************************************/

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	v_component_id := component_pkg.SaveComponent(in_component_id, chain_pkg.PURCHASED_COMPONENT, in_description, in_component_code);
	
	SetSupplier(v_component_id, in_supplier_sid);
	
	GetComponent(v_component_id, out_cur);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;

	SELECT T_NUMERIC_ROW(in_component_id, null)
	  BULK COLLECT INTO v_component_ids
	  FROM v$purchased_component 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	SELECT T_NUMERIC_ROW(component_id, rownum)
	  BULK COLLECT INTO v_component_ids
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc, TT_COMPONENT_TREE ct
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PURCHASED_COMPONENT
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position
	);
		
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	SetSupplier(in_component_id, NULL);	
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
) 
AS
	v_count						NUMBER(10);
BEGIN
	-- make sure that the company clearing the supplier is either the supplier company, or the component owner company
	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND component_id = in_component_id
	   AND (	company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   		 OR supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   );

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied clearing the supplier for purchased component with id '||in_component_id||' where you are niether the owner or supplier company');
	END IF;
	
	SetSupplier(in_component_id, NULL);	
END;

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_purchaser_company_sid
		   AND (
		   			supplier_company_sid = in_supplier_company_sid
		   		 OR purchaser_company_sid = in_supplier_company_sid
		   	   )
	) LOOP
		SetSupplier(r.component_id, in_supplier_company_sid);	
	END LOOP;
END;

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_product_ids				T_NUMERIC_TABLE;
	v_total_count				NUMBER(10);
BEGIN

	/*
	IF NOT capability_pkg.CheckCapability(in_purchaser_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||in_purchaser_company_sid);
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	
	-- collect all of the PURCHASERS products
	SELECT T_NUMERIC_ROW(product_id, NULL)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = NVL(in_purchaser_company_sid, company_sid)
	   AND deleted = chain_pkg.NOT_DELETED;
	
	-- take a snap shot of these trees
	component_pkg.RecordTreeSnapshot(v_product_ids);
	
	-- fill the id table with all valid purchased components, owned by the purchaser company, and supplied by our company
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id, position)
	SELECT component_id, rownum
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc, TT_COMPONENT_TREE ct, (
		  		SELECT app_sid, product_id, description, code1, code2, code3
		  		  FROM v$product 
		  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  		   AND deleted = chain_pkg.NOT_DELETED
		  	   ) p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.app_sid = c.app_sid
		   AND pc.component_id = ct.child_component_id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = p.product_id(+)
		   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.acceptance_status_id = NVL(in_accept_status, pc.acceptance_status_id)
		   AND (
		   			pc.description LIKE v_search
		   		 OR pc.component_code LIKE v_search
		   		 OR p.description LIKE v_search
		   		 OR p.code1 LIKE v_search
		   		 OR p.code2 LIKE v_search
		   		 OR p.code3 LIKE v_search
		       )
		 ORDER BY LOWER(c.name), LOWER(pc.description)
		);

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position < NVL(in_start, 0)
		OR position >= NVL(in_start + in_page_size, v_total_count);
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_results_cur FOR
		SELECT c.name purchaser_company_name, pc.component_id, pc.description component_description, pc.component_code, pc.acceptance_status_id, 
				p.product_id, p.description product_description, p.code1, p.code2, p.code3
		  FROM v$purchased_component pc, TT_ID i, v$product p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.component_id = i.id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_company_sid = p.company_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		 ORDER BY i.position;
END;

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	       acceptance_status_id = chain_pkg.ACCEPT_PENDING
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;

	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	   	   acceptance_status_id = chain_pkg.ACCEPT_REJECTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
END;

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = in_product_id,
		   acceptance_status_id = chain_pkg.ACCEPT_ACCEPTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
	
	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;


END purchased_component_pkg;
/
 
CREATE OR REPLACE PACKAGE BODY chain.product_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_product_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to products for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to products for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

PROCEDURE CollectToCursor (
	in_product_ids			IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.pseudo_root_component_id, p.active, p.code1, p.code2, p.code3, 
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				'Open' status
		  FROM v$product p, TABLE(in_product_ids) i
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = i.item
		 ORDER BY i.pos;
END;

/**********************************************************************************
	PRODUCT CALLS
**********************************************************************************/

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE
) RETURN NUMBER
AS
	v_product_id			product.product_id%TYPE;
	v_pct					product_code_type%ROWTYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	-- this will do in the place of a NOT NULL on the column (not all components require a code)
	IF in_code1 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL component_code (code1)');
	END IF;
	
	v_product_id := component_pkg.SaveComponent(in_product_id, chain_pkg.PRODUCT_COMPONENT, in_description, in_code1);
	
	BEGIN
		-- we select this into a variable to be sure that the entry exists, an insert based on select would fail silently
		SELECT *
		  INTO v_pct
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
		INSERT INTO product
		(product_id, pseudo_root_component_id, code2_mandatory, code2, code3_mandatory, code3)
		VALUES
		(v_product_id, v_product_id, v_pct.code2_mandatory, in_code2, v_pct.code3_mandatory, in_code3);
		
		chain_link_pkg.AddProduct(v_product_id);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE product
			   SET code2 = in_code2,
			       code3 = in_code3
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   		   AND product_id = v_product_id;
	END;

	
	RETURN v_product_id;
END;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
    component_pkg.DeleteComponent(in_product_id);    
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM v$purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_supplier_type_id = chain_pkg.EXISTING_SUPPLIER
		   AND supplier_product_id = in_component_id
		   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	) LOOP
		purchased_component_pkg.ClearSupplier(r.component_id);	
    END LOOP;
END;


PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_READ);

	SELECT T_NUMERIC_ROW(product_id, null)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||in_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT product_id
		  FROM v$product
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND deleted = chain_pkg.NOT_DELETED
		 ORDER BY LOWER(description), LOWER(code1)
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

-- this is required for component implementation
PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetProduct(in_component_id, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT p.product_id
		  FROM v$product p, TT_COMPONENT_TREE ct
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PRODUCT_COMPONENT
		   AND p.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

PROCEDURE SearchProducts (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_top_component_ids			T_NUMERIC_TABLE;
	v_product_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200) DEFAULT 'LOWER(p.'||in_sort_by||') '||in_sort_dir;
	v_sort_sql					VARCHAR2(4000);
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'code1', 'code2', 'code3', 'status') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	IF LOWER(in_sort_by) = 'status' THEN
		-- clear the order by as the only status that we have right now is 'Open'
		v_order_by := '';
	ELSIF LOWER(in_sort_by) = 'customer' THEN
		-- remap the order by
		v_order_by := 'LOWER(t.value) '||in_sort_dir;
	END IF;
	
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(p.description) '||in_sort_dir;
	END IF;
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id)
	SELECT product_id
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   -- don't show deleted unless it's been asked for
	   AND (deleted = chain_pkg.NOT_DELETED OR in_show_deleted = 1)
	   -- show all products unless we want to only show needs review ones
	   AND ((need_review = chain_pkg.ACTIVE AND in_only_show_need_review = 1) OR in_only_show_need_review = 0)
	   AND (   LOWER(description) LIKE v_search
			OR LOWER(code1) LIKE v_search
			OR LOWER(code2) LIKE v_search
			OR LOWER(code3) LIKE v_search
		   );

	-- if we're looking at a specific purchaser company, remove any products that we don't supply to them
	IF in_purchaser_company_sid IS NOT NULL THEN
		
		DELETE 
		  FROM TT_ID 
		 WHERE id NOT IN (
		 	SELECT supplier_product_id
		 	  FROM v$purchased_component
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND company_sid = in_purchaser_company_sid
		 	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 );
		 
	END IF;
	
	-- if we're looking at a specific supplier company, then we need to drill down the component tree and find all of our purchased components
	IF in_supplier_company_sid IS NOT NULL THEN
		
		SELECT T_NUMERIC_ROW(id, rownum)
	  	  BULK COLLECT INTO v_top_component_ids
	  	  FROM TT_ID;
		
		component_pkg.RecordTreeSnapshot(v_top_component_ids);
		v_record_called := TRUE;
		
		DELETE 
		  FROM TT_ID
		 WHERE id NOT IN (
		 	SELECT ct.top_component_id
		 	  FROM TT_COMPONENT_TREE ct, TT_ID i, v$purchased_component pc
		 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND pc.component_id = ct.child_component_id
		 	   AND (pc.supplier_company_sid = in_supplier_company_sid)
		 	   AND ct.top_component_id = i.id
		 	   AND pc.deleted = chain_pkg.NOT_DELETED
		 );
		 
	END IF;
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	
	-- if the sort by is a column in the v$product view...
	IF LOWER(in_sort_by) IN ('description', 'code1', 'code2', 'code3', 'status') THEN
	
		v_sort_sql := ''||
			'	SELECT p.product_id '||
			'	  FROM v$product p, TT_ID t '||
			'	 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
			'	   AND p.product_id = t.id '||
			'	 ORDER BY '||v_order_by;
	
	/* -- the page doesn't let you do this!
	ELSIF LOWER(in_sort_by) = 'customer' THEN
	
		v_sort_sql := ''||
			'	SELECT id product_id, min(rn) '||
			'	  FROM ( '||
			'		SELECT i.id, rownum rn '||
			'		  FROM ( '||
			'		  	SELECT id  '||
			'		  	  FROM TT_ORDERED_PARAM  '||
			'			 ORDER BY '||v_order_by||
			'		  	 ) i '||
			'		 ) '||
			'	GROUP BY id';
	*/			
	END IF;
	
	EXECUTE IMMEDIATE ''||
		'UPDATE TT_ID i '||
		'   SET position = ( '||
		'		SELECT r.rn '||
		'		  FROM ('||
		'			SELECT product_id, rownum rn '||
		'			  FROM ('||v_sort_sql||') '||
		'			) r '||
		'		 WHERE i.id = r.product_id '||
		'   )';
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position < NVL(in_start, 0)
	    OR position >= NVL(in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_purchaser_cur FOR
		SELECT pc.supplier_product_id product_id, c.company_sid, c.name
		  FROM v$purchased_component pc, v$company c, TT_ID i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = i.id
		   AND pc.deleted = chain_pkg.NOT_DELETED
	 	 ORDER BY LOWER(c.name);
	
	
	IF NOT v_record_called THEN
		SELECT T_NUMERIC_ROW(id, rownum)
		  BULK COLLECT INTO v_top_component_ids
		  FROM TT_ID;

		component_pkg.RecordTreeSnapshot(v_top_component_ids);
	END IF;
	
	OPEN out_supplier_cur FOR
		SELECT i.id product_id, c.company_sid, c.name
		  FROM TT_COMPONENT_TREE ct, TT_ID i, v$purchased_component pc, v$company c
	 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND pc.app_sid = c.app_sid
		   AND pc.component_id = ct.child_component_id
		   AND pc.supplier_company_sid = c.company_sid
	 	   AND ct.top_component_id = i.id
		   AND pc.deleted = chain_pkg.NOT_DELETED
	 	 ORDER BY LOWER(c.name);
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_product_ids
	  FROM TT_ID;
	
	CollectToCursor(v_product_ids, out_product_cur);
END;


PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
			SELECT product_id
			  FROM v$product
			 WHERE created_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND created_dtm > SYSDATE - 7 -- let's give them a week as the row limit will take care of too many
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 ORDER BY created_dtm DESC
			)
	 WHERE rownum <= 3;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product code types for company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT code_label1, code_label2, code_label3, code2_mandatory, code3_mandatory
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodes (
    in_company_sid      	IN  security_pkg.T_SID_ID,
	in_code_label1			IN  product_code_type.code_label1%TYPE,
	in_code_label2			IN  product_code_type.code_label2%TYPE,
	in_code_label3			IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory		IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory		IN 	product_code_type.code3_mandatory%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	-- this will blowup if we're setting to mandatory and any of the existing products have null vals...
	UPDATE product
	   SET code2_mandatory = in_code2_mandatory,
		   code3_mandatory = in_code3_mandatory
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	UPDATE product_code_type
	   SET code_label1 = TRIM(in_code_label1),
		   code_label2 = TRIM(in_code_label2),
		   code_label3 = TRIM(in_code_label3),
		   code2_mandatory = in_code2_mandatory,
		   code3_mandatory = in_code3_mandatory
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
)
AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	-- we'll let this blow up if it already exists because I'm not sure what the correct response is if this is called twice
	INSERT INTO product_code_type 
	(company_sid) 
	VALUES (in_company_sid);
	
END;


PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product codes for company with sid '||in_company_sid);
	END IF;

	SELECT mapping_approval_required
	  INTO out_mapping_approval_required
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE product_code_type
	   SET mapping_approval_required = in_mapping_approval_required
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);

	UPDATE product 
	   SET active = in_active
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product 
	   SET need_review = in_need_review
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE product 
	   SET pseudo_root_component_id = in_component_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


END product_pkg;
/
 
CREATE OR REPLACE PACKAGE BODY chain.chain_link_pkg
IS

PROCEDURE CallLinkProc (
	in_proc_call				IN  VARCHAR2,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE DEFAULT NULL
)
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE := NULL;
	PROC_NOT_FOUND				EXCEPTION;
	PRAGMA EXCEPTION_INIT (PROC_NOT_FOUND, -06550);
BEGIN
	IF in_questionnaire_id IS NOT NULL THEN
		-- use the helper for the questionnaire_type if possible
		SELECT db_class
		  INTO v_helper_pkg
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND questionnaire_id = in_questionnaire_id;
	END IF;
	
	IF v_helper_pkg IS NULL THEN 
		-- default to company
		BEGIN
			SELECT company_helper_sp
			  INTO v_helper_pkg 
			  FROM customer_options co
			 WHERE app_sid = security_pkg.getApp;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	   	 
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || v_helper_pkg || '.' || in_proc_call || ';END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;


PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('AddCompanyUser(' || in_user_sid || ', ' || 
									in_company_sid || ')');
END;

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('AddCompany(' || in_company_sid || ')');
END;

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('DeleteCompany(' || in_company_sid || ')');
END;

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN  security_pkg.T_SID_ID,
	in_from_user_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('InviteCreated(' || in_invitation_id || ', ' ||
									in_from_company_sid || ', ' ||
									in_from_user_sid || ', ' ||
									in_to_user_sid || ')');
END;

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	CallLinkProc('QuestionnaireAdded(' || in_from_company_sid || ', ' ||
											in_to_company_sid || ', ' ||
											in_to_user_sid || ', ' ||
											in_questionnaire_id || ')', in_questionnaire_id);
END;

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateCompany(' || in_company_sid || ')');
END;


PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateUser(' || in_user_sid || ')');
END;


PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ApproveUser(' || in_company_sid || ', ' ||
									in_user_sid || ')');
END;

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateRelationship(' || in_purchaser_company_sid || ', ' ||
											in_supplier_company_sid || ')');
END;

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_comp_helper				customer_options.company_helper_sp%TYPE;
	/*
		For some reason, if you pass out_titles in to the execute immediate statement
		it barfs on linux with an invalid cursor exception when returning the cursor
		to the webserver, although it works fine on Win7 x64.
		The solution appears to be declaring another cursor locally, assigning it to
		that and then passing it back out
	*/
	c_titles					security_pkg.T_OUTPUT_CUR;
	e_proc_not_found			EXCEPTION;
	PRAGMA EXCEPTION_INIT (e_proc_not_found, -06550);
BEGIN
	SELECT COMPANY_HELPER_SP INTO v_comp_helper 
							 FROM customer_options
							WHERE app_sid=security_pkg.getApp;
	IF v_comp_helper IS NOT NULL THEN
		BEGIN
            execute immediate (
				'BEGIN ' || v_comp_helper || '.GetWizardTitles(:card_group,:out_titles);END;'
			) USING in_card_group_id, c_titles;
			out_titles := c_titles;
			RETURN;
		EXCEPTION
			WHEN e_proc_not_found THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	OPEN out_titles FOR 
		SELECT NULL AS WIZARD_TITLE, NULL AS WIZARD_SUB_TITLE FROM dual;
END;

PROCEDURE AddProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	CallLinkProc('AddProduct(' || in_product_id || ')');
END;

PROCEDURE KillProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	CallLinkProc('KillProduct(' || in_product_id || ')');
END;

PROCEDURE FilterComponentTypeContainment
AS
BEGIN
	CallLinkProc('FilterComponentTypeContainment()');
END;

END chain_link_pkg;
/ 

CREATE OR REPLACE PACKAGE BODY chain.action_pkg
IS

PROCEDURE AddActionINTERNAL (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
)
AS
	v_action_id							action.action_id%TYPE;
	v_action_repeat_type_id				reason_for_action.action_repeat_type_id%TYPE;
	v_just_add_new_action				NUMBER(1) := 0;
BEGIN
	
	-- some action types are actions that should only appear once
	-- if they happen again (and aren't complete and therefore hidden) reset the timestamp, duedtm, reason data

	-- get the action repeat type
	SELECT action_repeat_type_id
	  INTO v_action_repeat_type_id
	  FROM reason_for_action ra
	 WHERE ra.app_sid = security_pkg.GetApp
	   AND ra.reason_for_action_id = in_reason_for_action_id;


	IF v_action_repeat_type_id = action_pkg.AC_REP_ALLOW_MULTIPLE THEN
		-- this is the usual case - insert and brand new action
		v_just_add_new_action := 1;
	ELSE

		-- find any incomplete action with the same
		-- for company, for user, related company, related user, related questionnaire and reason for action id

		-- TO DO - might want to match the above without looking at from users and update who the action has come from
		-- as a new action_repeat_type - but we don't have any action like this atm

		-- in these cases should only be one action but get latest (and MAX id if identical dtm) action id rather than
		-- assume only one in case action repeat type has changed for this action reason type

		BEGIN
			SELECT MAX(action_id)
			  INTO v_action_id
			  FROM action A
			 WHERE app_sid = security_pkg.GetApp
			   AND for_company_sid 						= in_for_company_sid   -- non null
			   AND NVL(for_user_sid, -1) 				= NVL(in_for_user_sid, -1)
			   AND NVL(related_company_sid, -1) 		= NVL(in_related_company_sid, -1)
			   AND NVL(related_user_sid, -1) 			= NVL(in_related_user_sid, -1)
			   AND NVL(related_questionnaire_id, -1) 	= NVL(in_related_questionnaire_id, -1)
			   AND NVL(reason_for_action_id, -1) 		= NVL(in_reason_for_action_id, -1)
			   AND is_complete = 0
			   AND SYSDATE =   (SELECT MAX(SYSDATE)
								  FROM action A
								 WHERE app_sid = security_pkg.GetApp
								   AND for_company_sid 						= in_for_company_sid   -- non null
								   AND NVL(for_user_sid, -1) 				= NVL(in_for_user_sid, -1)
								   AND NVL(related_company_sid, -1) 		= NVL(in_related_company_sid, -1)
								   AND NVL(related_user_sid, -1) 			= NVL(in_related_user_sid, -1)
								   AND NVL(related_questionnaire_id, -1) 	= NVL(in_related_questionnaire_id, -1)
								   AND NVL(reason_for_action_id, -1) 		= NVL(in_reason_for_action_id, -1)
								   AND is_complete = 0
				)
				GROUP BY action_id;

			-- if we are here we have an existing action
			out_action_id := v_action_id;

			CASE v_action_repeat_type_id
				WHEN action_pkg.AC_REP_NO_MULTIPLE_UPDATE_DTM THEN

					-- update the action
					UPDATE action
					   SET
							due_date = in_due_date,
							reason_data = in_reason_data,
							created_dtm = SYSDATE
					 WHERE action_id = v_action_id
					   AND app_sid = security_pkg.GetApp;
				WHEN action_pkg.AC_REP_NO_MULTIPLE_LEAVE_DTM THEN
					-- do nothing - leave well alone
					NULL;
				WHEN action_pkg.AC_REP_REOPEN THEN
					-- update the action
					UPDATE action
					   SET
							due_date = in_due_date,
							reason_data = in_reason_data,
							created_dtm = SYSDATE,
							is_complete = 0
					 WHERE action_id = v_action_id
					   AND app_sid = security_pkg.GetApp;
			END CASE;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- no matches
				v_just_add_new_action := 1;
		END;

	END IF;

	-- we are actually OK to just add the new action
	IF v_just_add_new_action = 1 THEN
		INSERT INTO action (
			app_sid,
			action_id,
			for_company_sid,
			for_user_sid,
			related_company_sid,
			related_user_sid,
			related_questionnaire_id,
			created_dtm,
			due_date,
			reason_for_action_id,
			reason_data
		) VALUES (
			security_pkg.GetApp,
			action_id_seq.NEXTVAL,
			in_for_company_sid,
			in_for_user_sid,
			in_related_company_sid,
			in_related_user_sid,
			in_related_questionnaire_id,
			SYSDATE,
			in_due_date,
			in_reason_for_action_id,
			in_reason_data
		) RETURNING action_id INTO v_action_id;
	END IF;


	out_action_id := v_action_id;

END;

PROCEDURE AddAction (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
)
AS
BEGIN

	-- we have to do this as we may be setting removing actions for a company yet to confirm 
	company_pkg.ActivateVirtualRelationship(in_for_company_sid);
	
	IF NOT capability_pkg.CheckCapability(in_for_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_for_company_sid);
	END IF;
	
	
	
	AddActionINTERNAL (
		in_for_company_sid,
		in_for_user_sid,
		in_related_company_sid,
		in_related_user_sid,
		in_related_questionnaire_id,
		in_due_date,
		in_reason_for_action_id,
		in_reason_data,
		out_action_id
	);
	
	company_pkg.DeactivateVirtualRelationship(in_for_company_sid);

END;

PROCEDURE CompleteAction (
	in_action_id		IN  action.action_id%TYPE
)
AS
BEGIN
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE app_sid = security_pkg.GetApp
	   AND action_id = in_action_id;
END;


PROCEDURE GetActions (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetActions(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_start, in_page_size, out_cur);
END;

PROCEDURE GetActions (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to actions for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT * FROM
		(
			SELECT ROWNUM rn, A.* FROM
			(
				SELECT for_company_sid, for_company_name, for_company_url, for_user_sid, for_user_full_name, for_user_friendly_name,
						for_user_url, related_company_sid, related_company_name, related_company_url, related_user_sid, related_user_full_name,
						related_user_friendly_name, related_user_url, related_questionnaire_id, related_questionnaire_name, related_questionnaire_url,
						action_id, created_dtm, due_date, is_complete, completion_dtm, other_url_1, other_url_2, other_url_3, reason_for_action_id,
						reason_for_action_name, reason_for_action_description, action_type_id, message_template, priority, for_whom, is_for_user, css_class
				  FROM v$action
				 WHERE app_sid = security_pkg.GetApp
				   AND for_company_sid = in_company_sid
				   AND (for_user_sid IS NULL OR (for_user_sid = NVL(v_user_sid, -1)))
				   AND is_complete = 0
				ORDER BY priority, created_dtm DESC, NVL(for_user_sid, -1), NVL2(for_user_sid, 1, 0) DESC
			) A
			WHERE ((in_page_size IS NULL) OR (ROWNUM <= in_start+in_page_size))
			ORDER BY priority, created_dtm DESC, is_for_user DESC
		)
		WHERE rn > in_start
		ORDER BY priority, created_dtm DESC, is_for_user DESC;

END;

FUNCTION GetReasonForActionId (
	in_reason_class		reason_for_action.CLASS%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	BEGIN
        SELECT reason_for_action_id
          INTO v_ret
          FROM reason_for_action
         WHERE CLASS = in_reason_class
           AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			raise_application_error (-20100,'Cannot find reason class ' || in_reason_class || ' for app_sid=' || security_pkg.GetApp);
	END;
	RETURN v_ret;
END;

-- Helper functions - certain repetitive things need to do actions for

-- Creating a company
PROCEDURE AddCompanyDoActions (
	in_new_company_sid			security_pkg.T_SID_ID
)
AS
	v_action_id					action.action_id%TYPE;
BEGIN
	-- ensure that we can write suppliers - that's good enough for now as the company isn't a supplier when it's created
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to suppliers for company with sid '||company_pkg.GetCompany||' for user with sid '||security_pkg.GetSid);
	END IF;

	AddActionINTERNAL(in_new_company_sid, NULL, NULL, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_FIRST_REGISTRATION), NULL, v_action_id);
END;


-- Adding / registering a user
PROCEDURE AddUserDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
)
AS
	v_action_id					action.action_id%TYPE;
	v_dc						chain_user.details_confirmed%TYPE;
BEGIN
	SELECT details_confirmed
	  INTO v_dc
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURItY', 'APP')
	   AND user_sid = in_user_sid;

	IF v_dc = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;

	AddActionINTERNAL(in_company_sid, in_user_sid, NULL, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_USER_REGISTRATION), NULL, v_action_id);
END;


PROCEDURE ConfirmCompanyDetailsDoActions (
	in_company_sid			security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RETURN;
	END IF;
	
	-- actually we are just clearing actions here
	-- close the actions relating to this questionnaire type, for this company, being assigned
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_company_sid = in_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND 	(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_FIRST_REGISTRATION)) OR
			(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_COMPANY_DETAILS_CHANGED));

	UPDATE company
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

END;


PROCEDURE ConfirmUserDetailsDoActions (
	in_user_sid				security_pkg.T_SID_ID
)
AS
BEGIN
	-- actually we are just clearing actions here
	-- close the actions relating to this questionnaire type, for this user, being assigned
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_user_sid = in_user_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_USER_REGISTRATION);

	UPDATE chain_user
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

END;

PROCEDURE InviteQuestionnaireDoActions (
	in_to_company_sid			security_pkg.T_SID_ID,
	in_questionnaire_id			questionnaire.questionnaire_id%TYPE,
	in_from_company_sid			security_pkg.T_SID_ID,
	out_action_id				OUT action.action_id%TYPE
)
AS
	v_due_dtm					questionnaire_share.due_by_dtm%TYPE;
	v_action_id					action.action_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_to_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_to_company_sid);
	END IF;

	SELECT due_by_dtm 
	  INTO v_due_dtm 
	  FROM questionnaire_share 
	 WHERE app_sid = security_pkg.GetApp 
	   AND questionnaire_id = in_questionnaire_id
	   AND qnr_owner_company_sid = in_to_company_sid
	   AND share_with_company_sid = in_from_company_sid;
	
	AddActionINTERNAL(in_to_company_sid, NULL, in_from_company_sid, NULL, in_questionnaire_id, v_due_dtm, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_ASSIGNED), NULL, v_action_id);

	out_action_id := v_action_id;
END;

PROCEDURE ShareQuestionnaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT questionnaire_pkg.GetQuestionnaireId (in_qnr_owner_company_sid, in_questionnaire_class);
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_qnr_owner_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_qnr_owner_company_sid);
	END IF;
	
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE related_questionnaire_id = v_questionnaire_id
	   AND for_company_sid = in_qnr_owner_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_ASSIGNED);
	
	AddActionINTERNAL(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, NULL, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_SUBMITTED), NULL, v_action_id);
	-- message to the company that asked for the questionnaire
	event_pkg.AddEvent(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_SUBMITTED), v_event_id);
	-- message to company who submitted the quesionnaire
	event_pkg.AddEvent(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, NULL, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_SUBMITTED_SUP), v_event_id);
END;


-- approving questionnaire
PROCEDURE AcceptQuestionaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT  questionnaire_pkg.GetQuestionnaireId(in_qnr_owner_company_sid, in_questionnaire_class);
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_qnr_owner_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_qnr_owner_company_sid);
	END IF;

	-- close the actions relating to this questionnaire type, for this company, being assigned
	-- TODO: I think that this actions all questionnaires instead of just the one we're looking at
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE related_company_sid = in_qnr_owner_company_sid
	   AND for_company_sid = in_share_with_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND 	((reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_SUBMITTED)) OR 
			(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_DEPENDENT_DATA_UPDATED)));
	
	-- message to company who approved the quesionnaire
	event_pkg.AddEvent(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, NULL, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_APPROVED), v_event_id);

	-- add an action for the company that did the questionnaire telling them they can review their score
	AddActionINTERNAL(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, NULL, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_APPROVED), NULL, v_action_id);
	
	-- message to company who did the quesionnaire as well
	event_pkg.AddEvent(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_APPROVED_SUP), v_event_id);
END;

--- this is called the first time a user from a company views the
PROCEDURE ViewQResultsDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id	questionnaire.questionnaire_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	v_questionnaire_id := questionnaire_pkg.GetQuestionnaireId (in_company_sid, in_questionnaire_class);

	-- close the actions relating to this questionnaire type, for this company, being approved
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_company_sid = in_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND related_questionnaire_id = v_questionnaire_id
	   AND (reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_APPROVED));
END;

PROCEDURE StartActionPlanDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	event_pkg.AddEvent(v_company_sid, NULL, in_company_sid, NULL, NULL, NULL, event_pkg.GetEventTypeId(event_pkg.EV_ACTION_PLAN_STARTED), v_event_id);
END;

PROCEDURE CompanyDetailsUpdatedDoActions (
	in_company_sid				security_pkg.T_SID_ID
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
	v_risk_found				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	SELECT COUNT(*) INTO v_risk_found
	  FROM company_metric cm, company_metric_type cmt -- From metric_pkg.GetCompanyMetric
	 WHERE cm.app_sid = cmt.app_sid
	   AND cm.company_metric_type_id = cmt.company_metric_type_id
	   AND cm.app_sid = security_pkg.GetApp
	   AND cm.company_sid = in_company_sid
	   AND cmt.CLASS = 'CALCULATED_RISK';

	IF v_risk_found > 0 THEN
		AddActionINTERNAL(v_company_sid, NULL, in_company_sid, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_DEPENDENT_DATA_UPDATED), NULL, v_action_id);
	END IF;

	event_pkg.AddEvent(v_company_sid, NULL, in_company_sid, NULL, NULL, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_COMPANY_DETAILS_UPDATED), v_event_id);
END;


PROCEDURE CollectActionParams (
	in_action_ids			IN security.T_SID_TABLE
)
AS
BEGIN
	DELETE FROM tt_named_param;

	-- This is a bit dodgy. Actions and events have this concept of string replacement, but the parameters they're replacing can either contain HTML (in which case they shouldn't
	-- be escaped) or not (in which case they should be escaped). We seem to be relying on the fact that developers know which is which and whether the escaping has been done or
	-- not everywhere they're used.

	INSERT INTO tt_named_param
	(ID, name, VALUE)
	(
		SELECT action_id, 'FOR_COMPANY_SID' name, TO_CHAR(FOR_COMPANY_SID) VALUE FROM v$action WHERE FOR_COMPANY_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_COMPANY_NAME)) VALUE FROM v$action WHERE FOR_COMPANY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_COMPANY_URL' name, TO_CHAR(FOR_COMPANY_URL) VALUE FROM v$action WHERE FOR_COMPANY_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_SID' name, TO_CHAR(FOR_USER_SID) VALUE FROM v$action WHERE FOR_USER_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FULL_NAME)) VALUE FROM v$action WHERE FOR_USER_FULL_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FRIENDLY_NAME)) VALUE FROM v$action WHERE FOR_USER_FRIENDLY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_URL' name, TO_CHAR(FOR_USER_URL) VALUE FROM v$action WHERE FOR_USER_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_SID' name, TO_CHAR(RELATED_COMPANY_SID) VALUE FROM v$action WHERE RELATED_COMPANY_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_COMPANY_NAME)) VALUE FROM v$action WHERE RELATED_COMPANY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_URL' name, TO_CHAR(RELATED_COMPANY_URL) VALUE FROM v$action WHERE RELATED_COMPANY_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_SID' name, TO_CHAR(RELATED_USER_SID) VALUE FROM v$action WHERE RELATED_USER_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FULL_NAME)) VALUE FROM v$action WHERE RELATED_USER_FULL_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FRIENDLY_NAME)) VALUE FROM v$action WHERE RELATED_USER_FRIENDLY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_URL' name, TO_CHAR(RELATED_USER_URL) VALUE FROM v$action WHERE RELATED_USER_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_ID' name, TO_CHAR(RELATED_QUESTIONNAIRE_ID) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_ID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_QUESTIONNAIRE_NAME)) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_URL' name, TO_CHAR(RELATED_QUESTIONNAIRE_URL) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_1' name, TO_CHAR(OTHER_URL_1) VALUE FROM v$action WHERE OTHER_URL_1 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_2' name, TO_CHAR(OTHER_URL_2) VALUE FROM v$action WHERE OTHER_URL_2 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_3' name, TO_CHAR(OTHER_URL_3) VALUE FROM v$action WHERE OTHER_URL_3 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
	);
END;


PROCEDURE GenerateAlertEntries (
	in_as_of_dtm		IN TIMESTAMP
)
AS
	v_action_ids				security.T_SID_TABLE;
BEGIN
	-- NOTE: When this method is called via the scheduler, the logged on user is
	-- the builtin administrator, therefore, the user / company sids are not set
	-- in the sesstion
	NULL;

	SELECT action_id
	  BULK COLLECT INTO v_action_ids
	  FROM (
		-- get all events that have been created
		SELECT action_id
		  FROM v$action
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (created_dtm >= in_as_of_dtm OR completion_dtm >= in_as_of_dtm)
			);

	-- collect all of the params required for the events being submitted
	CollectActionParams(v_action_ids);

	-- submit our actions to the scheduler
	FOR r IN (
		SELECT A.*, cu.company_sid, cu.user_sid
		  FROM v$action A, v$company_user cu
		 WHERE A.app_sid = cu.app_sid
		   AND A.action_id IN (SELECT * FROM TABLE(v_action_ids))
		   AND A.for_company_sid = cu.company_sid
		   AND (A.for_user_sid IS NULL OR A.for_user_sid = cu.user_sid)
	) LOOP
		scheduled_alert_pkg.SetAlertEntry(
			chain_pkg.ACTION_ALERT,
			r.action_id,
			r.company_sid,
			r.user_sid,
			r.created_dtm,
			CASE WHEN r.completion_dtm IS NULL THEN 'DEFAULT' ELSE 'COMPLETED' END,
			r.message_template,
			chain_pkg.NAMED_PARAMS
		);
	END LOOP;
END;

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_for_company_url				IN	action_type.for_company_url%TYPE,
	in_related_questionnaire_url	IN	action_type.related_questionnaire_url%TYPE,
	in_related_company_url			IN	action_type.related_company_url%TYPE,
	in_for_user_url					IN	action_type.for_user_url%TYPE,
	in_other_url_1					IN	action_type.other_url_1%TYPE DEFAULT NULL,
	in_other_url_2					IN	action_type.other_url_2%TYPE DEFAULT NULL,
	in_other_url_3					IN	action_type.other_url_3%TYPE DEFAULT NULL,
	in_css_class					IN	action_type.css_class%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateActionType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
        INSERT INTO action_type ( 
            app_sid,
            action_type_id, 
            message_template, 
            priority, 
            for_company_url,
            related_questionnaire_url,
            related_company_url,
            for_user_url,
			other_url_1,
			other_url_2,
			other_url_3,
			css_class
        ) VALUES (
            security_pkg.getApp,
            in_action_type_id,
            in_message_template,
            in_priority,
            in_for_company_url,
            in_related_questionnaire_url,
            in_related_company_url,
            in_for_user_url,
			in_other_url_1,
			in_other_url_2,
			in_other_url_3,
			in_css_class
        );
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE action_type
			   SET	message_template=in_message_template,
					priority = in_priority,
					for_company_url = in_for_company_url,
        			related_questionnaire_url = in_related_questionnaire_url,
        			related_company_url = in_related_company_url,
					for_user_url = in_for_user_url,
					other_url_1 = in_other_url_1,
					other_url_2 = in_other_url_2,
					other_url_3 = in_other_url_3,
					css_class = in_css_class
			 WHERE app_sid = security_pkg.getApp
			   AND action_type_id = in_action_type_id;
	END;
END;

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_clear_urls					IN  BOOLEAN,
	in_css_class					IN	action_type.css_class%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateActionType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO action_type 
		(app_sid, action_type_id, message_template, priority, css_class)
		VALUES
        (security_pkg.getApp, in_action_type_id, in_message_template, in_priority, in_css_class);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE action_type
		   SET message_template = in_message_template,
			   priority = in_priority,
			   css_class = in_css_class
		 WHERE app_sid = security_pkg.getApp
		   AND action_type_id = in_action_type_id;

		IF in_clear_urls THEN
			ClearActionTypeUrls(in_action_type_id);
        END IF;
	END;
END;

PROCEDURE ClearActionTypeUrls (
	in_action_type_id				IN	action_type.action_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearActionTypeUrls can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE action_type
	   SET 	FOR_COMPANY_URL = NULL,
			FOR_USER_URL = NULL,
			RELATED_COMPANY_URL = NULL,
			RELATED_USER_URL = NULL,
			RELATED_QUESTIONNAIRE_URL = NULL,
			OTHER_URL_1 = NULL,
			OTHER_URL_2 = NULL,
			OTHER_URL_3 = NULL
	 WHERE app_sid = security_pkg.getApp
	   AND action_type_id = in_action_type_id;
END;


PROCEDURE SetActionTypeUrl (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
)
AS
	v_column_name					user_tab_columns.COLUMN_NAME%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetActionTypeUrl can only be run as BuiltIn/Administrator');
	END IF;

	-- basic stuff to prevent obvious errors, but as we need to run this as builtin admin, I don't see this getting called maliciously.
	BEGIN
		SELECT column_name
		  INTO v_column_name
		  FROM user_tab_columns
		 WHERE table_name = 'ACTION_TYPE'
		   AND column_name = UPPER(in_column_name)
		   AND (column_name LIKE '%_URL' OR column_name LIKE 'OTHER_URL_%');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, '"'||in_column_name||'" does not appear to be a url column');
	END;
	
	EXECUTE IMMEDIATE 'UPDATE action_type SET '||v_column_name||' = :url WHERE app_sid = security_pkg.GetApp AND action_type_id = :action_type_id'
	USING in_url, in_action_type_id;
END;




PROCEDURE CreateReasonForAction (
	in_reason_for_action_id		IN	reason_for_action.reason_for_action_id%TYPE,
	in_action_type_id			IN	reason_for_action.action_type_id%TYPE,
	in_class					IN	reason_for_action.CLASS%TYPE,
	in_reason_name				IN	reason_for_action.reason_name%TYPE,
	in_reason_desc				IN	reason_for_action.reason_description%TYPE,
	in_action_repeat_type_id	IN	reason_for_action.action_repeat_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateReasonForAction can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO reason_for_action (
			app_sid,
			reason_for_action_id, 
			action_type_id, 
			CLASS, 
			reason_name, 
			reason_description,
			action_repeat_type_id	
		) VALUES ( 
			security_pkg.getApp,
			in_reason_for_action_id,
			in_action_type_id,
			in_class,
			in_reason_name,
			in_reason_desc,
			NVL(in_action_repeat_type_id, action_pkg.AC_REP_ALLOW_MULTIPLE)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE reason_for_action 
					SET action_type_id=in_action_type_id,
					CLASS=in_class,
              		reason_name=in_reason_name,
              		reason_description=in_reason_desc,
					action_repeat_type_id=NVL(in_action_repeat_type_id, action_pkg.AC_REP_ALLOW_MULTIPLE)
			 WHERE app_sid=security_pkg.getApp
			   AND reason_for_action_id=in_reason_for_action_id;
	END;
END;



END action_pkg;
/

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
	  FROM old_component_type_containment
	 UNION ALL
	SELECT app_sid, container_component_type_id, child_component_type_id, 0 allow_add_existing, 0 allow_add_new
	  FROM (
		SELECT r.app_sid, con.component_type_id container_component_type_id, chi.component_type_id child_component_type_id
		  FROM old_cmpnt_cmpnt_relationship r, component_bind con, component_bind chi
		 WHERE r.app_sid = con.app_sid
		   AND r.app_sid = chi.app_sid
		   AND r.parent_component_id = con.component_id
		   AND r.component_id = chi.component_id
		 MINUS 
		SELECT app_sid, container_component_type_id, child_component_type_id
		  FROM old_component_type_containment
		);
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
	   AND r.supplier_product_id = p.product_id(+)
	   -- we need to include this (apparently!) because the old code appears to have allowed non-purchased components to be used in the cmpnt_prod_rel_pending table
	   AND (r.purchaser_component_id, chain_pkg.PURCHASED_COMPONENT, r.purchaser_company_sid) IN (
	   			SELECT component_id, component_type_id, company_sid
	   			  FROM component_bind
	   		);
END;
/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST03
/********************************************************/

ALTER TABLE chain.UNINVITED_SUPPLIER ADD(CREATED_AS_COMPANY_SID NUMBER(10, 0));

/********************************************************
	Put package in here rather than referencing as it is
	Likely we will move the methods to another package
	rather than a package just for uninvited suppliers
********************************************************/


CREATE OR REPLACE PACKAGE chain.uninvited_pkg
IS

PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_id	IN	NUMBER,
	in_created_as_company_sid	IN	NUMBER
);

END uninvited_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.uninvited_pkg
IS

PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN

	-- TODO: Is this the appropriate permission level? Would anyone need to search uninvited suppliers
	--       if they weren't then going to invite them?
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for uninvited suppliers');
	END IF;
	
	-- Find all IDs that match the search criteria
	SELECT T_NUMERIC_ROW(uninvited_supplier_id, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT ui.uninvited_supplier_id
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (LOWER(ui.name) LIKE v_search)
		   AND ui.created_as_company_sid IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page in the order specified
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT ui.*, ctry.name as country_name,
				   row_number() OVER (ORDER BY 
						CASE
							WHEN in_sort_by='name' AND in_sort_dir = 'DESC' THEN LOWER(ui.name)
							WHEN in_sort_by='countryName' AND in_sort_dir = 'DESC' THEN LOWER(ctry.name)
						END DESC,
						CASE
							WHEN in_sort_by='name' AND in_sort_dir = 'ASC' THEN LOWER(ui.name)
							WHEN in_sort_by='countryName' AND in_sort_dir = 'ASC' THEN LOWER(ctry.name)
						END ASC 
				   ) rn
			  FROM uninvited_supplier ui
			  JOIN TABLE(v_results) r ON ui.uninvited_supplier_id = r.item
			  JOIN postcode.country ctry on ctry.country = ui.country_code
			 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY rn
		  ) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1;

END;

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_id	IN	NUMBER,
	in_created_as_company_sid	IN	NUMBER
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied applying company_sid to uninvited supplier');
	END IF;
	
	UPDATE uninvited_supplier
	   SET created_as_company_sid = in_created_as_company_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND uninvited_supplier_id = in_uninvited_supplier_id;
	
	--TODO: Should we do some error checking here before attempting to migrate?
	
	--TODO: Actual migration of tasks
END;

END uninvited_pkg;
/

BEGIN
		user_pkg.LogonAdmin;
		
		card_pkg.RegisterCardGroup(18, 'Invite the Uninvited Wizard', 'Used to add a contact and invite a company that exists but hasn''t yet been invited');
		
		card_pkg.RegisterCard(
			'Add user card that allows you to add a new user to a company.', 
			'Credit360.Chain.Cards.CreateUser',
			'/csr/site/chain/cards/createUser.js', 
			'Chain.Cards.CreateUser'
		);
END;
/

grant execute on chain.uninvited_pkg to web_user;

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST04
/********************************************************/

ALTER TABLE chain.COMPONENT_BIND MODIFY COMPANY_SID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
ALTER TABLE chain.COMPONENT_RELATIONSHIP MODIFY COMPANY_SID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
ALTER TABLE chain.PRODUCT_CODE_TYPE MODIFY COMPANY_SID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
ALTER TABLE chain.UNINVITED_SUPPLIER MODIFY COMPANY_SID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST05
/********************************************************/

-- Just in case anyone missed this from latest03 when I acceidentally left it commented out.
DECLARE
	v_col_count	INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO v_col_count
	  FROM user_tab_cols
	 WHERE column_name='CREATED_AS_COMPANY_SID'
	   AND table_name='UNINVITED_SUPPLIER';
	
	IF v_col_count = 0 THEN
		EXECUTE IMMEDIATE('ALTER TABLE chain.UNINVITED_SUPPLIER ADD(CREATED_AS_COMPANY_SID NUMBER(10, 0))');
	END IF;
END;
/

DELETE FROM chain.UNINVITED_SUPPLIER;

ALTER TABLE chain.UNINVITED_SUPPLIER RENAME COLUMN UNINVITED_SUPPLIER_ID TO UNINVITED_SUPPLIER_SID;
ALTER TABLE chain.PURCHASED_COMPONENT RENAME COLUMN UNINVITED_SUPPLIER_ID TO UNINVITED_SUPPLIER_SID;

PROMPT >> Creating v$purchased_component
CREATE OR REPLACE VIEW chain.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, pc.purchaser_company_sid, 
			pc.uninvited_supplier_sid, pc.supplier_product_id
	  FROM purchased_component pc, component cmp
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
;

PROMPT >> Creating v$purchased_component_supplier
CREATE OR REPLACE VIEW chain.v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_sid, 
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
			pc.supplier_company_sid, NULL uninvited_supplier_sid, 
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
			pc.purchaser_company_sid supplier_company_sid, NULL uninvited_supplier_sid, 
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
			NULL supplier_company_sid, us.uninvited_supplier_sid, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
	   AND us.country_code = coun.country_code
;

grant execute on chain.uninvited_pkg to security;
	
BEGIN	
	user_pkg.LogonAdmin();
	
	chain.card_pkg.RegisterCard(
		'Chain.Cards.AddComponentSupplier extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/addSupplier.js', 
		'Chain.Cards.ComponentBuilder.AddSupplier',
		chain.T_STRING_LIST('default', 'createnew')
	);	
	
	chain.card_pkg.RegisterCard(
		'Chain.Cards.CreateCompany extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.CreateCompany',
		'/csr/site/chain/cards/componentBuilder/createSupplier.js', 
		'Chain.Cards.ComponentBuilder.CreateSupplier'
	);	
END;
/

DECLARE
	v_class_id				security_pkg.T_CLASS_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_chain_users_sid		security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
	
	-- it needs to be applied to all companies in the application - as a rule of thumb, anything SO related is "global"
	FOR c IN (
		SELECT app_sid, company_sid, rownum as rn
		  FROM chain.company 
		 ORDER BY app_sid
		
		
	) LOOP

		-- if the app_sid is changing or if first row just to be sure...
		IF c.app_sid <> NVL(SYS_CONTEXT('SECURITY', 'APP'), 0) OR c.rn=1 THEN
			-- log us on (here's yet another method to log someone on - have a look at cvs\security\db\oracle\user_pkg.sql for even more!)
			user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 86400, c.app_sid, v_act_id);
			
			BEGIN
				v_class_id := class_pkg.GetClassID('Chain Uninvited Supplier');
			EXCEPTION 
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					class_pkg.CreateClass(security_pkg.getACT, null, 'Chain Uninvited Supplier', 'chain.uninvited_pkg', null, v_class_id);
			END;	
			
			v_chain_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, c.app_sid, 'Groups/'||chain.chain_pkg.CHAIN_USER_GROUP);
		END IF;
		
		BEGIN
			v_uninvited_sups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.company_sid, chain.chain_pkg.UNINVITED_SUPPLIERS);
		EXCEPTION 
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				securableobject_pkg.CreateSO(v_act_id, c.company_sid, security_pkg.SO_CONTAINER, chain.chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);

		END;	
		
		acl_pkg.AddACE(
			v_act_id, 
			acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
			security_pkg.ACL_INDEX_LAST, 
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_chain_users_sid, 
			security_pkg.PERMISSION_STANDARD_ALL
		);

	END LOOP;
END;
/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST06
/********************************************************/

-- drop all temp helper columns named "isnew"
BEGIN
	FOR r IN (
		SELECT ut.table_name
		  FROM user_tab_columns utc, user_tables ut 
		 WHERE utc.table_name = ut.table_name
		   AND NVL(ut.dropped, 'NO') = 'NO'
		   AND utc.column_name = 'ISNEW' 
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.'||r.table_name||' drop column ISNEW';
	END LOOP;
END;
/


-- drop all component table constraints
BEGIN
	FOR r IN (
	  SELECT * 
	    FROM all_constraints 
	   WHERE constraint_type = 'R' 
	     AND owner='CHAIN' and table_name IN (
			'ALL_COMPONENT_TYPE',
			'COMPONENT',
			'COMPONENT_BIND',
			'COMPONENT_RELATIONSHIP',
			'COMPONENT_SOURCE',
			'COMPONENT_TYPE',
			'COMPONENT_TYPE_CONTAINMENT',
			'PRODUCT',
			'PRODUCT_CODE_TYPE',
			'PRODUCT_METRIC',
			'PRODUCT_METRIC_TYPE',
			'PURCHASED_COMPONENT',
			'UNINVITED_SUPPLIER'
		  )
	) LOOP
	  EXECUTE IMMEDIATE 'ALTER TABLE chain.'||r.table_name||' drop constraint '||r.constraint_name;
	END LOOP;
END;
/

-- now recreate them

-- 
-- TABLE: ALL_COMPONENT_TYPE 
--

ALTER TABLE chain.ALL_COMPONENT_TYPE ADD CONSTRAINT FK_ALL_COMP_TYPE_CARDG 
    FOREIGN KEY (EDITOR_CARD_GROUP_ID)
    REFERENCES chain.CARD_GROUP(CARD_GROUP_ID)
;

-- 
-- TABLE: COMPONENT 
--

ALTER TABLE chain.COMPONENT ADD CONSTRAINT FK_COMPONENT_CHAIN_USER 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE chain.COMPONENT ADD CONSTRAINT FK_COMPONENT_COPT 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

-- 
-- TABLE: COMPONENT_BIND 
--

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT_TYPE578 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT RefCOMPONENT580 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.COMPONENT_BIND ADD CONSTRAINT FK_COMPONENT_BIND_COMPANY 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;


-- 
-- TABLE: COMPONENT_RELATIONSHIP 
--

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND581 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_ID, CONTAINER_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_BIND582 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_ID, CHILD_COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefCOMPONENT_TYPE_CONTAINME583 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE_CONTAINMENT(APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID)  DEFERRABLE INITIALLY DEFERRED
;


-- 
-- TABLE: COMPONENT_SOURCE 
--
ALTER TABLE chain.COMPONENT_SOURCE ADD CONSTRAINT RefCOMPONENT_TYPE528 
    FOREIGN KEY (APP_SID, COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_SOURCE ADD CONSTRAINT FK_COMPONENT_SOUCE_CARDG 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES chain.CARD_GROUP(CARD_GROUP_ID)
;


-- 
-- TABLE: COMPONENT_TYPE 
--

ALTER TABLE chain.COMPONENT_TYPE ADD CONSTRAINT RefALL_COMPONENT_TYPE584 
    FOREIGN KEY (COMPONENT_TYPE_ID)
    REFERENCES chain.ALL_COMPONENT_TYPE(COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_TYPE ADD CONSTRAINT FK_COMPONENT_TYPE_COPT 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;


-- 
-- TABLE: COMPONENT_TYPE_CONTAINMENT 
--

ALTER TABLE chain.COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE532 
    FOREIGN KEY (APP_SID, CONTAINER_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

ALTER TABLE chain.COMPONENT_TYPE_CONTAINMENT ADD CONSTRAINT RefCOMPONENT_TYPE533 
    FOREIGN KEY (APP_SID, CHILD_COMPONENT_TYPE_ID)
    REFERENCES chain.COMPONENT_TYPE(APP_SID, COMPONENT_TYPE_ID)
;

-- 
-- TABLE: PRODUCT 
--

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT_BIND585 
    FOREIGN KEY (APP_SID, PRODUCT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT515 
    FOREIGN KEY (APP_SID, PSEUDO_ROOT_COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.PRODUCT ADD CONSTRAINT RefCOMPONENT539 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;


-- 
-- TABLE: PRODUCT_CODE_TYPE 
--

ALTER TABLE chain.PRODUCT_CODE_TYPE ADD CONSTRAINT FK_PRODUCT_CODE_TYPE_COMPANY 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;


-- 
-- TABLE: PRODUCT_METRIC 
--

ALTER TABLE chain.PRODUCT_METRIC ADD CONSTRAINT RefPRODUCT_METRIC_TYPE436 
    FOREIGN KEY (APP_SID, PRODUCT_METRIC_TYPE_ID)
    REFERENCES chain.PRODUCT_METRIC_TYPE(APP_SID, PRODUCT_METRIC_TYPE_ID)
;

ALTER TABLE chain.PRODUCT_METRIC ADD CONSTRAINT RefPRODUCT516 
    FOREIGN KEY (APP_SID, PRODUCT_ID)
    REFERENCES chain.PRODUCT(APP_SID, PRODUCT_ID)
;


-- 
-- TABLE: PRODUCT_METRIC_TYPE 
--

ALTER TABLE chain.PRODUCT_METRIC_TYPE ADD CONSTRAINT RefCUSTOMER_OPTIONS438 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;


-- 
-- TABLE: PURCHASED_COMPONENT 
--

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_BIND586 
    FOREIGN KEY (APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES chain.COMPONENT_BIND(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_SUPPLIER_TYPE587 
    FOREIGN KEY (COMPONENT_SUPPLIER_TYPE_ID)
    REFERENCES chain.COMPONENT_SUPPLIER_TYPE(COMPONENT_SUPPLIER_TYPE_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefACCEPTANCE_STATUS588 
    FOREIGN KEY (ACCEPTANCE_STATUS_ID)
    REFERENCES chain.ACCEPTANCE_STATUS(ACCEPTANCE_STATUS_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefUNINVITED_SUPPLIER589 
    FOREIGN KEY (APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_SID)
    REFERENCES chain.UNINVITED_SUPPLIER(APP_SID, COMPANY_SID, UNINVITED_SUPPLIER_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefPRODUCT590 
    FOREIGN KEY (APP_SID, SUPPLIER_PRODUCT_ID)
    REFERENCES chain.PRODUCT(APP_SID, PRODUCT_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT593 
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT FK_PURCH_COMP_SUPP_REL_1 
    FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

ALTER TABLE chain.PURCHASED_COMPONENT ADD CONSTRAINT FK_PURCH_COMP_SUPP_REL_2 
    FOREIGN KEY (APP_SID, COMPANY_SID, SUPPLIER_COMPANY_SID)
    REFERENCES chain.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
;

-- 
-- TABLE: UNINVITED_SUPPLIER 
--

ALTER TABLE chain.UNINVITED_SUPPLIER ADD CONSTRAINT RefCOMPANY616 
    FOREIGN KEY (APP_SID, CREATED_AS_COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE chain.UNINVITED_SUPPLIER ADD CONSTRAINT FK_UNINVITED_SUPPLIER_COMPANY 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE chain.UNINVITED_SUPPLIER ADD CONSTRAINT FK_UNINVITED_SUPPLIER_COUNTRY 
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES postcode.COUNTRY(COUNTRY)
;

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST07
/********************************************************/


/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST08
/********************************************************/

BEGIN
	FOR r IN (
		SELECT host 
		  FROM v$chain_host 
	) LOOP
		user_pkg.LogonAdmin(r.host);
		
		DECLARE
			v_class_id		security_pkg.T_CLASS_ID;
		BEGIN
			class_pkg.CreateClass(security_pkg.getACT, null, 'ChainFileUpload', 'chain.upload_pkg', null, v_class_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END LOOP;
END;
/

connect aspen2/aspen2@&_CONNECT_IDENTIFIER

grant select, REFERENCES on aspen2.filecache to chain;

connect chain/chain@&_CONNECT_IDENTIFIER

CREATE TABLE chain.FILE_UPLOAD(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILE_UPLOAD_SID      NUMBER(10, 0)    NOT NULL,
    COMPANY_SID          NUMBER(10, 0)    NOT NULL,
    FILENAME             VARCHAR2(255)    NOT NULL,
    MIME_TYPE            VARCHAR2(255)    NOT NULL,
    DATA                 BLOB             NOT NULL,
    SHA1                 RAW(20)          NOT NULL,
    LAST_MODIFIED_DTM    TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_FILE_UPLOAD PRIMARY KEY (APP_SID, FILE_UPLOAD_SID)
)
;

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST09
/********************************************************/

BEGIN
	user_pkg.LogonAdmin;
		
	chain.card_pkg.RegisterCard(
		'Generic summary page', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/wizardSummary.js', 
		'Chain.Cards.WizardSummary'
	);
	
	chain.card_pkg.RegisterCard(
		'Chain.Cards.SearchCompany extension for picking component suppliers', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/searchComponentSupplier.js', 
		'Chain.Cards.SearchComponentSupplier',
		chain.T_STRING_LIST('default', 'createnew')
	);
END;
/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST10
/********************************************************/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST11
/********************************************************/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST12
/********************************************************/

begin
	FOR r IN (
		SELECT app_sid, site_name
		  FROM chain.customer_options
		 WHERE chain_implementation IN ('deutschebank', 'eicc.credit360.com')
	) 
	LOOP
		user_pkg.LogonAdmin;
		security_pkg.SetACT(security_pkg.GetACT, r.app_sid);

		chain.card_pkg.RegisterCard(
			'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
			'Credit360.Chain.Cards.QuestionnaireInvitationConfirmation',
			'/csr/site/chain/cards/QuestionnaireInvitationConfirmation.js', 
			'Chain.Cards.QuestionnaireInvitationConfirmation',
			chain.T_STRING_LIST('login', 'register', 'reject')
		);
		chain.card_pkg.SetGroupCards(
				'Questionnaire Invitation Landing', 
				chain.T_STRING_LIST(
					'Chain.Cards.QuestionnaireInvitationConfirmation',
					'Chain.Cards.Login',
					'Chain.Cards.RejectInvitation',
					'Chain.Cards.SelfRegistration'
				)
		);
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.QuestionnaireInvitationConfirmation', chain.T_CARD_ACTION_LIST(
			chain.T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
			chain.T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
			chain.T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
		));
		
		-- From /csr/db/util/EnableChain
		chain.card_pkg.SetGroupCards('Questionnaire Invitation Wizard', chain.T_STRING_LIST('Chain.Cards.AddCompany', 'Chain.Cards.CreateCompany', 'Chain.Cards.AddUser', 'Chain.Cards.CreateUser', 'Chain.Cards.InvitationSummary'));	
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', chain.T_CARD_ACTION_LIST(chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'), chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')));	
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', chain.T_CARD_ACTION_LIST(chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'), chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')));

		chain.card_pkg.SetGroupCards('My Company', chain.T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SETUP_STUB_REGISTRATION);
		chain.card_pkg.SetGroupCards('Supplier Details', chain.T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.TaskBrowser'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
	
	END LOOP;
end;
/

begin
	FOR r IN (
		SELECT app_sid, site_name
		  FROM chain.customer_options
		 WHERE chain_implementation IN ('CSR.HAMMERSON', 'CSR.WHISTLER')
	) 
	LOOP
		user_pkg.LogonAdmin;
		security_pkg.SetACT(security_pkg.GetACT, r.app_sid);

		chain.card_pkg.RegisterCard(
			'Confirms questionnaire intvitation details with a potential new user - flavoured for csr', 
			'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation',
			'/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js', 
			'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
			chain.T_STRING_LIST('login', 'register', 'reject')
		);
		chain.card_pkg.SetGroupCards(
				'Questionnaire Invitation Landing', 
				chain.T_STRING_LIST(
					'Chain.Cards.CSRQuestionnaireInvitationConfirmation',
					'Chain.Cards.Login',
					'Chain.Cards.RejectInvitation',
					'Chain.Cards.SelfRegistration'
				)
		);
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.CSRQuestionnaireInvitationConfirmation', chain.T_CARD_ACTION_LIST(
			chain.T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
			chain.T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
			chain.T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
		));
		
		-- From /csr/db/util/EnableChain
		chain.card_pkg.SetGroupCards('Questionnaire Invitation Wizard', chain.T_STRING_LIST('Chain.Cards.AddCompany', 'Chain.Cards.CreateCompany', 'Chain.Cards.AddUser', 'Chain.Cards.CreateUser', 'Chain.Cards.InvitationSummary'));	
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddCompany', chain.T_CARD_ACTION_LIST(chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.AddUser'), chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateCompany')));	
		chain.card_pkg.RegisterProgression('Questionnaire Invitation Wizard', 'Chain.Cards.AddUser', chain.T_CARD_ACTION_LIST(chain.T_CARD_ACTION_ROW('default', 'Chain.Cards.InvitationSummary'), chain.T_CARD_ACTION_ROW('createnew', 'Chain.Cards.CreateUser')));

		chain.card_pkg.SetGroupCards('My Company', chain.T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'My Company', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.SETUP_STUB_REGISTRATION);
		chain.card_pkg.SetGroupCards('Supplier Details', chain.T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.ActivityBrowser', 'Chain.Cards.QuestionnaireList', 'Chain.Cards.CompanyUsers', 'Chain.Cards.TaskBrowser'));
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.ViewCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => TRUE);
		chain.card_pkg.MakeCardConditional(in_group_name => 'Supplier Details', in_js_class => 'Chain.Cards.EditCompany', in_capability => chain.chain_pkg.COMPANY, in_permission_set => security_pkg.PERMISSION_WRITE, in_invert_check => FALSE);
	
	END LOOP;
end;
/

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST13
/********************************************************/
	
BEGIN
	user_pkg.logonadmin;
	
	-- UPLOADED FILE
	chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ);
	chain.capability_pkg.GrantCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.UPLOADED_FILE, chain.chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);

	FOR r IN (
		SELECT * FROM chain.v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		FOR c IN (
			SELECT * FROM chain.company WHERE app_sid = security_pkg.GetApp
		) LOOP
			chain.capability_pkg.RefreshCompanyCapabilities(c.company_sid);
		END LOOP;
		
	END LOOP;
	
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE chain.file_upload DROP COLUMN parent_sid';
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

ALTER TABLE chain.file_upload MODIFY company_sid DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

/********************************************************/
exec user_pkg.logonadmin;
COMMIT;
PROMPT >> RAP5-LATEST14
/********************************************************/

DECLARE
	v_cg_id  		card_group.card_group_id%TYPE;
BEGIN

	user_pkg.logonadmin;
	
	v_cg_id := chain.card_pkg.GetCardGroupId('Temporary Invitation Wizard');
	DELETE FROM chain.card_group_progression WHERE card_group_id = v_cg_id;
	DELETE FROM chain.card_group_card WHERE card_group_id = v_cg_id;
	DELETE FROM chain.card_group WHERE card_group_id = v_cg_id;
	
	v_cg_id := chain.card_pkg.GetCardGroupId('Simple Questionnaire Invitation');
	DELETE FROM chain.card_group_progression WHERE card_group_id = v_cg_id;
	DELETE FROM chain.card_group_card WHERE card_group_id = v_cg_id;
	DELETE FROM chain.card_group WHERE card_group_id = v_cg_id;
END;
/

whenever oserror continue
@..\action_pkg
@..\chain_pkg
@..\company_pkg
@..\component_pkg
@..\purchased_component_pkg
@..\product_pkg
@..\uninvited_pkg;
@..\upload_pkg

@..\action_body
@..\component_body
@..\product_body
@..\purchased_component_body
@..\company_body
@..\chain_link_body
@..\uninvited_body;
@..\upload_body

@update_tail
