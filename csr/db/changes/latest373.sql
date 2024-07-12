-- Please update version.sql too -- this keeps clean builds in sync
define version=373
@update_header

ALTER TABLE METER_READING ADD (
	CREATED_INVOICE_ID     NUMBER(10, 0)
);

ALTER TABLE METER_READING ADD CONSTRAINT RefUTILITY_INVOICE1367 
    FOREIGN KEY (APP_SID, CREATED_INVOICE_ID)
    REFERENCES UTILITY_INVOICE(APP_SID, UTILITY_INVOICE_ID)
;

@../create_triggers

@update_tail
