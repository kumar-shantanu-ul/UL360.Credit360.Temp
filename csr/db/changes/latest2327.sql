-- Please update version.sql too -- this keeps clean builds in sync
define version=2327
@update_header

ALTER TABLE CSR.METER_SOURCE_TYPE ADD (SHOW_INVOICE_REMINDER NUMBER(1,0) DEFAULT 0 NOT NULL, INVOICE_REMINDER VARCHAR2(1024));

@../meter_body

@update_tail