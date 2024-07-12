define version=116
@update_header

CREATE SEQUENCE CHAIN.PURCHASE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER
;

CREATE TABLE CHAIN.PURCHASE_CHANNEL
(
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COMPANY_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CHAIN_COMPANY') NOT NULL,
	PURCHASE_CHANNEL_ID		NUMBER(10) NOT NULL,
	DESCRIPTION				VARCHAR2(255) NOT NULL,
	REGION_SID				NUMBER(10),
	CONSTRAINT PK_PURCHASE_CHANNEL PRIMARY KEY (APP_SID, COMPANY_SID, PURCHASE_CHANNEL_ID),
	CONSTRAINT FK_PURCHASE_CNL_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
);

CREATE TABLE CHAIN.PURCHASE
(
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PRODUCT_ID				NUMBER(10) NOT NULL,
	PURCHASER_COMPANY_SID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CHAIN_COMPANY') NOT NULL,
	PURCHASE_ID				NUMBER(10) NOT NULL,
	START_DATE				DATE NOT NULL,
	END_DATE				DATE,
	INVOICE_NUMBER			VARCHAR2(50),
	PURCHASE_ORDER			VARCHAR2(50),
	NOTE					VARCHAR2(255),
	AMOUNT					NUMBER(10, 3) NOT NULL,
	AMOUNT_UNIT_ID			NUMBER(10) NOT NULL,
	PURCHASE_CHANNEL_ID		NUMBER(10),
	CONSTRAINT PK_PURCHASE PRIMARY KEY (APP_SID, PURCHASE_ID),
	CONSTRAINT FK_PURCHASE_PRODUCT FOREIGN KEY (APP_SID, PRODUCT_ID) REFERENCES CHAIN.PURCHASED_COMPONENT (APP_SID, COMPONENT_ID),
	CONSTRAINT FK_PURCHASE_CHANNEL FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, PURCHASE_CHANNEL_ID) REFERENCES CHAIN.PURCHASE_CHANNEL(APP_SID, COMPANY_SID, PURCHASE_CHANNEL_ID),
	CONSTRAINT FK_PURCHASE_COMPANY FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID),
	CONSTRAINT FK_PURCHASE_UNIT FOREIGN KEY (APP_SID, AMOUNT_UNIT_ID) REFERENCES CHAIN.AMOUNT_UNIT(APP_SID, AMOUNT_UNIT_ID)
);

ALTER TABLE CHAIN.AMOUNT_UNIT ADD UNIT_TYPE VARCHAR2(32) NULL;

UPDATE chain.amount_unit
   SET unit_type = 'fraction'
 WHERE description = '%';

ALTER TABLE CHAIN.AMOUNT_UNIT MODIFY UNIT_TYPE VARCHAR2(32) NOT NULL;

@..\chain_pkg
@..\purchased_component_pkg
@..\purchased_component_body
@..\company_body
@..\rls

@update_tail
