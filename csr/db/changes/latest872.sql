-- Please update version.sql too -- this keeps clean builds in sync
define version=872
@update_header

ALTER TABLE donations.CUSTOMER_OPTIONS ADD (IS_RECIPIENT_TAX_ID_MANDATORY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE donations.CUSTOMER_OPTIONS ADD (IS_RECIPIENT_ADDRESS_MANDATORY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE donations.RECIPIENT ADD (TAX_ID VARCHAR2(128));

@../donations/options_body
@../donations/recipient_pkg
@../donations/recipient_body

@update_tail
