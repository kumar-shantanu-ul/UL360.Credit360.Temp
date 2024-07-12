-- Please update version.sql too -- this keeps clean builds in sync
define version=1686
@update_header

CREATE TABLE CSR.EST_MISMATCHED_ESP_ID (
	APP_SID					NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	EST_ACCOUNT_SID			NUMBER(10)		NOT NULL,
	PM_CUSTOMER_ID			VARCHAR2(1024)	NOT NULL,
	PM_ID					VARCHAR2(1024)	NOT NULL,
	ES_ESP_ID				NUMBER(10)		NOT NULL,
	CR_ESP_ID				NUMBER(10)		NOT NULL,
	DETECTED_DTM			DATE			NOT NULL,
	PM_TYPE					VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_EST_MISMATCHED_ESP_ID PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_ID)
);

ALTER TABLE CSR.EST_MISMATCHED_ESP_ID ADD CONSTRAINT FK_CUSTOMER_MISMATCHED_ESP_ID
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID)
    REFERENCES CSR.EST_CUSTOMER(APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID)
;

ALTER TABLE CSR.EST_MISMATCHED_ESP_ID ADD CONSTRAINT FK_ACCOUNT_MISMATCHED_ESP_ID 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID)
    REFERENCES CSR.EST_ACCOUNT(APP_SID, EST_ACCOUNT_SID)
;

@../energy_star_pkg
@../energy_star_body

@update_tail


