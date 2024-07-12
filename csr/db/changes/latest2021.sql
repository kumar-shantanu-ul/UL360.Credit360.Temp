-- Please update version.sql too -- this keeps clean builds in sync
define version=2021
@update_header

--todo: add to manual schema changes
/*1: Add contacts, 2: Add Existing contacts*/
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD DEFAULT_QNR_INVITATION_WIZ NUMBER(1, 0) NULL;

UPDATE CHAIN.CUSTOMER_OPTIONS SET DEFAULT_QNR_INVITATION_WIZ = 1;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS MODIFY DEFAULT_QNR_INVITATION_WIZ NUMBER(1, 0) DEFAULT 1 NOT NULL;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD CHECK (DEFAULT_QNR_INVITATION_WIZ IN (1, 2));

@../chain/helper_body

@update_tail