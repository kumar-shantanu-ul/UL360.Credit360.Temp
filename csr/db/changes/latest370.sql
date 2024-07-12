-- Please update version.sql too -- this keeps clean builds in sync
define version=370
@update_header

DROP TABLE UTILITY_INVOICE_COMMENT CASCADE CONSTRAINTS;

ALTER TABLE METER_SOURCE_TYPE ADD (
	ADD_INVOICE_DATA           NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CHECK (ADD_INVOICE_DATA IN (0,1))
);

ALTER TABLE UTILITY_CONTRACT ADD CONSTRAINT RefCSR_USER1365 
    FOREIGN KEY (APP_SID, CREATED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

-- Default behaviour is to ask for invoice type data 
-- when meter source type is arbitrary period
UPDATE meter_source_type
   SET add_invoice_data = arbitrary_period;

@update_tail
