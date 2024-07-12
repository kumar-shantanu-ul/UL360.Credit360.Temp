-- Please update version.sql too -- this keeps clean builds in sync
define version=1254
@update_header

ALTER TABLE DONATIONS.CUSTOMER_OPTIONS ADD FC_PAID_TAG_ID NUMBER(10, 0);

ALTER TABLE DONATIONS.CUSTOMER_OPTIONS ADD CONSTRAINT FK_FC_PAID_TAG_ID 
    FOREIGN KEY (APP_SID, FC_PAID_TAG_ID)
    REFERENCES DONATIONS.TAG(APP_SID, TAG_ID)
;

@..\donations\options_body
@..\donations\region_group_body
@..\donations\funding_commitment_body

@update_tail
