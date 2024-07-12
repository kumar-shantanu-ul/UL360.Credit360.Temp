-- Please update version.sql too -- this keeps clean builds in sync
define version=1022
@update_header

CREATE TABLE CHAIN.BUSINESS_UNIT(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BUSINESS_UNIT_ID           NUMBER(10, 0)    NOT NULL,
    PARENT_BUSINESS_UNIT_ID    NUMBER(10, 0),
    DESCRIPTION                VARCHAR2(255)    NOT NULL,
    ACTIVE                     NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_BU_ACTIVE_0_OR_1 CHECK (ACTIVE IN (0,1)),
    CONSTRAINT PK_BUSINESS_UNIT PRIMARY KEY (APP_SID, BUSINESS_UNIT_ID)
)
;


CREATE TABLE CHAIN.BUSINESS_UNIT_MEMBER(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BUSINESS_UNIT_ID    NUMBER(10, 0)    NOT NULL,
    USER_SID            NUMBER(10, 0)    NOT NULL,
    IS_PRIMARY_BU       NUMBER(1, 0),
    CONSTRAINT CHK_BU_MEM_IS_PRIM_NULL_OR_1 CHECK (IS_PRIMARY_BU IS NULL OR IS_PRIMARY_BU =1),
    CONSTRAINT PK_BUSINESS_UNIT_MEMBER PRIMARY KEY (APP_SID, BUSINESS_UNIT_ID, USER_SID)
)
;

CREATE TABLE CHAIN.BUSINESS_UNIT_SUPPLIER(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BUSINESS_UNIT_ID        NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    IS_PRIMARY_BU           NUMBER(1, 0),
    CONSTRAINT CHK_BU_SUP_IS_PRIM_NULL_OR_1 CHECK (IS_PRIMARY_BU IS NULL OR IS_PRIMARY_BU = 1),
    CONSTRAINT PK_BUSINESS_UNIT_SUPPLIER PRIMARY KEY (APP_SID, BUSINESS_UNIT_ID, SUPPLIER_COMPANY_SID)
)
;

ALTER TABLE CHAIN.COMPANY ADD (
    REFERENCE_ID_1               VARCHAR2(50),
    REFERENCE_ID_2               VARCHAR2(50),
    REFERENCE_ID_3               VARCHAR2(50)
)
;

CREATE TABLE CHAIN.REFERENCE_ID_LABEL(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    REFERENCE_NUMBER     NUMBER(10, 0)    NOT NULL,
    LABEL                VARCHAR2(255),
    MANDATORY            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    PURCHASER_ACC_LVL    CHAR(1)          DEFAULT 'H' NOT NULL,
    SUPPLIER_ACC_LVL     CHAR(1)          DEFAULT 'H' NOT NULL,
    UNIQUENESS           CHAR(1)          DEFAULT 'N' NOT NULL,
    CONSTRAINT CHK_REFERENCE_NUM_1_TO_3 CHECK (REFERENCE_NUMBER IN (1,2,3)),
    CONSTRAINT CHK_REF_LAB_MAND_0_OR_1 CHECK (MANDATORY IN (0,1)),
    CONSTRAINT CHK_REF_LAB_PURCH_ACC_LVL CHECK (PURCHASER_ACC_LVL IN ('H', 'R', 'W')),
    CONSTRAINT CHK_REF_LAB_SUP_ACC_LVL CHECK (SUPPLIER_ACC_LVL IN ('H', 'R', 'W')),
    CONSTRAINT CHK_REF_LAB_UNIQUENESS CHECK (UNIQUENESS IN ('N','C','G')),
    CONSTRAINT PK_REFERENCE_ID_LABEL PRIMARY KEY (APP_SID, REFERENCE_NUMBER)
)
;

ALTER  TABLE CHAIN.SECTOR ADD (
    PARENT_SECTOR_ID    NUMBER(10, 0)
)
;

CREATE UNIQUE INDEX CHAIN.UK_BU_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_MEMBER(APP_SID, USER_SID, IS_PRIMARY_BU)
;

CREATE UNIQUE INDEX CHAIN.UK_BU_SUP_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_SUPPLIER(APP_SID, SUPPLIER_COMPANY_SID, IS_PRIMARY_BU)
;

ALTER TABLE CHAIN.BUSINESS_UNIT ADD CONSTRAINT FK_BU_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.BUSINESS_UNIT ADD CONSTRAINT FK_BUSNESS_UNIT_PARENT 
    FOREIGN KEY (APP_SID, PARENT_BUSINESS_UNIT_ID)
    REFERENCES CHAIN.BUSINESS_UNIT(APP_SID, BUSINESS_UNIT_ID)
;


ALTER TABLE CHAIN.BUSINESS_UNIT_MEMBER ADD CONSTRAINT FK_BU_MEMBER_BU 
    FOREIGN KEY (APP_SID, BUSINESS_UNIT_ID)
    REFERENCES CHAIN.BUSINESS_UNIT(APP_SID, BUSINESS_UNIT_ID)
;

ALTER TABLE CHAIN.BUSINESS_UNIT_MEMBER ADD CONSTRAINT FK_BU_MEMBER_USER 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;


ALTER TABLE CHAIN.BUSINESS_UNIT_SUPPLIER ADD CONSTRAINT FK_BU_SUP_BU 
    FOREIGN KEY (APP_SID, BUSINESS_UNIT_ID)
    REFERENCES CHAIN.BUSINESS_UNIT(APP_SID, BUSINESS_UNIT_ID)
;

ALTER TABLE CHAIN.BUSINESS_UNIT_SUPPLIER ADD CONSTRAINT FK_BU_SUP_SUP 
    FOREIGN KEY (APP_SID, SUPPLIER_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.REFERENCE_ID_LABEL ADD CONSTRAINT FK_REF_ID_LABEL_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.SECTOR ADD CONSTRAINT FK_SECTOR_PARENT_ID 
    FOREIGN KEY (APP_SID, PARENT_SECTOR_ID)
    REFERENCES CHAIN.SECTOR(APP_SID, SECTOR_ID)
;

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id, c.reference_id_1, c.reference_id_2, c.reference_id_3,
		   cou.name country_name, s.description sector_description
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

declare
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'BUSINESS_UNIT',
		'BUSINESS_UNIT_MEMBER',
		'BUSINESS_UNIT_SUPPLIER',
		'REFERENCE_ID_LABEL'
	);
	for i in 1 .. v_list.count loop
		dbms_output.put_line('Doing '||v_list(i));
		dbms_rls.add_policy(
			object_schema   => 'CHAIN',
			object_name     => v_list(i),
			policy_name     => (SUBSTR(v_list(i), 1, 26) || '_POL'), 
			function_schema => 'CHAIN',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	end loop;
end;
/

@..\chain\helper_pkg
@..\chain\setup_pkg
@..\chain\company_pkg

@..\chain\helper_body
@..\chain\setup_body
@..\chain\company_body
@..\chain\chain_body

@..\quick_survey_body



@update_tail
