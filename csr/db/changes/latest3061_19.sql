-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.PRODUCT_COMPANY_ALERT_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.PRODUCT_COMPANY_ALERT(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ALERT_ID				NUMBER(10, 0)	NOT NULL,
	COMPANY_PRODUCT_ID		NUMBER(10, 0)	NOT NULL,
	PURCHASER_COMPANY_SID	NUMBER(10, 0)	NOT NULL,
	SUPPLIER_COMPANY_SID	NUMBER(10, 0)	NOT NULL,
	USER_SID				NUMBER(10, 0)	NOT NULL,
	SENT_DTM				TIMESTAMP(6),
	CONSTRAINT PK_PRODUCT_COMPANY_ALERT PRIMARY KEY (APP_SID, ALERT_ID)
);


CREATE TABLE CSRIMP.CHAIN_PRODUCT_COMPANY_ALERT (
	CSRIMP_SESSION_ID 		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALERT_ID 				NUMBER(10,0)	NOT NULL,
	COMPANY_PRODUCT_ID 		NUMBER(10,0)	NOT NULL,
	PURCHASER_COMPANY_SID 	NUMBER(10,0)	NOT NULL,
	SUPPLIER_COMPANY_SID 	NUMBER(10,0)	NOT NULL,
	USER_SID 				NUMBER(10,0)	NOT NULL,
	SENT_DTM 				TIMESTAMP(6),
	CONSTRAINT PK_CHAIN_PRODUCT_COMPANY_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, ALERT_ID),
	CONSTRAINT FK_CHAIN_PRDCT_CMPNY_ALERT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


-- Alter tables
ALTER TABLE CHAIN.PRODUCT_COMPANY_ALERT ADD CONSTRAINT FK_PRODUCT_COMPANY_ALERT_PROD
	FOREIGN KEY (APP_SID, COMPANY_PRODUCT_ID) REFERENCES CHAIN.COMPANY_PRODUCT (APP_SID, PRODUCT_ID);

ALTER TABLE CHAIN.PRODUCT_COMPANY_ALERT ADD CONSTRAINT FK_PRODUCT_COMPANY_ALERT_CPNYP
	FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID);

ALTER TABLE CHAIN.PRODUCT_COMPANY_ALERT ADD CONSTRAINT FK_PRODUCT_COMPANY_ALERT_CPNYS
	FOREIGN KEY (APP_SID, SUPPLIER_COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID);

ALTER TABLE CHAIN.PRODUCT_COMPANY_ALERT ADD CONSTRAINT FK_PRODUCT_COMPANY_ALERT_USER
	FOREIGN KEY (APP_SID, USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID, USER_SID);

CREATE INDEX CHAIN.IX_PRODUCT_COMPANY_ALERT_PROD ON CHAIN.PRODUCT_COMPANY_ALERT (APP_SID, COMPANY_PRODUCT_ID);
CREATE INDEX CHAIN.IX_PRODUCT_COMPANY_ALERT_CPNYP ON CHAIN.PRODUCT_COMPANY_ALERT (APP_SID, PURCHASER_COMPANY_SID);
CREATE INDEX CHAIN.IX_PRODUCT_COMPANY_ALERT_CPNYS ON CHAIN.PRODUCT_COMPANY_ALERT (APP_SID, SUPPLIER_COMPANY_SID);
CREATE INDEX CHAIN.IX_PRODUCT_COMPANY_ALERT_USER ON CHAIN.PRODUCT_COMPANY_ALERT (APP_SID, USER_SID);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON Chain.product_company_alert TO CSR;

GRANT SELECT, INSERT, UPDATE ON chain.product_company_alert TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_product_company_alert TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.app_sid, cp.product_id, tr.description product_name, cp.company_sid, cp.product_type_id,
		   cp.sku, cp.lookup_key, cp.is_active
	  FROM chain.company_product cp
	  JOIN chain.company_product_tr tr ON tr.product_id = cp.product_id AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
-- csr\db\chain\create_views.sql

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_alert_id NUMBER := 5030;
	v_group_id NUMBER := 8;
BEGIN
	-- Supplier Company associated with Product alert
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES (v_alert_id,
		'Supplier Company associated with Product alert',
		'Sent on a scheduled basis for suppliers to review their data.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		v_group_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Supplier Company associated with Product alert',
				send_trigger = 'Sent on a scheduled basis for suppliers to review their data.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = v_alert_id;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PRODUCT_ID', 'Product Id', 'The product id the alert is being sent for', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PRODUCT_NAME', 'Product Name', 'The product the alert is being sent for', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PURCHASER_COMPANY_NAME', 'Purchaser Company', 'The company to which the product is supplied to', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'PURCHASER_COMPANY_SID', 'Purchaser Company Sid', 'The purchasing company sid with which the product has been associated to', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'SUPPLIER_COMPANY_NAME', 'Supplier Company', 'The company from which the product is supplied', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'SUPPLIER_COMPANY_SID', 'Supplier Company Sid', 'The supplier company sid with which the product has been associated to', 9);
	
	-- Run Setup-SuperAdmin-Utility Scripts-"Add missing alert" for id 5030 if you want to use this alert.
END;
/



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../chain/scheduled_alert_pkg

@../schema_body
@../chain/company_product_body
@../chain/scheduled_alert_body

@../csrimp/imp_body

@update_tail
