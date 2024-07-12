-- Please update version.sql too -- this keeps clean builds in sync
define version=1662
@update_header


ALTER TABLE DONATIONS.CUSTOMER_OPTIONS ADD FC_RECONCILED_TAG_ID NUMBER(10, 0);
;

ALTER TABLE DONATIONS.CUSTOMER_OPTIONS ADD CONSTRAINT FK_FC_RECONCILED_TAG_ID 
    FOREIGN KEY (APP_SID, FC_RECONCILED_TAG_ID)
    REFERENCES DONATIONS.TAG(APP_SID, TAG_ID)
;

@../donations/options_body

@update_tail
