-- Please update version.sql too -- this keeps clean builds in sync
define version=1167
@update_header

CREATE SEQUENCE CT.PS_ITEM_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE TABLE CT.PS_ITEM (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    SUPPLIER_COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    ITEM_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    SPEND NUMBER(20,10) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PURCHASE_DATE DATE NOT NULL,
    WORKSHEET_ID NUMBER(10),
    CREATED_BY_SID NUMBER(10) NOT NULL,
    CREATED_DTM DATE NOT NULL,
    MODIFIED_BY_SID NUMBER(10),
    LAST_MODIFIED_DTM DATE,
    CONSTRAINT PK_PS_ITEM PRIMARY KEY (APP_SID, COMPANY_SID, SUPPLIER_COMPANY_SID, ITEM_ID),
    CONSTRAINT TUC_PS_ITEM_ID UNIQUE (ITEM_ID),
    CONSTRAINT TCC_PS_ITEM_SPEND CHECK (SPEND > 0),
    CONSTRAINT TCC_PS_ITEM_NOSUPPLYSELF CHECK (COMPANY_SID <> SUPPLIER_COMPANY_SID),
    CONSTRAINT TCC_PS_ITEM_MODIFIED_VALID CHECK ((MODIFIED_BY_SID IS NULL AND LAST_MODIFIED_DTM IS NULL) OR (MODIFIED_BY_SID IS NOT NULL AND LAST_MODIFIED_DTM IS NOT NULL))
);

COMMENT ON TABLE CT.PS_ITEM IS 'Purchased products and services';

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT COMPANY_PS_ITEM 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT COMPANY_PS_ITEM_SUPP 
    FOREIGN KEY (APP_SID, SUPPLIER_COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CURRENCY_PS_ITEM 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT WORKSHEET_PS_ITEM 
    FOREIGN KEY (APP_SID, WORKSHEET_ID) REFERENCES CT.WORKSHEET (APP_SID,WORKSHEET_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CSR_USR_PS_ITEM 
    FOREIGN KEY (APP_SID, CREATED_BY_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CSR_USR_PS_ITEM_MOD 
    FOREIGN KEY (APP_SID, MODIFIED_BY_SID) REFERENCES CSR.CSR_USER (APP_SID,CSR_USER_SID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT B_R_PS_ITEM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

@../ct/products_services_pkg;
@../ct/products_services_body;
	
@update_tail

